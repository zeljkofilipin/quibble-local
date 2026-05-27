#!/usr/bin/env bats
#
# Tests for lib/duration_trap.

@test "duration_trap: provides format_duration function (TIME_ELAPSED=1)" {
  run bash -c '
    TIME_ELAPSED=1
    . lib/duration_trap
    _quibble_format_duration 61
  '
  [ "$status" -eq 0 ]
  [ "$output" = "1m 1s" ]
}

@test "duration_trap: format_duration outputs nothing when TIME_ELAPSED unset" {
  run bash -c '
    unset TIME_ELAPSED
    . lib/duration_trap
    _quibble_format_duration 61
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
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

@test "duration_trap: EXIT trap emits nothing when both TIME_ELAPSED and TIME_UTC are unset" {
  # Regression guard: with neither gate set, the trap must not emit a bare "()" line or
  # any UTC line. The trap still fires (it's installed under _QUIBBLE_FORCE_TERMINAL=1),
  # but its body must short-circuit to silence.
  run bash -c '
    unset TIME_ELAPSED TIME_UTC
    export _QUIBBLE_FORCE_TERMINAL=1
    . lib/duration_trap
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "duration_trap: EXIT trap emits only duration when TIME_ELAPSED=1 (TIME_UTC unset)" {
  # Legacy behavior: the trap output is "(Xs)" with no UTC suffix and no trailing space.
  run bash -c '
    TIME_ELAPSED=1
    unset TIME_UTC
    export _QUIBBLE_FORCE_TERMINAL=1
    . lib/duration_trap
  '
  [ "$status" -eq 0 ]
  # Must look like "(0s)" or "(1s)" etc. — open paren, digits/letters, "s)", nothing after.
  [[ "$output" =~ ^\([0-9].*s\)$ ]]
}

@test "duration_trap: EXIT trap emits only UTC stamp when TIME_UTC=1 (TIME_ELAPSED unset)" {
  # New behavior: TIME_UTC alone produces a bare "YYYY-MM-DD HH:MM:SS UTC" line, no parens.
  run bash -c '
    TIME_UTC=1
    unset TIME_ELAPSED
    export _QUIBBLE_FORCE_TERMINAL=1
    . lib/duration_trap
  '
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ UTC$ ]]
}

@test "duration_trap: EXIT trap combines duration and UTC stamp on one line when both set" {
  # New behavior: with both gates set the trap emits "(Xs) YYYY-MM-DD HH:MM:SS UTC" on a
  # single line — matches the install_each_gated / find_dependencies_minimal_thorough
  # formatting so a user piping output to a log gets one anchored line per script exit.
  run bash -c '
    TIME_ELAPSED=1 TIME_UTC=1
    export _QUIBBLE_FORCE_TERMINAL=1
    . lib/duration_trap
  '
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^\([0-9].*s\)\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ UTC$ ]]
}
