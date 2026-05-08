#!/usr/bin/env bats
#
# Tests for generate_examples script.
# Driven via DRY_RUN=1 against the real examples/ directory so we don't run dozens of commands.

@test "generate_examples: DRY_RUN lists what would be generated" {
  run env DRY_RUN=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Should print one "Would generate ..." line per project-root script with a Usage block.
  [[ "$output" == *"Would generate examples/"* ]]
}

@test "generate_examples: DRY_RUN runs every Usage line per script" {
  run env DRY_RUN=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Both first and non-first Usage lines of help should appear.
  [[ "$output" == *"Would generate examples/help.txt from: ./help"* ]]
  [[ "$output" == *"Would generate examples/help-install.txt from: ./help install"* ]]
}

@test "generate_examples: DRY_RUN skips itself and generate_example" {
  run env DRY_RUN=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" != *"examples/generate_examples.txt"* ]]
  [[ "$output" != *"examples/generate_example.txt"* ]]
}

@test "generate_examples: warns and skips filename collisions" {
  # The same command appears in run_selenium_tests_all_gated's Usage block and
  # suggest_parallel's Usage block, producing the same derived filename.
  run env DRY_RUN=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" == *"filename collision"* ]]
}
