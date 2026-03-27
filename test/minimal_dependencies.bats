#!/usr/bin/env bats
#
# Tests for minimal_dependencies script.

@test "minimal_dependencies: shows usage with no arguments" {
  run ./minimal_dependencies
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
