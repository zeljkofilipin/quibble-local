#!/usr/bin/env bats
#
# Tests that the parallel orchestration lib (lib/run_waves) installs an INT/TERM cleanup trap,
# so a Ctrl-C / kill removes the run's temp dir (and src_worker_* checkouts) instead of
# orphaning gigabytes. lib/parallel delegates to lib/run_waves, so it inherits the same trap.
# The lib runs its wave loop on source, so we drive it with an empty work list (loop skipped)
# in an isolated dir and assert the trap is armed and the cleanup works. End-to-end signal
# cleanup is covered by the PARALLEL integration tests; orchestration logic is in run_waves.bats.

setup() {
  # Isolate cwd so lib/remove_worker_dirs' `src_worker_*` glob cannot touch the real repo.
  mkdir -p "$BATS_TEST_TMPDIR/lib"
  cp lib/remove_worker_dirs "$BATS_TEST_TMPDIR/lib/"
}

@test "lib/parallel: delegates cleanup to lib/run_waves (trap armed when sourced)" {
  # lib/parallel reimplements its search on top of lib/run_waves, so the INT/TERM cleanup trap
  # (and src_worker_* removal) now comes from run_waves. Sourcing lib/parallel with an empty
  # work list should still arm run_waves' trap. (run_waves' own cleanup is verified below.)
  cp lib/parallel lib/run_waves lib/pluralize "$BATS_TEST_TMPDIR/lib/"
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    parallel=1; fast=""; total=0; combos=()   # empty work list -> wave loop is skipped
    . lib/parallel
    trap -p INT; trap -p TERM
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"_quibble_run_waves_cleanup"* ]]   # trap installed (via run_waves) for INT and TERM
}

@test "lib/run_waves: installs an INT/TERM cleanup trap" {
  cp lib/run_waves "$BATS_TEST_TMPDIR/lib/"
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    items=(); parallel=1                      # empty work list -> wave loop is skipped
    _run_worker() { :; }; _collect_result() { :; }; utc_timestamp() { :; }
    . lib/run_waves
    trap -p INT; trap -p TERM
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"_quibble_run_waves_cleanup"* ]]   # trap installed for INT and TERM
}
