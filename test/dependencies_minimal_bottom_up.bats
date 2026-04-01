#!/usr/bin/env bats
#
# Tests for dependencies_minimal_bottom_up script.

@test "dependencies_minimal_bottom_up: shows usage with no arguments" {
  run ./dependencies_minimal_bottom_up
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
