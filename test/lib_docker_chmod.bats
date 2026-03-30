#!/usr/bin/env bats
#
# Tests for lib/docker_chmod.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "docker_chmod: defines the docker_chmod function" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/docker_chmod
    type docker_chmod
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}

@test "docker_chmod: sets permissions on user-owned directory" {
  mkdir -p "$TEST_DIR/mydir"
  chmod 755 "$TEST_DIR/mydir" # start with restricted permissions
  run bash -c '
    export QUIBBLE_DIR='"$TEST_DIR"'
    export QUIBBLE_IMAGE=unused # not needed when local chmod succeeds
    . '"$BATS_TEST_DIRNAME"'/../lib/docker_chmod
    cd '"$TEST_DIR"'
    docker_chmod mydir
  '
  [ "$status" -eq 0 ]
  # Verify permissions were changed (stat format differs on macOS vs Linux)
  perms=$(stat -f "%Lp" "$TEST_DIR/mydir" 2>/dev/null || stat -c "%a" "$TEST_DIR/mydir" 2>/dev/null)
  [ "$perms" = "777" ]
}

@test "docker_chmod: handles multiple directories" {
  mkdir -p "$TEST_DIR/dir1" "$TEST_DIR/dir2" "$TEST_DIR/dir3"
  chmod 755 "$TEST_DIR/dir1" "$TEST_DIR/dir2" "$TEST_DIR/dir3"
  run bash -c '
    export QUIBBLE_DIR='"$TEST_DIR"'
    export QUIBBLE_IMAGE=unused
    . '"$BATS_TEST_DIRNAME"'/../lib/docker_chmod
    cd '"$TEST_DIR"'
    docker_chmod dir1 dir2 dir3
  '
  [ "$status" -eq 0 ]
  for d in dir1 dir2 dir3; do
    perms=$(stat -f "%Lp" "$TEST_DIR/$d" 2>/dev/null || stat -c "%a" "$TEST_DIR/$d" 2>/dev/null)
    [ "$perms" = "777" ]
  done
}
