#!/usr/bin/env bats
#
# Tests for lib/run_quibble_test.

@test "run_quibble_test: defines the run_quibble_test function" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/run_quibble_test
    type run_quibble_test
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}
