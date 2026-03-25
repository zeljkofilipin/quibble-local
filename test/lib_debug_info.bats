#!/usr/bin/env bats
#
# Tests for lib/debug_info.

@test "debug_info: suppresses output when stdout is not a terminal" {
  # Piping through cat means [ -t 1 ] is false
  run bash -c '. lib/debug_info | cat'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "debug_info: exits 0 when git is installed" {
  run bash -c '. lib/debug_info'
  [ "$status" -eq 0 ]
}
