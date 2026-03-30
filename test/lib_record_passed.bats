#!/usr/bin/env bats
#
# Tests for lib/record_passed.

@test "record_passed: adds component to passed list" {
  run bash -c '
    failed=""
    passed=""
    . lib/record_passed
    record_passed "core"
    echo "$passed"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"core"* ]]
}

@test "record_passed: skips if component already failed" {
  run bash -c '
    failed="
  core"
    passed=""
    . lib/record_passed
    record_passed "core"
    echo "passed:${passed}:end"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "passed::end" ]]
}
