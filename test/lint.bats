#!/usr/bin/env bats
#
# Tests for lint script.

@test "lint: all scripts pass shellcheck" {
  run ./lint
  [ "$status" -eq 0 ]
}
