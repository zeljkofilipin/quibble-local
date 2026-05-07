#!/usr/bin/env bats
#
# Tests for find_dependencies_minimal_bottom_up script.

@test "find_dependencies_minimal_bottom_up: shows usage with no arguments" {
  run ./find_dependencies_minimal_bottom_up
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
