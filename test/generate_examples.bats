#!/usr/bin/env bats
#
# Tests for generate_examples script.
# Driven via DRY_RUN=1 against the real examples/ directory so we don't run dozens of commands.
# _QUIBBLE_NO_INHIBIT=1 skips lib/inhibit_sleep so no background sleep helper is spawned during tests.

@test "generate_examples: DRY_RUN lists what would be generated" {
  run env DRY_RUN=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Should print one "Would generate ..." line per project-root script with a Usage block.
  [[ "$output" == *"Would generate examples/"* ]]
}

@test "generate_examples: DRY_RUN runs every Usage line per script" {
  run env DRY_RUN=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Both first and non-first Usage lines of help should appear.
  [[ "$output" == *"Would generate examples/help.txt from: ./help"* ]]
  [[ "$output" == *"Would generate examples/help-install.txt from: ./help install"* ]]
}

@test "generate_examples: DRY_RUN skips itself and generate_example" {
  run env DRY_RUN=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" != *"examples/generate_examples.txt"* ]]
  [[ "$output" != *"examples/generate_example.txt"* ]]
}

@test "generate_examples: warns and skips filename collisions" {
  # The same command appears in run_selenium_tests_all_gated's Usage block and
  # suggest_parallel's Usage block, producing the same derived filename.
  run env DRY_RUN=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" == *"filename collision"* ]]
}

@test "generate_examples: Usage-line loop reads from FD 3, not stdin" {
  # Regression guard: the loop must use `read -r cmd <&3` with the herestring on FD 3
  # (`done 3<<< "$usage_block"`). If it used `<<< "$usage_block"` (stdin), any child
  # process that drains stdin — notably `docker run -i ...` — would swallow every
  # remaining Usage line and the loop would exit after generating only the first one.
  # See the comment block in generate_examples for the full explanation.
  run grep -E "read -r cmd <&3" generate_examples
  [ "$status" -eq 0 ]
  run grep -E "done 3<<< \"\\\$usage_block\"" generate_examples
  [ "$status" -eq 0 ]
}

@test "generate_examples: FD 3 loop pattern survives a child draining stdin" {
  # Demonstrate the underlying fix in isolation: a loop reading from FD 3 keeps
  # iterating even when the body spawns a child that drains stdin (cat > /dev/null
  # simulates docker -i). The same loop with the herestring on stdin would print
  # only "got: line1" and then exit.
  # The loop's stdin is provided by a separate herestring so `cat` has something
  # finite to drain — otherwise, when bats runs in an interactive terminal, `cat`
  # would block waiting for the user to type and ^D. The fix being demonstrated
  # is that the loop reads from FD 3, so what's on stdin doesn't matter.
  result=$(while IFS= read -r line <&3; do
    echo "got: $line"
    cat >/dev/null    # drain stdin — simulates docker run -i
  done 3<<< 'line1
line2
line3' <<< 'stdin content for cat to drain')
  [[ "$result" == *"got: line1"* ]]
  [[ "$result" == *"got: line2"* ]]
  [[ "$result" == *"got: line3"* ]]
}
