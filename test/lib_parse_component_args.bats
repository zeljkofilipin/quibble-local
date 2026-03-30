#!/usr/bin/env bats
#
# Tests for lib/parse_component_args.

@test "parse_component_args: parses extension component" {
  run bash -c '
    set -euo pipefail
    set -- extensions/Echo
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    echo "component=$component"
    echo "zuul=${zuul_project[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"component=extensions/Echo"* ]]
  [[ "$output" == *"ZUUL_PROJECT=mediawiki/extensions/Echo"* ]]
}

@test "parse_component_args: parses skin component" {
  run bash -c '
    set -euo pipefail
    set -- skins/MinervaNeue
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    echo "component=$component"
    echo "zuul=${zuul_project[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"component=skins/MinervaNeue"* ]]
  [[ "$output" == *"ZUUL_PROJECT=mediawiki/skins/MinervaNeue"* ]]
}

@test "parse_component_args: collects extra args" {
  run bash -c '
    set -euo pipefail
    set -- --spec tests/selenium/specs/page.js
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    echo "component=$component"
    echo "extra=${extra_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"component="* ]]
  [[ "$output" == *"extra=--spec tests/selenium/specs/page.js"* ]]
}

@test "parse_component_args: separates component from extra args" {
  run bash -c '
    set -euo pipefail
    set -- extensions/Echo --filter testName
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    echo "component=$component"
    echo "extra=${extra_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"component=extensions/Echo"* ]]
  [[ "$output" == *"extra=--filter testName"* ]]
}

@test "parse_component_args: no args sets empty defaults" {
  run bash -c '
    set -euo pipefail
    set --
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    echo "component=$component"
    echo "extra_count=${#extra_args[@]}"
    echo "zuul_count=${#zuul_project[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"component="* ]]
  [[ "$output" == *"extra_count=0"* ]]
  [[ "$output" == *"zuul_count=0"* ]]
}
