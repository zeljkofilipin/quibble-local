#!/usr/bin/env bats
#
# Tests for lib/format_duration.

setup() {
  export TIME_ELAPSED=1 # enable formatter for tests that exercise its formatting logic
  . lib/format_duration # source the formatting function
}

teardown() {
  unset TIME_ELAPSED
}

@test "format_duration: outputs nothing by default (TIME_ELAPSED unset)" {
  run bash -c '
    unset TIME_ELAPSED
    . lib/format_duration
    _quibble_format_duration 61
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "format_duration_padded: outputs nothing by default (TIME_ELAPSED unset)" {
  run bash -c '
    unset TIME_ELAPSED
    . lib/format_duration
    _quibble_format_duration_padded 61
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "format_duration_padded: returns ' (DURATION)' with leading space when TIME_ELAPSED=1" {
  result=$(_quibble_format_duration_padded 61)
  [ "$result" = " (1m 1s)" ]
}

@test "format_duration: 0 seconds" {
  result=$(_quibble_format_duration 0)
  [ "$result" = "0s" ]
}

@test "format_duration: seconds only" {
  result=$(_quibble_format_duration 45)
  [ "$result" = "45s" ]
}

@test "format_duration: minutes and seconds" {
  result=$(_quibble_format_duration 125) # 2m 5s
  [ "$result" = "2m 5s" ]
}

@test "format_duration: exact minute" {
  result=$(_quibble_format_duration 60) # 1m 0s
  [ "$result" = "1m 0s" ]
}

@test "format_duration: hours, minutes, and seconds" {
  result=$(_quibble_format_duration 3661) # 1h 1m 1s
  [ "$result" = "1h 1m 1s" ]
}

@test "format_duration: exact hour" {
  result=$(_quibble_format_duration 3600) # 1h 0s
  [ "$result" = "1h 0s" ]
}

@test "format_duration: hours and seconds, no minutes" {
  result=$(_quibble_format_duration 3601) # 1h 1s
  [ "$result" = "1h 1s" ]
}

@test "format_duration: days, hours, minutes, and seconds" {
  result=$(_quibble_format_duration 90061) # 1d 1h 1m 1s
  [ "$result" = "1d 1h 1m 1s" ]
}

@test "format_duration: exact day" {
  result=$(_quibble_format_duration 86400) # 1d 0s
  [ "$result" = "1d 0s" ]
}
