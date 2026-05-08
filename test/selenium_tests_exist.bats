#!/usr/bin/env bats
#
# Tests for selenium_tests_exist script.

# Create a bare git repo with a package.json file.
# Usage: create_bare_repo <bare_repo_path> <package_json_content>
create_bare_repo() {
  local bare_repo="$1"   # path for the bare repo (e.g. ref/mediawiki/core.git)
  local content="$2"     # package.json content
  local tmp_repo
  tmp_repo=$(mktemp -d)  # temporary regular repo to commit into

  # Create a regular repo, add package.json, then clone it as bare
  git init --quiet "$tmp_repo"
  git -C "$tmp_repo" config user.email "test@test"  # needed in CI where no global git identity exists
  git -C "$tmp_repo" config user.name "test"         # needed in CI where no global git identity exists
  echo "$content" > "$tmp_repo/package.json"
  git -C "$tmp_repo" add package.json
  git -C "$tmp_repo" commit --quiet -m "add package.json"
  mkdir -p "$(dirname "$bare_repo")" # create parent directories
  git clone --quiet --bare "$tmp_repo" "$bare_repo"
  rm -rf "$tmp_repo" # clean up temporary repo
}

setup() {
  TEST_DIR=$(mktemp -d) # create a temp directory to simulate the project root
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

# --- Tests with src/ already present (e.g. after fresh_install/install) ---

@test "selenium_tests_exist: exits 0 when core has selenium-test script" {
  mkdir -p "$TEST_DIR/src"
  echo '{"scripts": {"selenium-test": "wdio"}}' > "$TEST_DIR/src/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 0 ]
}

@test "selenium_tests_exist: exits 1 when core has no selenium-test script" {
  mkdir -p "$TEST_DIR/src"
  echo '{"scripts": {"test": "jest"}}' > "$TEST_DIR/src/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 1 when core package.json missing" {
  mkdir -p "$TEST_DIR/src"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 0 for extension with selenium-test" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  echo '{"scripts": {"selenium-test": "wdio"}}' > "$TEST_DIR/src/extensions/Echo/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 0 ]
}

@test "selenium_tests_exist: exits 1 for extension without selenium-test" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  echo '{"scripts": {"test": "jest"}}' > "$TEST_DIR/src/extensions/Echo/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 1 for extension with no package.json" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 0 for skin with selenium-test" {
  mkdir -p "$TEST_DIR/src/skins/MinervaNeue"
  echo '{"scripts": {"selenium-test": "wdio"}}' > "$TEST_DIR/src/skins/MinervaNeue/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" skins/MinervaNeue
  [ "$status" -eq 0 ]
}

# --- Tests that read from ref/ bare repos (no src/ present) ---

@test "selenium_tests_exist: reads core from ref and finds selenium-test" {
  cd "$TEST_DIR"
  create_bare_repo ref/mediawiki/core.git '{"scripts": {"selenium-test": "wdio"}}'
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_DIR/src" ] # script must not write to src/ (avoids host/container UID conflicts)
}

@test "selenium_tests_exist: reads core from ref and exits 1 when no selenium-test" {
  cd "$TEST_DIR"
  create_bare_repo ref/mediawiki/core.git '{"scripts": {"test": "jest"}}'
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: reads extension from ref and finds selenium-test" {
  cd "$TEST_DIR"
  create_bare_repo ref/mediawiki/extensions/Echo.git '{"scripts": {"selenium-test": "wdio"}}'
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_DIR/src/extensions/Echo" ] # script must not write to src/ (avoids host/container UID conflicts)
}

@test "selenium_tests_exist: reads skin from ref and finds selenium-test" {
  cd "$TEST_DIR"
  create_bare_repo ref/mediawiki/skins/MinervaNeue.git '{"scripts": {"selenium-test": "wdio"}}'
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" skins/MinervaNeue
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_DIR/src/skins/MinervaNeue" ] # script must not write to src/ (avoids host/container UID conflicts)
}