#!/usr/bin/env bats
#
# Tests for lib/debug_info.

@test "debug_info: suppresses output when stdout is not a terminal" {
  # Piping through cat means [ -t 1 ] is false
  run bash -c '. lib/debug_info | cat'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "debug_info: prints banner with _QUIBBLE_FORCE_TERMINAL even when stdout is not a terminal" {
  run bash -c 'export _QUIBBLE_FORCE_TERMINAL=1; . lib/debug_info | cat'
  [ "$status" -eq 0 ]
  [[ "$output" == *"OS:"* ]]
  [[ "$output" == *"bash:"* ]]
}

@test "debug_info: exits 0 when git is installed" {
  run bash -c '. lib/debug_info'
  [ "$status" -eq 0 ]
}

@test "debug_info: _quibble_print_host_resources prints CPU and RAM" {
  run bash -c '. lib/debug_info 2>/dev/null; _quibble_print_host_resources'
  [ "$status" -eq 0 ]
  [[ "$output" == *"CPU:"* ]]
  [[ "$output" == *"cores"* ]]
  [[ "$output" == *"RAM:"* ]]
  [[ "$output" == *"GB"* ]]
}

@test "debug_info: defines _quibble_print_docker_resources" {
  run bash -c '. lib/debug_info 2>/dev/null; type _quibble_print_docker_resources'
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}
