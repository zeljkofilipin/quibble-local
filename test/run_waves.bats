#!/usr/bin/env bats
#
# Orchestration tests for lib/run_waves — the generic wave-based parallel worker loop.
# These exercise the control flow (early-exit, the _worker_label hook) with mock workers,
# so they need no Docker. The real worker bodies (install / Selenium / greedy) are covered
# by the PARALLEL integration tests; cleanup-trap behavior is in interrupt_cleanup.bats.

setup() {
  # Isolate cwd: run_waves does `mkdir src_worker_N` and its cleanup globs `src_worker_*`,
  # so keep all of that inside the throwaway test dir, never the real repo.
  # remove_worker_dirs sources lib/default_image, so copy that in too.
  mkdir -p "$BATS_TEST_TMPDIR/lib"
  cp lib/run_waves lib/pluralize lib/remove_worker_dirs lib/default_image "$BATS_TEST_TMPDIR/lib/"
}

@test "lib/run_waves: a collector setting _quibble_run_waves_stop halts further waves" {
  # items i0..i4 in waves of 2 -> waves (i0,i1) (i2,i3) (i4). i2 is the first pass; the
  # collector records it and signals stop. Expect: collection stops at i2 (so i3, already
  # launched in the same wave, is not collected) and wave 3 (i4) never launches at all.
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    utc_timestamp() { :; }                       # stub: run_waves stamps the wave header
    items=(i0 i1 i2 i3 i4); parallel=2
    : > collected                                # collection log (main shell, sequential)
    _run_worker() { if [ "$2" = i2 ]; then echo pass; else echo fail; fi > "$1"; }
    _collect_result() {
      echo "$1" >> collected
      [ "$2" = pass ] && { winner="$1"; _quibble_run_waves_stop=1; }
    }
    . lib/run_waves
    echo "WINNER=$winner"
    echo "COLLECTED=$(tr "\n" " " < collected)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"WINNER=i2"* ]]
  [[ "$output" == *"COLLECTED=i0 i1 i2 "* ]]   # collection stopped at the first pass
  [[ "$output" != *"i4"* ]]                    # wave 3 (i4) never launched -> run halted early
}

@test "lib/run_waves: uses the _worker_label hook when the caller defines one" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    utc_timestamp() { :; }
    items=(alpha); parallel=1
    _run_worker() { echo fail > "$1"; }
    _collect_result() { :; }
    _worker_label() { printf "LABELED w=%s i=%s idx=%s\n" "$1" "$2" "$3"; }
    . lib/run_waves
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"LABELED w=1 i=alpha idx=0"* ]]   # hook gets worker_num, item, item_idx
}

@test "lib/run_waves: default worker label when no hook is defined" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    utc_timestamp() { :; }
    items=(alpha); parallel=1
    _run_worker() { echo fail > "$1"; }
    _collect_result() { :; }
    . lib/run_waves
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Worker 1: alpha"* ]]
}
