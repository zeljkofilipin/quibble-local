#!/usr/bin/env bats
#
# Tests for lib/print_header.

@test "print_header: prints separator in verbose mode" {
  run bash -c '
    verbose=1
    . lib/utc_timestamp
    . lib/print_header
    print_header "core"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"########################################"* ]]
  [[ "$output" == *"core"* ]]
}

@test "print_header: prints label only in silent mode" {
  run bash -c '
    verbose=""
    . lib/utc_timestamp
    . lib/print_header
    print_header "core"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "core " ]]
}

@test "print_header: includes UTC timestamp in verbose mode when TIME_UTC=1" {
  run bash -c '
    verbose=1
    TIME_UTC=1
    . lib/utc_timestamp
    . lib/print_header
    print_header "extensions/Echo"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"UTC"* ]]
}

@test "print_header: omits UTC timestamp in verbose mode when TIME_UTC unset" {
  run bash -c '
    verbose=1
    unset TIME_UTC
    . lib/utc_timestamp
    . lib/print_header
    print_header "extensions/Echo"
  '
  [ "$status" -eq 0 ]
  [[ "$output" != *"UTC"* ]]
}
