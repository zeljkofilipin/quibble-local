#!/usr/bin/env bats
#
# Tests that the parallel orchestration libs install an INT/TERM cleanup trap, so a
# Ctrl-C / kill removes the run's temp dir (and src_worker_* checkouts) instead of
# orphaning gigabytes. The libs run their wave loop on source, so we drive them with an
# empty work list (loop skipped) in an isolated dir and assert the trap is armed and the
# cleanup works. End-to-end signal cleanup is covered by the PARALLEL integration tests.

setup() {
  # Isolate cwd so lib/remove_worker_dirs' `src_worker_*` glob cannot touch the real repo.
  mkdir -p "$BATS_TEST_TMPDIR/lib"
  cp lib/remove_worker_dirs "$BATS_TEST_TMPDIR/lib/"
}

@test "lib/parallel: installs an INT/TERM cleanup trap" {
  cp lib/parallel "$BATS_TEST_TMPDIR/lib/"
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    parallel=1; fast=""; total=0; combos=()   # empty work list -> wave loop is skipped
    . lib/parallel
    trap -p INT; trap -p TERM
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"_quibble_parallel_cleanup"* ]]   # trap installed for INT and TERM
}

@test "lib/parallel: cleanup removes the temp dir and src_worker_* dirs" {
  cp lib/parallel "$BATS_TEST_TMPDIR/lib/"
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    parallel=1; fast=""; total=0; combos=()
    . lib/parallel                            # defines _quibble_parallel_cleanup, sets result_dir
    mkdir -p src_worker_1 src_worker_2        # fake worker checkouts to be removed
    mkdir -p "$result_dir"                    # recreate the result dir (end-cleanup already removed it)
    _quibble_parallel_cleanup
    [ -d src_worker_1 ] && echo WORKER_LEFT
    [ -d src_worker_2 ] && echo WORKER_LEFT
    [ -d "$result_dir" ] && echo RESULTDIR_LEFT
    echo DONE
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"DONE"* ]]
  [[ "$output" != *"WORKER_LEFT"* ]]     # src_worker_* removed
  [[ "$output" != *"RESULTDIR_LEFT"* ]]  # temp dir removed
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
