#!/usr/bin/env bats
#
# Tests for dependencies_minimal_greedy script.

@test "dependencies_minimal_greedy: shows usage with no arguments" {
  run ./dependencies_minimal_greedy
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
