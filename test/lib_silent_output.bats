#!/usr/bin/env bats
#
# Tests for lib/silent_output.

@test "silent_output: does not activate in verbose mode" {
  run bash -c '
    export VERBOSE=1
    . lib/silent_output
    echo "direct output"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"direct output"* ]]
}

@test "silent_output: does not activate when _QUIBBLE_OUTPUT_MANAGED is set" {
  run bash -c '
    unset VERBOSE
    export _QUIBBLE_OUTPUT_MANAGED=1
    . lib/silent_output
    echo "direct output"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"direct output"* ]]
}

@test "silent_output: does not activate when stdout is not a terminal" {
  # run captures output via pipe, so [ -t 1 ] is false
  run bash -c '
    unset VERBOSE
    unset _QUIBBLE_OUTPUT_MANAGED
    . lib/silent_output
    echo "direct output"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"direct output"* ]]
}

@test "silent_output: activates with _QUIBBLE_FORCE_TERMINAL even when stdout is not a terminal" {
  # run captures via pipe (not a TTY) but _QUIBBLE_FORCE_TERMINAL=1 must still engage silent mode:
  # the "direct output" line should be replaced by a single dot in the captured output.
  run bash -c '
    unset VERBOSE
    unset _QUIBBLE_OUTPUT_MANAGED
    export _QUIBBLE_FORCE_TERMINAL=1
    . lib/silent_output
    echo "direct output"
  '
  [ "$status" -eq 0 ]
  [[ "$output" != *"direct output"* ]]   # full text suppressed
  [[ "$output" == *"."* ]]                # replaced by a dot
}
