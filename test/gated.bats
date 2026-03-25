#!/usr/bin/env bats
#
# Tests for gated script.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
  mkdir -p "$TEST_DIR/src/config/zuul" # create fake config directory
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "gated: lists gated extensions and skins" {
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
  run "$BATS_TEST_DIRNAME/../gated"
  [ "$status" -eq 0 ]
  expected=$(printf "extensions/Echo\nextensions/VisualEditor\nskins/MinervaNeue")
  [ "$output" = "$expected" ]
}

@test "gated: handles empty lists" {
  cat > "$TEST_DIR/src/config/zuul/parameter_functions.py" <<'PYTHON'
gatedextensions = [
]
gatedskins = [
]
PYTHON
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../gated"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "gated: errors when config file missing" {
  rm -rf "$TEST_DIR/src/config/zuul/parameter_functions.py"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../gated"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}
