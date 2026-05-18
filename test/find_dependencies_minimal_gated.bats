#!/usr/bin/env bats
#
# Tests for find_dependencies_minimal_gated script.

setup() {
  TEST_DIR=$(mktemp -d) # fake project root: contains symlinks to scripts/lib but no ref/
  local project_root="$BATS_TEST_DIRNAME/.." # real project root
  # Symlink the scripts and helpers the gated script invokes through CWD-relative paths
  # (e.g. ./selenium_tests_exist) and through $(dirname "$0") (lib/). Leaving ref/
  # unmirrored is what triggers the lib/ensure_config failure we want to exercise.
  ln -s "$project_root"/find_dependencies_minimal_gated "$TEST_DIR"/find_dependencies_minimal_gated
  ln -s "$project_root"/find_dependencies_minimal_greedy "$TEST_DIR"/find_dependencies_minimal_greedy
  ln -s "$project_root"/selenium_tests_exist "$TEST_DIR"/selenium_tests_exist
  ln -s "$project_root"/list_dependencies "$TEST_DIR"/list_dependencies
  ln -s "$project_root"/list_dependencies_optional "$TEST_DIR"/list_dependencies_optional
  ln -s "$project_root"/list_dependencies_required "$TEST_DIR"/list_dependencies_required
  ln -s "$project_root"/lib "$TEST_DIR"/lib
  # selenium_tests_exist reads src/extensions/<name>/package.json — fake one with a
  # "selenium-test" script so the filter doesn't short-circuit to "no Selenium tests".
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  cat > "$TEST_DIR/src/extensions/Echo/package.json" <<'JSON'
{ "scripts": { "selenium-test": "wdio" } }
JSON
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "find_dependencies_minimal_gated: exits non-zero when ref/integration/config.git is missing" {
  # Regression: the filter loop must propagate list_dependencies_optional failures so a
  # missing ref/integration/config.git (lib/ensure_config) causes the script to fail fast
  # instead of treating "0 optional deps" as "skip this component" and reporting
  # "All passed." at the end.
  # _QUIBBLE_NO_INHIBIT=1 skips lib/inhibit_sleep so no background processes leak.
  cd "$TEST_DIR"
  run env _QUIBBLE_NO_INHIBIT=1 ./find_dependencies_minimal_gated extensions/Echo
  [ "$status" -ne 0 ]
  # The ensure_config message lands on stderr (and `run` merges stderr into $output).
  [[ "$output" == *"Run ./prepare first"* ]]
  # And the filter loop's own propagation message names the failing operation.
  [[ "$output" == *"failed to list optional dependencies for extensions/Echo"* ]]
  # Negative: must NOT pretend everything passed.
  [[ "$output" != *"All passed"* ]]
}
