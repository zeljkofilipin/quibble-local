#!/usr/bin/env bats
#
# Tests for find_dependencies_minimal_thorough script.

@test "find_dependencies_minimal_thorough: shows usage with no arguments" {
  run ./find_dependencies_minimal_thorough
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
