#!/usr/bin/env bats
#
# Tests for suggested_parallel script.

@test "suggested_parallel: outputs a number" {
  run ./suggested_parallel
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]] # output is a positive integer
}

@test "suggested_parallel: output is at least 1" {
  run ./suggested_parallel
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
