#!/usr/bin/env bats
#
# Tests for lib/print_dep_summary.

@test "print_dep_summary: lists all dependencies" {
  run bash -c '
    component="extensions/Echo"
    all_deps=(A B C)
    required=(A)
    optional=(B C)
    total=4
    . lib/print_dep_summary
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"All dependencies for extensions/Echo (3):"* ]]
  [[ "$output" == *"  A"* ]]
  [[ "$output" == *"  B"* ]]
  [[ "$output" == *"  C"* ]]
}

@test "print_dep_summary: lists required dependencies" {
  run bash -c '
    component="extensions/Echo"
    all_deps=(A B)
    required=(A)
    optional=(B)
    total=2
    . lib/print_dep_summary
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Required dependencies (always included) (1):"* ]]
  [[ "$output" == *"  A"* ]]
}

@test "print_dep_summary: skips required section when none required" {
  run bash -c '
    component="extensions/Echo"
    all_deps=(A B)
    required=()
    optional=(A B)
    total=4
    . lib/print_dep_summary
  '
  [ "$status" -eq 0 ]
  [[ "$output" != *"Required dependencies"* ]]
}

@test "print_dep_summary: shows (none) when no optional deps" {
  run bash -c '
    component="extensions/Echo"
    all_deps=(A)
    required=(A)
    optional=()
    total=1
    . lib/print_dep_summary
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Optional dependencies to vary (0):"* ]]
  [[ "$output" == *"(none)"* ]]
}

@test "print_dep_summary: lists optional dependencies" {
  run bash -c '
    component="extensions/Echo"
    all_deps=(A B C)
    required=(A)
    optional=(B C)
    total=4
    . lib/print_dep_summary
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Optional dependencies to vary (2):"* ]]
}

@test "print_dep_summary: shows total combinations" {
  run bash -c '
    component="extensions/Echo"
    all_deps=(A B C)
    required=(A)
    optional=(B C)
    total=4
    . lib/print_dep_summary
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total combinations to test: 4 (from 0 to 2 optional dependencies)"* ]]
}
