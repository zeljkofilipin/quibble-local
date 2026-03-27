#!/usr/bin/env bats
#
# Tests for lib/print_found.

@test "print_found: prints required and optional deps" {
  run bash -c '
    component="extensions/Echo"
    required_str="Dep1 Dep2"
    required=(Dep1 Dep2)
    optional_combo="Dep3 Dep4"
    . lib/print_found
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"FOUND: minimum dependencies for extensions/Echo"* ]]
  [[ "$output" == *"Required (always needed)"* ]]
  [[ "$output" == *"Dep1"* ]]
  [[ "$output" == *"Dep2"* ]]
  [[ "$output" == *"Optional (minimum needed)"* ]]
  [[ "$output" == *"Dep3"* ]]
  [[ "$output" == *"Dep4"* ]]
}

@test "print_found: required only when no optional" {
  run bash -c '
    component="extensions/Echo"
    required_str="Dep1"
    required=(Dep1)
    optional_combo=""
    . lib/print_found
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Required (always needed)"* ]]
  [[ "$output" == *"Dep1"* ]]
  [[ "$output" == *"Optional: (none needed)"* ]]
}

@test "print_found: no dependencies needed" {
  run bash -c '
    component="extensions/Echo"
    required_str=""
    required=()
    optional_combo=""
    . lib/print_found
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"No dependencies needed"* ]]
}

@test "print_found: optional only when no required" {
  run bash -c '
    component="extensions/Echo"
    required_str=""
    required=()
    optional_combo="Dep1"
    . lib/print_found
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Optional (minimum needed)"* ]]
  [[ "$output" == *"Dep1"* ]]
  [[ "$output" != *"Required"* ]]
}
