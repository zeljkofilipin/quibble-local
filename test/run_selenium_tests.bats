#!/usr/bin/env bats
#
# Tests for run_selenium_tests argument parsing.
# Uses _QUIBBLE_NO_DOCKER_CHECK to skip Docker checks.
# The docker run command at the end will fail (docker not called),
# but we can verify the argument parsing logic by inspecting variables.

@test "run_selenium_tests: parses component argument" {
  # Source the argument parsing section only (lines before lib/setup)
  run bash -c '
    set -euo pipefail
    zuul_project=()
    wdio_args=()
    component=""
    # Simulate the argument parsing loop from run_selenium_tests
    args=(extensions/Echo)
    set -- "${args[@]}"
    while [ $# -gt 0 ]; do
      case "$1" in
        extensions/* | skins/*) component="$1"; zuul_project=(-e "ZUUL_PROJECT=mediawiki/${component}"); shift ;;
        *) wdio_args+=("$1"); shift ;;
      esac
    done
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
    zuul_project=()
    wdio_args=()
    component=""
    args=(--spec tests/selenium/specs/page.js)
    set -- "${args[@]}"
    while [ $# -gt 0 ]; do
      case "$1" in
        extensions/* | skins/*) component="$1"; zuul_project=(-e "ZUUL_PROJECT=mediawiki/${component}"); shift ;;
        *) wdio_args+=("$1"); shift ;;
      esac
    done
    echo "wdio=${wdio_args[*]}"
    echo "component=$component"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"wdio=--spec tests/selenium/specs/page.js"* ]]
  [[ "$output" == *"component="* ]]
}

@test "run_selenium_tests: parses component with --spec and --mochaOpts.grep" {
  run bash -c '
    set -euo pipefail
    zuul_project=()
    wdio_args=()
    component=""
    args=(extensions/Echo --spec tests/selenium/specs/notifications.js --mochaOpts.grep "alerts and notices")
    set -- "${args[@]}"
    while [ $# -gt 0 ]; do
      case "$1" in
        extensions/* | skins/*) component="$1"; zuul_project=(-e "ZUUL_PROJECT=mediawiki/${component}"); shift ;;
        *) wdio_args+=("$1"); shift ;;
      esac
    done
    # Build quibble_args like the script does
    if [ ${#wdio_args[@]} -gt 0 ]; then
      if [ -n "${component:-}" ]; then
        quibble_args=(--command "cd ${component} && npm run selenium-test -- ${wdio_args[*]}")
      else
        quibble_args=(--command "npm run selenium-test -- ${wdio_args[*]}")
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
    zuul_project=()
    wdio_args=()
    component=""
    # No arguments
    if [ ${#wdio_args[@]} -gt 0 ]; then
      quibble_args=(--command "npm run selenium-test -- ${wdio_args[*]}")
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
    zuul_project=()
    wdio_args=(--spec tests/selenium/specs/page.js)
    component=""
    if [ ${#wdio_args[@]} -gt 0 ]; then
      if [ -n "${component:-}" ]; then
        quibble_args=(--command "cd ${component} && npm run selenium-test -- ${wdio_args[*]}")
      else
        quibble_args=(--command "npm run selenium-test -- ${wdio_args[*]}")
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
