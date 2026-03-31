#!/usr/bin/env bats
#
# Tests for dependencies_optional script.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
  mkdir -p "$TEST_DIR/src/config/zuul" # create fake config directory
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "dependencies_optional: shows usage with no arguments" {
  run ./dependencies_optional
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "dependencies_optional: filters out required deps" {
  # dependencies.yaml lists A, B, C as deps
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - A
  - B
  - C
YAML
  # extension.json requires A (so B and C are optional)
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  cat > "$TEST_DIR/src/extensions/Echo/extension.json" <<'JSON'
{
  "requires": {
    "extensions": {
      "A": "*"
    }
  }
}
JSON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../dependencies_optional" extensions/Echo
  [ "$status" -eq 0 ]
  expected=$(printf "B\nC")
  [ "$output" = "$expected" ]
}

@test "dependencies_optional: all deps optional when no requires" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - A
  - B
YAML
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  echo '{"name": "Echo"}' > "$TEST_DIR/src/extensions/Echo/extension.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../dependencies_optional" extensions/Echo
  [ "$status" -eq 0 ]
  expected=$(printf "A\nB")
  [ "$output" = "$expected" ]
}

@test "dependencies_optional: no optional deps when all are required" {
  cat > "$TEST_DIR/src/config/zuul/dependencies.yaml" <<'YAML'
Echo:
  - A
YAML
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  cat > "$TEST_DIR/src/extensions/Echo/extension.json" <<'JSON'
{
  "requires": {
    "extensions": {
      "A": "*"
    }
  }
}
JSON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../dependencies_optional" extensions/Echo
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
