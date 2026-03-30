#!/usr/bin/env bats
#
# Tests for lib/clone_or_fetch.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

# Create a bare git repo at the given path (with one empty commit).
# Usage: create_test_bare_repo <path>
create_test_bare_repo() {
  local bare_path="$1"   # path for the bare repo
  local tmp_repo
  tmp_repo=$(mktemp -d)  # temporary regular repo to commit into
  git init --quiet "$tmp_repo"
  git -C "$tmp_repo" config user.email "test@test"  # needed in CI where no global git identity exists
  git -C "$tmp_repo" config user.name "test"         # needed in CI where no global git identity exists
  git -C "$tmp_repo" commit --quiet --allow-empty -m "init"
  mkdir -p "$(dirname "$bare_path")" # create parent directories
  git clone --quiet --bare "$tmp_repo" "$bare_path"
  rm -rf "$tmp_repo" # clean up temporary repo
}

@test "clone_or_fetch: defines the clone_or_fetch function" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/clone_or_fetch
    type clone_or_fetch
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}

@test "clone_or_fetch: fetches existing bare repo" {
  cd "$TEST_DIR"
  create_test_bare_repo "$TEST_DIR/ref/test/repo.git"
  run bash -c '
    cd '"$TEST_DIR"'
    . '"$BATS_TEST_DIRNAME"'/../lib/clone_or_fetch
    clone_or_fetch test/repo
  '
  [ "$status" -eq 0 ]
}

@test "clone_or_fetch: fetches with --quiet flag" {
  cd "$TEST_DIR"
  create_test_bare_repo "$TEST_DIR/ref/test/repo.git"
  run bash -c '
    cd '"$TEST_DIR"'
    . '"$BATS_TEST_DIRNAME"'/../lib/clone_or_fetch
    clone_or_fetch --quiet test/repo
  '
  [ "$status" -eq 0 ]
}

@test "clone_or_fetch: creates parent directories for new repos" {
  cd "$TEST_DIR"
  # Mock git clone to avoid network access (just create the directory)
  run bash -c '
    cd '"$TEST_DIR"'
    . '"$BATS_TEST_DIRNAME"'/../lib/clone_or_fetch
    # Override git to avoid actual Gerrit clone
    git() {
      if [ "$1" = "clone" ]; then
        # Find the last argument (destination path)
        local dest="${@: -1}"
        mkdir -p "$dest" # simulate a successful clone
      fi
    }
    clone_or_fetch deep/nested/repo
    # Check that parent directories were created
    [ -d ref/deep/nested ]
  '
  [ "$status" -eq 0 ]
}
