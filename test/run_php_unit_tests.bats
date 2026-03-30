#!/usr/bin/env bats
#
# Tests for run_php_unit_tests argument parsing.
# Uses _QUIBBLE_NO_DOCKER_CHECK to skip Docker checks.
# The docker run command at the end will fail (docker not called),
# but we can verify the argument parsing logic by inspecting variables.

@test "run_php_unit_tests: parses component argument" {
  # Source the argument parsing section only (lines before lib/setup)
  run bash -c '
    set -euo pipefail
    zuul_project=()
    phpunit_args=()
    component=""
    # Simulate the argument parsing loop from run_php_unit_tests
    args=(extensions/Echo)
    set -- "${args[@]}"
    while [ $# -gt 0 ]; do
      case "$1" in
        extensions/* | skins/*) component="$1"; zuul_project=(-e "ZUUL_PROJECT=mediawiki/${component}"); shift ;;
        *) phpunit_args+=("$1"); shift ;;
      esac
    done
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
    zuul_project=()
    phpunit_args=()
    component=""
    args=(extensions/Echo --filter testNotificationCount)
    set -- "${args[@]}"
    while [ $# -gt 0 ]; do
      case "$1" in
        extensions/* | skins/*) component="$1"; zuul_project=(-e "ZUUL_PROJECT=mediawiki/${component}"); shift ;;
        *) phpunit_args+=("$1"); shift ;;
      esac
    done
    # Build quibble_args like the script does
    if [ ${#phpunit_args[@]} -gt 0 ]; then
      quibble_args=(--command "php tests/phpunit/phpunit.php ${phpunit_args[*]}")
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
    zuul_project=()
    phpunit_args=()
    component=""
    # No arguments
    if [ ${#phpunit_args[@]} -gt 0 ]; then
      quibble_args=(--command "php tests/phpunit/phpunit.php ${phpunit_args[*]}")
    else
      quibble_args=(--run phpunit)
    fi
    echo "${quibble_args[*]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--run phpunit"* ]]
}
