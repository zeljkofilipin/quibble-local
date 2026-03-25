#!/usr/bin/env bats
#
# Tests for install script.

@test "install: shows usage with no arguments" {
  run ./install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
