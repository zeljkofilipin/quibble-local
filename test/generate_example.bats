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

@test "generate_example: captures output directly to file, not through a streaming pipe" {
  # Regression guard: piping the captured eval output through `awk | >> "$file"` makes any
  # libc-using child in the captured pipeline switch from block-buffered to fully-buffered
  # stdout (writer sees "stdout is a pipe", not a regular file), which stalls `tail -f` on
  # the destination file. Direct redirection preserves the streaming UX; path scrubbing
  # runs as a separate post-processing step after the capture is complete.
  run grep -E "eval \"\\\$cmd\"\\) >> \"\\\$file\" 2>&1" generate_example
  [ "$status" -eq 0 ]
  # And the awk scrub must run as a SECOND pass on the finished file (not a pipe in the
  # eval line), reading the file as an argument rather than from stdin.
  run grep -E "awk -v pwd=\"\\\$PWD\" -f lib/scrub_pwd.awk \"\\\$file\"" generate_example
  [ "$status" -eq 0 ]
}

@test "generate_example: scrubs project absolute path to \$PWD placeholder in captured output" {
  # generate_example pipes captured stdout+stderr through lib/scrub_pwd.awk so docker -v
  # mount lines (and any other absolute path) become "$PWD/..." in examples/*.txt. This
  # keeps regenerated files machine-independent. See plan §6.
  # The cmd string uses single quotes here so the $PWD inside it reaches generate_example
  # un-expanded — the expansion happens inside generate_example's `eval` (after it cd's
  # to its own directory), then scrub_pwd.awk substitutes the expanded path back to "$PWD".
  run ./generate_example "$output_file" 'echo "  -v $PWD/cache:/cache"'
  [ "$status" -eq 0 ]
  # The scrubbed body line should contain the literal "$PWD" placeholder.
  grep -qF '  -v $PWD/cache:/cache' "$output_file"
  # And the absolute path of this test's $PWD should not appear anywhere in the file
  # (would only appear if scrubbing failed). -F = fixed string match.
  ! grep -qF "$PWD/cache:/cache" "$output_file"
}
