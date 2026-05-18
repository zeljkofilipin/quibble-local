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

@test "batch_setup: deletes log/silent/*.log at outermost invocation (silent mode)" {
  # Sandbox: a temp project root with a pre-existing log/silent/stale.log. After
  # sourcing batch_setup the file should be gone — this is the cleanup that
  # keeps results from prior runs out of the next run's logs.
  local tmpdir
  tmpdir="$(mktemp -d)"
  ln -s "$PWD/lib" "$tmpdir/lib"
  mkdir -p "$tmpdir/log/silent"
  : > "$tmpdir/log/silent/stale.log"

  run bash -c "
    cd '$tmpdir'
    export _QUIBBLE_NO_INHIBIT=1
    unset VERBOSE
    unset _QUIBBLE_NESTED_BATCH
    . lib/batch_setup
    [ -f log/silent/stale.log ] && echo PRESENT || echo ABSENT
  "

  rm -rf "$tmpdir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"ABSENT"* ]]
}

@test "batch_setup: keeps log/silent/*.log when _QUIBBLE_NESTED_BATCH=1" {
  # Regression: when an outer batch script (find_dependencies_minimal_gated) invokes an
  # inner batch script (find_dependencies_minimal_greedy) via run_step, the outer's tee
  # is writing to log/silent/<component>--find_dependencies_minimal_greedy.log when the
  # inner's batch_setup runs. If batch_setup wiped *.log here it would unlink that file
  # mid-write and the outer would have nothing to read for the FOUND-block extraction.
  # _QUIBBLE_NESTED_BATCH=1 tells inner invocations to skip the cleanup.
  local tmpdir
  tmpdir="$(mktemp -d)"
  ln -s "$PWD/lib" "$tmpdir/lib"
  mkdir -p "$tmpdir/log/silent"
  : > "$tmpdir/log/silent/outer.log"

  run bash -c "
    cd '$tmpdir'
    export _QUIBBLE_NO_INHIBIT=1
    export _QUIBBLE_NESTED_BATCH=1
    unset VERBOSE
    . lib/batch_setup
    [ -f log/silent/outer.log ] && echo PRESENT || echo ABSENT
  "

  rm -rf "$tmpdir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"PRESENT"* ]]
}
