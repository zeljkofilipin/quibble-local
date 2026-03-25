#!/usr/bin/env bats
#
# Tests for lib/print_results.

@test "print_results: prints all passed when nothing failed" {
  run bash -c '
    passed="
  step1
  step2"
    failed=""
    . lib/print_results
    print_results
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASSED:"* ]]
  [[ "$output" == *"step1"* ]]
  [[ "$output" == *"step2"* ]]
  [[ "$output" == *"All passed."* ]]
}

@test "print_results: exits 1 when something failed" {
  run bash -c '
    passed="
  step1"
    failed="
  step2"
    . lib/print_results
    print_results
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"PASSED:"* ]]
  [[ "$output" == *"FAILED:"* ]]
  [[ "$output" == *"step2"* ]]
}

@test "print_results: shows log hint in silent mode" {
  run bash -c '
    VERBOSE=""
    passed=""
    failed="
  step1"
    . lib/print_results
    print_results
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"Logs: log/silent/"* ]]
}

@test "print_results: no log hint in verbose mode" {
  run bash -c '
    VERBOSE=1
    passed=""
    failed="
  step1"
    . lib/print_results
    print_results
  '
  [ "$status" -eq 1 ]
  [[ "$output" != *"Logs: log/silent/"* ]]
}

@test "print_results: prints results header" {
  run bash -c '
    passed=""
    failed=""
    . lib/print_results
    print_results
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Results"* ]]
}
