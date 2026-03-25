#!/usr/bin/env bats
#
# Tests for lib/build_full_combo.

@test "build_full_combo: combines required and optional" {
  run bash -c '
    required_str="A B"
    optional_combo="C D"
    . lib/build_full_combo
    echo "$full_combo"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "A B C D" ]
}

@test "build_full_combo: required only when no optional" {
  run bash -c '
    required_str="A B"
    optional_combo=""
    . lib/build_full_combo
    echo "$full_combo"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "A B" ]
}

@test "build_full_combo: optional only when no required" {
  run bash -c '
    required_str=""
    optional_combo="C D"
    . lib/build_full_combo
    echo "$full_combo"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "C D" ]
}

@test "build_full_combo: empty when both empty" {
  run bash -c '
    required_str=""
    optional_combo=""
    . lib/build_full_combo
    echo "$full_combo"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
