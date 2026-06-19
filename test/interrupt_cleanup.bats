#!/usr/bin/env bats
#
# Tests that the dynamic worker pool (lib/run_pool) installs an INT/TERM cleanup trap, so a
# Ctrl-C / kill removes the run's sentinel temp dir instead of orphaning it. lib/parallel drives
# its ordered minimum-dependency search on lib/run_pool, so it inherits the same trap when sourced.
# Each lib runs on source, so we drive it with an empty work list (loop skipped) in an isolated
# dir and assert the trap is armed. End-to-end signal cleanup is covered by the PARALLEL
# integration tests; orchestration logic is in run_pool.bats.

setup() {
  # Isolate cwd: the libs are sourced via "$(dirname "$0")"/lib, and $0 is "bash" in the `bash -c`
  # below (dirname -> "."), so copy the libs into a throwaway lib/. run_pool sources lib/pluralize.
  mkdir -p "$BATS_TEST_TMPDIR/lib"
  cp lib/run_pool lib/pluralize "$BATS_TEST_TMPDIR/lib/"
}

@test "lib/parallel: delegates cleanup to lib/run_pool (trap armed when sourced)" {
  # lib/parallel runs its search on lib/run_pool, so the INT/TERM cleanup trap comes from run_pool.
  # Sourcing lib/parallel with an empty combo list (the pool loop is skipped) should still arm it.
  cp lib/parallel "$BATS_TEST_TMPDIR/lib/"
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    parallel=1; fast=""; total=0; combos=()   # empty work list -> pool loop is skipped
    . lib/parallel
    trap -p INT; trap -p TERM
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"_quibble_run_pool_cleanup"* ]]   # trap installed (via run_pool) for INT and TERM
}

@test "lib/run_pool: installs an INT/TERM cleanup trap" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    items=(); parallel=1                       # empty work list -> pool loop is skipped
    _run_pool_worker() { :; }
    . lib/run_pool
    trap -p INT; trap -p TERM
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"_quibble_run_pool_cleanup"* ]]   # trap installed for INT and TERM
}
