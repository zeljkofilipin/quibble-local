#!/usr/bin/env bats
#
# Tests for list_dependencies_combinations script.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
  mkdir -p "$TEST_DIR/src/config/zuul" # create fake config directory
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "list_dependencies_combinations: shows usage with no arguments" {
  run ./list_dependencies_combinations
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "list_dependencies_combinations: single dependency produces one combination" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - EventLogging
YAML
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_dependencies_combinations" extensions/Echo
  [ "$status" -eq 0 ]
  [ "$output" = "EventLogging" ]
}

@test "list_dependencies_combinations: two dependencies produce three combinations" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - A
  - B
YAML
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_dependencies_combinations" extensions/Echo
  [ "$status" -eq 0 ]
  expected=$(printf "A\nB\nA B")
  [ "$output" = "$expected" ]
}

@test "list_dependencies_combinations: no dependencies produces no output" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Other:
  - Dep1
YAML
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_dependencies_combinations" extensions/Echo
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
