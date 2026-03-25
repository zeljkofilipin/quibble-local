#!/usr/bin/env bats
#
# Tests for lib/heartbeat (run_with_dots function).

@test "run_with_dots: returns 0 for successful command" {
  . lib/heartbeat
  TEST_LOG=$(mktemp)
  run run_with_dots "$TEST_LOG" echo "hello"
  rm -f "$TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "run_with_dots: returns non-zero for failing command" {
  . lib/heartbeat
  TEST_LOG=$(mktemp)
  run run_with_dots "$TEST_LOG" false
  rm -f "$TEST_LOG"
  [ "$status" -ne 0 ]
}

@test "run_with_dots: saves output to log file" {
  . lib/heartbeat
  TEST_LOG=$(mktemp)
  run_with_dots "$TEST_LOG" echo "hello world" > /dev/null
  result=$(cat "$TEST_LOG")
  rm -f "$TEST_LOG"
  [[ "$result" == *"hello world"* ]]
}

@test "run_with_dots: prints dots for each line" {
  . lib/heartbeat
  TEST_LOG=$(mktemp)
  # printf outputs 3 lines
  result=$(run_with_dots "$TEST_LOG" printf "a\nb\nc\n")
  rm -f "$TEST_LOG"
  [ "$result" = "..." ]
}
