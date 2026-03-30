#!/usr/bin/env bats
#
# Tests for run_php_unit_tests argument parsing and quibble_args building.
# Sources lib/parse_component_args for argument parsing,
# then tests the phpunit-specific quibble_args logic.

@test "run_php_unit_tests: parses component argument" {
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

@test "run_php_unit_tests: parses --filter argument" {
  run bash -c '
    set -euo pipefail
    set -- extensions/Echo --filter testNotificationCount
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    # Build quibble_args like the script does
    if [ ${#extra_args[@]} -gt 0 ]; then
      quibble_args=(--command "php tests/phpunit/phpunit.php ${extra_args[*]}")
    else
      quibble_args=(--run phpunit)
    fi
    echo "${quibble_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"php tests/phpunit/phpunit.php --filter testNotificationCount"* ]]
}

@test "run_php_unit_tests: no args uses --run phpunit" {
  run bash -c '
    set -euo pipefail
    set --
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    if [ ${#extra_args[@]} -gt 0 ]; then
      quibble_args=(--command "php tests/phpunit/phpunit.php ${extra_args[*]}")
    else
      quibble_args=(--run phpunit)
    fi
    echo "${quibble_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--run phpunit"* ]]
}
