#!/usr/bin/env bats
#
# Tests for lib/cmd_to_filename.

setup() {
  # shellcheck disable=SC1091
  . ./lib/cmd_to_filename
}

@test "cmd_to_filename: no args" {
  [ "$(cmd_to_filename './help')" = "examples/help.txt" ]
}

@test "cmd_to_filename: positional arg" {
  [ "$(cmd_to_filename './help install')" = "examples/help-install.txt" ]
}

@test "cmd_to_filename: positional arg with slash" {
  [ "$(cmd_to_filename './install extensions/Echo')" = "examples/install-extensions_echo.txt" ]
}

@test "cmd_to_filename: positional arg with dots and slashes" {
  [ "$(cmd_to_filename './fetch ref/mediawiki/core.git')" = "examples/fetch-ref_mediawiki_core_git.txt" ]
}

@test "cmd_to_filename: env var with non-empty value" {
  result=$(cmd_to_filename 'QUIBBLE_DEPS="EventLogging" ./install extensions/Echo')
  [ "$result" = "examples/install-extensions_echo-quibble_deps_eventlogging.txt" ]
}

@test "cmd_to_filename: env var with empty value" {
  result=$(cmd_to_filename 'QUIBBLE_DEPS="" ./install extensions/Echo')
  [ "$result" = "examples/install-extensions_echo-quibble_deps.txt" ]
}

@test "cmd_to_filename: --flag drops value" {
  result=$(cmd_to_filename './run_php_unit_tests --filter testValidSpecialPageAliases')
  [ "$result" = "examples/run_php_unit_tests-filter.txt" ]
}

@test "cmd_to_filename: --spec with long path drops value" {
  result=$(cmd_to_filename './run_selenium_tests --spec tests/selenium/wdio-mediawiki/specs/BlankPage.js')
  [ "$result" = "examples/run_selenium_tests-spec.txt" ]
}

@test "cmd_to_filename: command substitution in env var preserved as literal" {
  # eval would expand $(./suggest_parallel); read -ra preserves it as a literal token.
  result=$(cmd_to_filename 'PARALLEL=$(./suggest_parallel) ./run_selenium_tests_all_gated')
  # The exact output is awkward but the test is that we don't execute the substitution.
  [[ "$result" == examples/run_selenium_tests_all_gated-parallel_* ]]
}
