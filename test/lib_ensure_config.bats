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
