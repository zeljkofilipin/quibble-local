#!/usr/bin/env bats
#
# Tests for lib/build_component_list.

setup() {
  TEST_DIR=$(mktemp -d) # create temp dir to simulate project root
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "build_component_list: uses argument when provided" {
  run bash -c '
    set -euo pipefail
    set -- extensions/Echo
    . '"$BATS_TEST_DIRNAME"'/../lib/build_component_list
    printf "%s\n" "${components[@]}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "extensions/Echo" ]
}

@test "build_component_list: reads from gated when no argument" {
  cd "$TEST_DIR"
  # Create a mock gated script that outputs two components
  mkdir -p "$(dirname "$0")" 2>/dev/null || true
  cat > "$TEST_DIR/gated" << 'SCRIPT'
#!/usr/bin/env bash
echo "extensions/Echo"
echo "skins/MinervaNeue"
SCRIPT
  chmod +x "$TEST_DIR/gated"
  run bash -c '
    cd '"$TEST_DIR"'
    set --
    . '"$BATS_TEST_DIRNAME"'/../lib/build_component_list
    printf "%s\n" "${components[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"extensions/Echo"* ]]
  [[ "$output" == *"skins/MinervaNeue"* ]]
}
