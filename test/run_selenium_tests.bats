#!/usr/bin/env bats
#
# Tests for run_selenium_tests argument parsing and quibble_args building.
# Sources lib/parse_component_args for argument parsing,
# then tests the selenium-specific quibble_args logic.

@test "run_selenium_tests: parses component argument" {
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

@test "run_selenium_tests: parses --spec argument" {
  run bash -c '
    set -euo pipefail
    set -- --spec tests/selenium/specs/page.js
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    echo "extra=${extra_args[*]}"
    echo "component=$component"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"extra=--spec tests/selenium/specs/page.js"* ]]
  [[ "$output" == *"component="* ]]
}

@test "run_selenium_tests: parses component with --spec and --mochaOpts.grep" {
  run bash -c '
    set -euo pipefail
    set -- extensions/Echo --spec tests/selenium/specs/notifications.js --mochaOpts.grep "alerts and notices"
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    # Build quibble_args like the script does
    if [ ${#extra_args[@]} -gt 0 ]; then
      if [ -n "$component" ]; then
        quibble_args=(--command "cd ${component} && npm run selenium-test -- ${extra_args[*]}")
      else
        quibble_args=(--command "npm run selenium-test -- ${extra_args[*]}")
      fi
    else
      quibble_args=(--run selenium)
    fi
    echo "${quibble_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"cd extensions/Echo && npm run selenium-test"* ]]
  [[ "$output" == *"--spec tests/selenium/specs/notifications.js"* ]]
  [[ "$output" == *"alerts and notices"* ]]
}

@test "run_selenium_tests: no args uses --run selenium" {
  run bash -c '
    set -euo pipefail
    set --
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    if [ ${#extra_args[@]} -gt 0 ]; then
      quibble_args=(--command "npm run selenium-test -- ${extra_args[*]}")
    else
      quibble_args=(--run selenium)
    fi
    echo "${quibble_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--run selenium"* ]]
}

@test "run_selenium_tests: --spec without component runs from repo root" {
  run bash -c '
    set -euo pipefail
    set -- --spec tests/selenium/specs/page.js
    . '"$BATS_TEST_DIRNAME"'/../lib/parse_component_args
    if [ ${#extra_args[@]} -gt 0 ]; then
      if [ -n "$component" ]; then
        quibble_args=(--command "cd ${component} && npm run selenium-test -- ${extra_args[*]}")
      else
        quibble_args=(--command "npm run selenium-test -- ${extra_args[*]}")
      fi
    else
      quibble_args=(--run selenium)
    fi
    echo "${quibble_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run selenium-test -- --spec tests/selenium/specs/page.js"* ]]
  [[ "$output" != *"cd "* ]]
}
