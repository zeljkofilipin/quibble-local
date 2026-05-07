#!/usr/bin/env bats
#
# Tests for lib/resolve_deps.
# Uses QUIBBLE_DEPS env var to avoid needing ./list_dependencies and config files.
# Pre-creates ref/ directories so git clone is skipped.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "resolve_deps: builds extension repo paths" {
  # Pre-create bare repo dirs so git clone is skipped
  mkdir -p "$TEST_DIR/ref/mediawiki/extensions/Echo.git"
  mkdir -p "$TEST_DIR/ref/mediawiki/extensions/EventLogging.git"
  cd "$TEST_DIR"
  run bash -c '
    component="extensions/Echo"
    export QUIBBLE_DEPS="Echo EventLogging"
    . '"$BATS_TEST_DIRNAME"'/../lib/resolve_deps
    printf "%s\n" "${deps[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"mediawiki/extensions/Echo"* ]]
  [[ "$output" == *"mediawiki/extensions/EventLogging"* ]]
}

@test "resolve_deps: builds skin repo paths with mediawiki/ prefix" {
  mkdir -p "$TEST_DIR/ref/mediawiki/skins/MinervaNeue.git"
  cd "$TEST_DIR"
  run bash -c '
    component="skins/MinervaNeue"
    export QUIBBLE_DEPS="skins/MinervaNeue"
    . '"$BATS_TEST_DIRNAME"'/../lib/resolve_deps
    printf "%s\n" "${deps[@]}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mediawiki/skins/MinervaNeue" ]
}

@test "resolve_deps: handles mixed extensions and skins" {
  mkdir -p "$TEST_DIR/ref/mediawiki/extensions/Echo.git"
  mkdir -p "$TEST_DIR/ref/mediawiki/skins/Vector.git"
  cd "$TEST_DIR"
  run bash -c '
    component="extensions/Echo"
    export QUIBBLE_DEPS="Echo skins/Vector"
    . '"$BATS_TEST_DIRNAME"'/../lib/resolve_deps
    printf "%s\n" "${deps[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"mediawiki/extensions/Echo"* ]]
  [[ "$output" == *"mediawiki/skins/Vector"* ]]
}

@test "resolve_deps: empty QUIBBLE_DEPS produces no deps" {
  cd "$TEST_DIR"
  run bash -c '
    component="extensions/Echo"
    export QUIBBLE_DEPS=""
    . '"$BATS_TEST_DIRNAME"'/../lib/resolve_deps
    echo "count=${#deps[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"count=0"* ]]
}
