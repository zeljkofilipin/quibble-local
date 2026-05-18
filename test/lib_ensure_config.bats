#!/usr/bin/env bats
#
# Tests for lib/ensure_config.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "ensure_config: skips clone when src/config already exists" {
  mkdir -p "$TEST_DIR/src/config"
  cd "$TEST_DIR"
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/ensure_config
    echo "config_src_dir=$config_src_dir"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"config_src_dir=src/config"* ]]
}

@test "ensure_config: errors when bare repo missing and src/config missing" {
  cd "$TEST_DIR"
  run bash -c '. '"$BATS_TEST_DIRNAME"'/../lib/ensure_config'
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
  [[ "$output" == *"Run ./prepare first"* ]]
}

@test "ensure_config: error message goes to stderr, not stdout" {
  # Regression: this message used to be on stdout, which polluted callers that read
  # list_dependencies via process substitution (lib/minimal_setup) — the error text
  # would end up as a "dependency name" in QUIBBLE_DEPS and lib/resolve_deps would
  # then try to clone a Gerrit repo named "Error:".
  # Run in a subshell (bash -c) so the script's `exit 1` doesn't terminate the test runner.
  cd "$TEST_DIR"
  stdout=$(bash -c '. "$1"' _ "$BATS_TEST_DIRNAME"/../lib/ensure_config 2>/dev/null || true) # drop stderr to inspect stdout alone
  stderr=$(bash -c '. "$1"' _ "$BATS_TEST_DIRNAME"/../lib/ensure_config 2>&1 >/dev/null || true) # drop stdout to inspect stderr alone
  [ -z "$stdout" ]
  [[ "$stderr" == *"not found"* ]]
  [[ "$stderr" == *"Run ./prepare first"* ]]
}

@test "ensure_config: sets config_ref_dir and config_src_dir variables" {
  mkdir -p "$TEST_DIR/src/config"
  cd "$TEST_DIR"
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/ensure_config
    echo "ref=$config_ref_dir"
    echo "src=$config_src_dir"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"ref=ref/integration/config.git"* ]]
  [[ "$output" == *"src=src/config"* ]]
}
