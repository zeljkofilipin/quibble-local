#!/usr/bin/env bats
#
# Tests for lib/inhibit_sleep.

@test "inhibit_sleep: skips when _QUIBBLE_NO_INHIBIT is set" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    . lib/inhibit_sleep
    echo "ok"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "inhibit_sleep: no background processes when skipped" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    . lib/inhibit_sleep
    # jobs -p lists background process PIDs; should be empty
    jobs -p
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
