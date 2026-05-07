#!/usr/bin/env bats
#
# Tests for list_dependencies script.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
  mkdir -p "$TEST_DIR/src/config/zuul" # create fake config directory
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "list_dependencies: shows usage with no arguments" {
  cd "$TEST_DIR"
  # ensure_config won't clone because src/config exists
  run "$BATS_TEST_DIRNAME/../list_dependencies"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "list_dependencies: lists extension dependencies" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - EventLogging
  - CommunityConfiguration
Other:
  - Foo
YAML
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_dependencies" extensions/Echo
  [ "$status" -eq 0 ]
  expected=$(printf "EventLogging\nCommunityConfiguration")
  [ "$output" = "$expected" ]
}

@test "list_dependencies: lists skin dependencies" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
skins/MinervaNeue:
  - MobileFrontend
YAML
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_dependencies" skins/MinervaNeue
  [ "$status" -eq 0 ]
  [ "$output" = "MobileFrontend" ]
}

@test "list_dependencies: returns nothing for unknown component" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - Dep1
YAML
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_dependencies" extensions/Unknown
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "list_dependencies: strips extensions/ prefix for lookup" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - Dep1
YAML
  cd "$TEST_DIR"
  # "extensions/Echo" should look up "Echo:" in the yaml
  run "$BATS_TEST_DIRNAME/../list_dependencies" extensions/Echo
  [ "$status" -eq 0 ]
  [ "$output" = "Dep1" ]
}
