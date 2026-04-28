#!/usr/bin/env bats
#
# Tests for lib/print_quibble_command.

@test "print_quibble_command: defines the print_quibble_command function" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    type print_quibble_command
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}

@test "print_quibble_command: brackets the command with a # banner" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    print_quibble_command docker run --rm fake-image:latest --command true
  '
  [ "$status" -eq 0 ]
  # Banner appears at top and bottom; expect it twice in the output.
  [ "$(echo "$output" | grep -c '^####################')" -eq 2 ]
}

@test "print_quibble_command: keeps -v flag together with its value on one line" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    print_quibble_command docker run -v /host/path:/container/path fake-image:latest
  '
  [ "$status" -eq 0 ]
  # The "-v X:Y" pair must appear together on a single line.
  [[ "$output" == *"-v /host/path:/container/path"* ]]
  # And not split across lines (no "-v" alone at the end of a line).
  ! echo "$output" | grep -E '^\s*-v *$' >/dev/null
}

@test "print_quibble_command: --command and its value stay on one line" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    print_quibble_command docker run fake-image:latest --command true
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--command true"* ]]
}

@test "print_quibble_command: image (positional after flags) is on its own line" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    print_quibble_command docker run -v /a:/b fake-image:latest --command true
  '
  [ "$status" -eq 0 ]
  # Image should be on a line by itself (with leading indent), not appended to "-v /a:/b".
  echo "$output" | grep -E '^[[:space:]]*fake-image:latest \\$' >/dev/null
}

@test "print_quibble_command: continuation backslashes on all but last command line" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    print_quibble_command docker run -v /a:/b fake-image:latest --command true
  '
  [ "$status" -eq 0 ]
  # The last command line ("--command true") must not end with a backslash.
  echo "$output" | grep -E '^[[:space:]]*--command true$' >/dev/null
}

@test "print_quibble_command: --key=value flag stays as one element" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/print_quibble_command
    print_quibble_command docker run --entrypoint=quibble-with-supervisord fake-image:latest
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--entrypoint=quibble-with-supervisord"* ]]
}
