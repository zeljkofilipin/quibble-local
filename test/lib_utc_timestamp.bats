#!/usr/bin/env bats
#
# Tests for lib/utc_timestamp.

@test "utc_timestamp: outputs UTC timestamp in expected format" {
  run bash -c '
    . lib/utc_timestamp
    utc_timestamp
  '
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ UTC$ ]]
}
