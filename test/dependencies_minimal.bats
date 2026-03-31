#!/usr/bin/env bats
#
# Tests for dependencies_minimal script.

@test "dependencies_minimal: shows usage with no arguments" {
  run ./dependencies_minimal
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
