#!/usr/bin/env bats
#
# Tests for find_dependencies_minimal_greedy script.

setup() {
  TEST_DIR=$(mktemp -d) # temp project root with no ref/ — exercises the ensure_config failure path
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "find_dependencies_minimal_greedy: shows usage with no arguments" {
  run ./find_dependencies_minimal_greedy
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "find_dependencies_minimal_greedy: exits non-zero when ref/integration/config.git is missing" {
  # Regression: lib/minimal_setup must propagate list_dependencies failures so a missing
  # ref/integration/config.git (lib/ensure_config) causes the script to fail fast instead
  # of treating an empty deps stream as "no dependencies" and continuing.
  # _QUIBBLE_NO_INHIBIT=1 skips lib/inhibit_sleep so no background processes leak.
  cd "$TEST_DIR"
  run env _QUIBBLE_NO_INHIBIT=1 "$BATS_TEST_DIRNAME/../find_dependencies_minimal_greedy" extensions/Echo
  [ "$status" -ne 0 ]
  # The ensure_config message lands on stderr (and `run` merges stderr into $output).
  [[ "$output" == *"Run ./prepare first"* ]]
  # And lib/minimal_setup's own propagation message names the failing operation.
  [[ "$output" == *"failed to list dependencies for extensions/Echo"* ]]
}
