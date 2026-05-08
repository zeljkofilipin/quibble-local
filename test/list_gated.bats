#!/usr/bin/env bats
#
# Tests for list_gated script.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
  mkdir -p "$TEST_DIR/src/config/zuul" # create fake config directory
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "list_gated: lists gated extensions and skins" {
  cat > "$TEST_DIR/src/config/zuul/parameter_functions.py" <<'PYTHON'
gatedextensions = [
    'Echo',
    'VisualEditor',
]
gatedskins = [
    'MinervaNeue',
]
PYTHON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_gated"
  [ "$status" -eq 0 ]
  expected=$(printf "extensions/Echo\nextensions/VisualEditor\nskins/MinervaNeue")
  [ "$output" = "$expected" ]
}

@test "list_gated: handles empty lists" {
  cat > "$TEST_DIR/src/config/zuul/parameter_functions.py" <<'PYTHON'
gatedextensions = [
]
gatedskins = [
]
PYTHON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_gated"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "list_gated: errors when config file missing" {
  rm -rf "$TEST_DIR/src/config/zuul/parameter_functions.py"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../list_gated"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}
