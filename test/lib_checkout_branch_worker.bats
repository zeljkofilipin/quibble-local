#!/usr/bin/env bats
#
# Tests for lib/checkout_branch_worker — the git logic that lib/checkout_branch runs inside
# the container. It is plain git, so it is exercised here on host fixture repos with no Docker.

# Path to the worker script under test.
WORKER="$BATS_TEST_DIRNAME/../lib/checkout_branch_worker"

setup() {
  TEST_DIR=$(mktemp -d)            # temp project root for fixtures
  HOME="$TEST_DIR/home"            # sandbox HOME so tests never touch the real ~/.gitconfig
  mkdir -p "$HOME"
  export HOME
  git config --global init.defaultBranch master  # deterministic default branch, silences git's hint
  git config --global user.email test@test        # identity for fixture commits
  git config --global user.name test
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

# Create a bare repo at $1 whose default branch is master, plus any extra branches named in
# the remaining args (each on its own commit). Usage: make_bare <bare-path> [extra-branch...]
make_bare() {
  local bare="$1"; shift # bare repo path; remaining args are extra branch names
  local work
  work=$(mktemp -d)                                   # temporary non-bare repo to commit into
  git init --quiet "$work"
  git -C "$work" symbolic-ref HEAD refs/heads/master  # force the first commit onto master
  git -C "$work" commit --quiet --allow-empty -m "master commit"
  local b
  for b in "$@"; do                                   # create each extra branch with its own commit
    git -C "$work" checkout --quiet -b "$b"
    git -C "$work" commit --quiet --allow-empty -m "$b commit"
    git -C "$work" checkout --quiet master            # leave the source on master so the bare's HEAD is master
  done
  mkdir -p "$(dirname "$bare")"
  git clone --quiet --bare "$work" "$bare"
  git -C "$bare" symbolic-ref HEAD refs/heads/master  # ensure clones get origin/HEAD -> master
  rm -rf "$work" # done with the temporary repo
}

# Clone a working copy from bare repo $1 into $2, then detach HEAD (as Quibble's cloner does).
clone_detached() {
  local bare="$1" work="$2"
  git clone --quiet "$bare" "$work"
  git -C "$work" checkout --quiet --detach HEAD # leave it in detached HEAD
}

# Print the current branch of repo $1, or literally "HEAD" when detached.
current_branch() {
  git -C "$1" rev-parse --abbrev-ref HEAD
}

@test "checkout_branch_worker: re-attaches a detached core repo to the requested branch" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git"
  clone_detached "$TEST_DIR/bare/core.git" "$src"
  [ "$(current_branch "$src")" = HEAD ] # precondition: detached
  run bash "$WORKER" "$src" master
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = master ]
}

@test "checkout_branch_worker: re-attaches every repo in a full src tree" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git"
  make_bare "$TEST_DIR/bare/vendor.git"
  make_bare "$TEST_DIR/bare/Vector.git"
  make_bare "$TEST_DIR/bare/Echo.git"
  clone_detached "$TEST_DIR/bare/core.git" "$src"
  clone_detached "$TEST_DIR/bare/vendor.git" "$src/vendor"
  clone_detached "$TEST_DIR/bare/Vector.git" "$src/skins/Vector"
  clone_detached "$TEST_DIR/bare/Echo.git" "$src/extensions/Echo"
  run bash "$WORKER" "$src" master
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = master ]
  [ "$(current_branch "$src/vendor")" = master ]
  [ "$(current_branch "$src/skins/Vector")" = master ]
  [ "$(current_branch "$src/extensions/Echo")" = master ]
}

@test "checkout_branch_worker: checks out a requested non-default branch (creating it from origin)" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git" REL1_44 # bare has master + REL1_44
  clone_detached "$TEST_DIR/bare/core.git" "$src"
  run bash "$WORKER" "$src" REL1_44
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = REL1_44 ]
}

@test "checkout_branch_worker: falls back to the default branch when the requested branch is absent" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git" # only master
  clone_detached "$TEST_DIR/bare/core.git" "$src"
  run bash "$WORKER" "$src" REL1_99 # repo has no REL1_99
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = master ] # fell back to the repo's default
}

@test "checkout_branch_worker: leaves an already-attached repo untouched" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git" REL1_44
  git clone --quiet "$TEST_DIR/bare/core.git" "$src" # on master, attached (NOT detached)
  run bash "$WORKER" "$src" REL1_44                  # request REL1_44...
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = master ]            # ...but it is left on master, not switched
}

@test "checkout_branch_worker: skips non-repo subdirectories" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git"
  clone_detached "$TEST_DIR/bare/core.git" "$src"
  mkdir -p "$src/extensions/NotARepo" # a plain directory, not a git repo
  run bash "$WORKER" "$src" master
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = master ]      # core still re-attached
  [ ! -e "$src/extensions/NotARepo/.git" ]     # the plain dir was left alone
}

@test "checkout_branch_worker: falls back to master when origin/HEAD is unset" {
  src="$TEST_DIR/src"
  make_bare "$TEST_DIR/bare/core.git"
  clone_detached "$TEST_DIR/bare/core.git" "$src"
  git -C "$src" remote set-head origin -d # remove refs/remotes/origin/HEAD
  run bash "$WORKER" "$src" REL1_99        # absent branch -> default_branch -> master fallback
  [ "$status" -eq 0 ]
  [ "$(current_branch "$src")" = master ]
}

@test "checkout_branch_worker: succeeds when there are no repos to re-attach" {
  src="$TEST_DIR/src"
  mkdir -p "$src" # empty src, no repos
  run bash "$WORKER" "$src" master
  [ "$status" -eq 0 ]
}

@test "checkout_branch_worker: exits non-zero when a detached repo cannot be put on any branch" {
  src="$TEST_DIR/src"
  # A bare repo whose only branch is 'develop' — neither the requested branch nor master exists.
  work=$(mktemp -d)
  git init --quiet "$work"
  git -C "$work" symbolic-ref HEAD refs/heads/develop
  git -C "$work" commit --quiet --allow-empty -m "develop commit"
  git clone --quiet --bare "$work" "$TEST_DIR/bare/x.git"
  rm -rf "$work"
  git clone --quiet "$TEST_DIR/bare/x.git" "$src"
  git -C "$src" remote set-head origin -d   # drop origin/HEAD so the fallback resolves to (absent) master
  git -C "$src" checkout --quiet --detach HEAD
  run bash "$WORKER" "$src" REL1_99          # neither REL1_99 nor the master fallback exists here
  [ "$status" -ne 0 ]
}
