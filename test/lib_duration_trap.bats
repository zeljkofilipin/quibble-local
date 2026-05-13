#!/usr/bin/env bats
#
# Tests for lib/duration_trap.

@test "duration_trap: provides format_duration function" {
  run bash -c '
    . lib/duration_trap
    _quibble_format_duration 61
  '
  [ "$status" -eq 0 ]
  [ "$output" = "1m 1s" ]
}

@test "duration_trap: does not set trap when stdout is not a terminal" {
  # run captures output via pipe, so [ -t 1 ] is false
  run bash -c '
    . lib/duration_trap
    trap -p EXIT
  '
  [ "$status" -eq 0 ]
  # No EXIT trap should be set (stdout is not a terminal in run)
  [[ "$output" != *"_quibble_duration_exit"* ]]
}

@test "duration_trap: sets trap with _QUIBBLE_FORCE_TERMINAL even when stdout is not a terminal" {
  run bash -c '
    export _QUIBBLE_FORCE_TERMINAL=1
    . lib/duration_trap
    trap -p EXIT
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"_quibble_duration_exit"* ]]
}
