#!/usr/bin/env bats
#
# Tests for suggest_parallel script.

@test "suggest_parallel: outputs a number" {
  run ./suggest_parallel
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]] # output is a positive integer
}

@test "suggest_parallel: output is at least 1" {
  run ./suggest_parallel
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
