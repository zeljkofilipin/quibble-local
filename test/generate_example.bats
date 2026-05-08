#!/usr/bin/env bats
#
# Tests for generate_example script.

setup() {
  # Per-test temp file that bats cleans up automatically
  output_file="$BATS_TEST_TMPDIR/example.txt"
}

@test "generate_example: writes command header and output to file" {
  run ./generate_example "$output_file" './help'
  [ "$status" -eq 0 ]
  # First non-empty line of the file should be the "$ <cmd>" header
  run head -n 1 "$output_file"
  [[ "$output" == '$ ./help' ]]
}

@test "generate_example: captures command output in file" {
  run ./generate_example "$output_file" 'echo hello'
  [ "$status" -eq 0 ]
  grep -q "^hello$" "$output_file"
}

@test "generate_example: captures stderr in file" {
  run ./generate_example "$output_file" 'echo error 1>&2'
  [ "$status" -eq 0 ]
  grep -q "^error$" "$output_file"
}

@test "generate_example: continues even when command fails" {
  run ./generate_example "$output_file" 'false'
  [ "$status" -eq 0 ]
  # Header is still written even when the captured command exits non-zero
  grep -q '^\$ false$' "$output_file"
}

@test "generate_example: exits 1 with no arguments" {
  run ./generate_example
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "generate_example: exits 1 with one argument" {
  run ./generate_example one_arg
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "generate_example: exits 1 with three arguments" {
  run ./generate_example one two three
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
