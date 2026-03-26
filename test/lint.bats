#!/usr/bin/env bats
#
# Tests for lint script.

@test "lint: all scripts pass shellcheck" {
  command -v shellcheck >/dev/null || skip "shellcheck not installed"
  run ./lint
  [ "$status" -eq 0 ]
}
