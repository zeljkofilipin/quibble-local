#!/usr/bin/env bats
#
# Tests for lib/utc_timestamp.

@test "utc_timestamp: outputs nothing by default (TIME_UTC unset)" {
  run bash -c '
    unset TIME_UTC
    . lib/utc_timestamp
    utc_timestamp
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "utc_timestamp: outputs UTC timestamp in expected format when TIME_UTC=1" {
  run bash -c '
    TIME_UTC=1
    . lib/utc_timestamp
    utc_timestamp
  '
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ UTC$ ]]
}
