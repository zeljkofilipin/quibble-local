#!/usr/bin/env bats
#
# Tests for selenium_tests_exist script.

setup() {
  TEST_DIR=$(mktemp -d) # create a temp directory to simulate src/
}

teardown() {
  rm -rf "$TEST_DIR" # clean up temp directory
}

@test "selenium_tests_exist: exits 0 when core has selenium-test script" {
  mkdir -p "$TEST_DIR/src"
  echo '{"scripts": {"selenium-test": "wdio"}}' > "$TEST_DIR/src/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 0 ]
}

@test "selenium_tests_exist: exits 1 when core has no selenium-test script" {
  mkdir -p "$TEST_DIR/src"
  echo '{"scripts": {"test": "jest"}}' > "$TEST_DIR/src/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 1 when core package.json missing" {
  mkdir -p "$TEST_DIR/src"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist"
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 0 for extension with selenium-test" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  echo '{"scripts": {"selenium-test": "wdio"}}' > "$TEST_DIR/src/extensions/Echo/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 0 ]
}

@test "selenium_tests_exist: exits 1 for extension without selenium-test" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  echo '{"scripts": {"test": "jest"}}' > "$TEST_DIR/src/extensions/Echo/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 1 for extension with no package.json" {
  mkdir -p "$TEST_DIR/src/extensions/Echo"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" extensions/Echo
  [ "$status" -eq 1 ]
}

@test "selenium_tests_exist: exits 0 for skin with selenium-test" {
  mkdir -p "$TEST_DIR/src/skins/MinervaNeue"
  echo '{"scripts": {"selenium-test": "wdio"}}' > "$TEST_DIR/src/skins/MinervaNeue/package.json"
  cd "$TEST_DIR"
  run "$BATS_TEST_DIRNAME/../selenium_tests_exist" skins/MinervaNeue
  [ "$status" -eq 0 ]
}
