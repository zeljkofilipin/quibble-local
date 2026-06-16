#!/usr/bin/env bats
#
# Tests for lib/exit_trap (composable EXIT-trap registry).

@test "exit_trap: runs all registered handlers in registration order" {
  # Two handlers under different keys must both run, first-registered first.
  run bash -c '
    . lib/exit_trap
    h1() { echo "h1"; }
    h2() { echo "h2"; }
    quibble_register_exit_trap one h1
    quibble_register_exit_trap two h2
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "h1" ]
  [ "${lines[1]}" = "h2" ]
}

@test "exit_trap: re-registering a key replaces its handler (display override)" {
  # This is how lib/silent_output overrides lib/duration_trap: same key, last wins.
  run bash -c '
    . lib/exit_trap
    old() { echo "old"; }
    new() { echo "new"; }
    quibble_register_exit_trap display old
    quibble_register_exit_trap display new
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"new"* ]]
  [[ "$output" != *"old"* ]]
}

@test "exit_trap: a cleanup key still runs alongside a replaced display key" {
  # Models batch_setup: inhibit cleanup (own key) plus duration/silent_output (display key).
  run bash -c '
    . lib/exit_trap
    cleanup() { echo "cleanup"; }
    duration() { echo "duration"; }
    silent() { echo "silent"; }
    quibble_register_exit_trap inhibit cleanup
    quibble_register_exit_trap display duration
    quibble_register_exit_trap display silent
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"cleanup"* ]]   # cleanup always runs
  [[ "$output" == *"silent"* ]]    # last display handler runs
  [[ "$output" != *"duration"* ]]  # replaced display handler does not
}

@test "exit_trap: preserves the script exit code" {
  run bash -c '
    . lib/exit_trap
    noop() { :; }
    quibble_register_exit_trap k noop
    exit 7
  '
  [ "$status" -eq 7 ]
}

@test "exit_trap: passes the exit code to handlers as \$1" {
  run bash -c '
    . lib/exit_trap
    show() { echo "code=$1"; }
    quibble_register_exit_trap k show
    exit 3
  '
  [ "$status" -eq 3 ]
  [[ "$output" == *"code=3"* ]]
}

@test "exit_trap: a handler returning non-zero does not skip later handlers (set -e)" {
  # The dispatcher tolerates a failing handler (|| :) so set -e cannot abort the loop.
  run bash -c '
    set -e
    . lib/exit_trap
    boom() { return 1; }
    after() { echo "after-ran"; }
    quibble_register_exit_trap a boom
    quibble_register_exit_trap b after
    exit 5
  '
  [ "$status" -eq 5 ]
  [[ "$output" == *"after-ran"* ]]
}

@test "exit_trap: re-sourcing does not discard already-registered handlers" {
  # The load guard must preserve registrations across a double-source
  # (lib/duration_trap is sourced by both lib/batch_setup and lib/debug_info).
  run bash -c '
    . lib/exit_trap
    keep() { echo "keep-ran"; }
    quibble_register_exit_trap k keep
    . lib/exit_trap
    more() { echo "more-ran"; }
    quibble_register_exit_trap m more
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"keep-ran"* ]]
  [[ "$output" == *"more-ran"* ]]
}
