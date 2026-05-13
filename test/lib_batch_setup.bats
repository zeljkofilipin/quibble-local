#!/usr/bin/env bats
#
# Tests for lib/batch_setup (run_step function).

setup() {
  export _QUIBBLE_NO_INHIBIT=1 # skip sleep inhibition in tests
  export VERBOSE=1 # use verbose mode to avoid log directory/silent output complexity
}

teardown() {
  unset _QUIBBLE_NO_INHIBIT
  unset VERBOSE
}

@test "run_step: records pass for successful command" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    run_step core true
    echo "passed:$passed"
  '
  [ "$status" -eq 0 ]
}

@test "run_step: records failure for failing command" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    run_step core false || true
    echo "failed:$failed"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"failed:"* ]]
  [[ "$output" == *"core"* ]]
}

@test "run_step: returns 0 on success" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    run_step mycomponent true
  '
  [ "$status" -eq 0 ]
}

@test "run_step: returns 1 on failure" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    run_step mycomponent false
  '
  [ "$status" -eq 1 ]
}

@test "run_step: prints component and command in verbose mode" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    run_step extensions/Echo echo hello
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"extensions/Echo"* ]]
  [[ "$output" == *"hello"* ]]
}

@test "run_step: prints UTC timestamp in verbose mode" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    run_step core true
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"UTC"* ]]
}

@test "batch_setup: initializes passed and failed as empty" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    export VERBOSE=1
    . lib/batch_setup
    echo "passed=[$passed] failed=[$failed]"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"passed=[] failed=[]"* ]]
}

@test "batch_setup: fails loudly when log/silent can't be created in silent mode" {
  # Sandbox: instead of faking root-ownership (which would require sudo), we make
  # `log` a regular file. Semantically different from the production bug (a
  # root-owned dir left over from Docker) but exercises the same failure path:
  # the chmod 777 fast-path is a no-op, `mkdir -p log/silent` fails with "Not a
  # directory", and `[ ! -d log/silent ]` is true — so batch_setup must print the
  # actionable error and exit 1 instead of limping along.
  local tmpdir
  tmpdir="$(mktemp -d)"
  ln -s "$PWD/lib" "$tmpdir/lib"
  : > "$tmpdir/log"   # create log as an empty file, blocking the directory below it

  run bash -c "
    cd '$tmpdir'
    export _QUIBBLE_NO_INHIBIT=1
    unset VERBOSE
    . lib/batch_setup
  "

  rm -rf "$tmpdir"

  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot create log/silent"* ]]
  [[ "$output" == *"./remove_all"* ]]
}
