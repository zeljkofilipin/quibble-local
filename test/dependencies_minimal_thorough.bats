#!/usr/bin/env bats
#
# Tests for dependencies_minimal_thorough script.

@test "dependencies_minimal_thorough: shows usage with no arguments" {
  run ./dependencies_minimal_thorough
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
