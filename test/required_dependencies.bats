#!/usr/bin/env bats
#
# Tests for required_dependencies script.

setup() {
  TEST_DIR=$(mktemp -d) # create a temp directory to simulate src/
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "required_dependencies: shows usage with no arguments" {
  run ./required_dependencies
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "required_dependencies: extracts required extensions from src/" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  cat > "$TEST_DIR/src/extensions/Echo/extension.json" <<'JSON'
{
  "requires": {
    "extensions": {
      "CommunityConfiguration": "*",
      "EventLogging": "*"
    }
  }
}
JSON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../required_dependencies" extensions/Echo
  [ "$status" -eq 0 ]
  [[ "$output" == *"CommunityConfiguration"* ]]
  [[ "$output" == *"EventLogging"* ]]
}

@test "required_dependencies: extracts required skins with prefix" {
  mkdir -p "$TEST_DIR/src/extensions/Foo"
  cat > "$TEST_DIR/src/extensions/Foo/extension.json" <<'JSON'
{
  "requires": {
    "skins": {
      "Vector": "*"
    }
  }
}
JSON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../required_dependencies" extensions/Foo
  [ "$status" -eq 0 ]
  [[ "$output" == *"skins/Vector"* ]]
}

@test "required_dependencies: exits 0 with no output when no requires" {
  mkdir -p "$TEST_DIR/src/extensions/Simple"
  echo '{"name": "Simple"}' > "$TEST_DIR/src/extensions/Simple/extension.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../required_dependencies" extensions/Simple
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "required_dependencies: exits 0 when extension.json missing" {
  mkdir -p "$TEST_DIR/src/extensions/NoJson"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../required_dependencies" extensions/NoJson
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "required_dependencies: reads skin.json for skins" {
  mkdir -p "$TEST_DIR/src/skins/MinervaNeue"
  cat > "$TEST_DIR/src/skins/MinervaNeue/skin.json" <<'JSON'
{
  "requires": {
    "extensions": {
      "MobileFrontend": "*"
    }
  }
}
JSON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../required_dependencies" skins/MinervaNeue
  [ "$status" -eq 0 ]
  [[ "$output" == *"MobileFrontend"* ]]
}
