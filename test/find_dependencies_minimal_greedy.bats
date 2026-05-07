#!/usr/bin/env bats
#
# Tests for find_dependencies_minimal_greedy script.

@test "find_dependencies_minimal_greedy: shows usage with no arguments" {
  run ./find_dependencies_minimal_greedy
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
