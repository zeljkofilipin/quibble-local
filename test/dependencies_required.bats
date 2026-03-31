#!/usr/bin/env bats
#
# Tests for dependencies_required script.

setup() {
  TEST_DIR=$(mktemp -d) # create a temp directory to simulate src/
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "dependencies_required: shows usage with no arguments" {
  run ./dependencies_required
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "dependencies_required: extracts required extensions from src/" {
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
  run "$BATS_TEST_DIRNAME/../dependencies_required" extensions/Echo
  [ "$status" -eq 0 ]
  [[ "$output" == *"CommunityConfiguration"* ]]
  [[ "$output" == *"EventLogging"* ]]
}

@test "dependencies_required: extracts required skins with prefix" {
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
  run "$BATS_TEST_DIRNAME/../dependencies_required" extensions/Foo
  [ "$status" -eq 0 ]
  [[ "$output" == *"skins/Vector"* ]]
}

@test "dependencies_required: exits 0 with no output when no requires" {
  mkdir -p "$TEST_DIR/src/extensions/Simple"
  echo '{"name": "Simple"}' > "$TEST_DIR/src/extensions/Simple/extension.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../dependencies_required" extensions/Simple
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "dependencies_required: exits 0 when extension.json missing" {
  mkdir -p "$TEST_DIR/src/extensions/NoJson"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../dependencies_required" extensions/NoJson
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "dependencies_required: reads skin.json for skins" {
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
  run "$BATS_TEST_DIRNAME/../dependencies_required" skins/MinervaNeue
  [ "$status" -eq 0 ]
  [[ "$output" == *"MobileFrontend"* ]]
}
