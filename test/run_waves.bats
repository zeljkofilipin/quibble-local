#!/usr/bin/env bats
#
# Tests for lib/run_waves — the bounded-concurrency wave runner (fetch / prepare / prepare_gated
# use it to run git clone/fetch jobs N at a time). These exercise the control flow (every item
# runs once, concurrency is bounded by $parallel and reaches it, a failed job warns but does not
# abort, items containing spaces stay one job, empty list is a no-op) with mock workers, so they
# need no Docker or network. Concurrency is measured by having each worker mark itself "live"
# under a unique-per-item path while it sleeps, then sampling how many are live at once.

setup() {
  # lib/run_waves is self-contained (sources nothing), but copy it into a throwaway lib/ so the
  # `. lib/run_waves` below resolves from the test's working directory. Bats runs from repo root.
  mkdir -p "$BATS_TEST_TMPDIR/lib"
  cp lib/run_waves "$BATS_TEST_TMPDIR/lib/"
}

@test "lib/run_waves: processes every item exactly once" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=(i0 i1 i2 i3 i4 i5); parallel=2
    _run_waves_job() { echo "$1" >> processed; }   # ITEM=$1
    . lib/run_waves
    echo "COUNT=$(grep -c . processed)"
    echo "UNIQ=$(sort -u processed | grep -c .)"
    echo "ITEMS=$(sort processed | tr "\n" " ")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"COUNT=6"* ]]                       # all six ran
  [[ "$output" == *"UNIQ=6"* ]]                        # none ran twice
  [[ "$output" == *"ITEMS=i0 i1 i2 i3 i4 i5 "* ]]
}

@test "lib/run_waves: never exceeds parallel concurrent jobs and reaches it" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    mkdir -p live; : > maxlog; : > processed
    items=(i0 i1 i2 i3 i4 i5 i6 i7 i8); parallel=3
    _run_waves_job() {
      : > "live/$1"                          # mark THIS item running (unique per job)
      ls live | wc -l | tr -d " " >> maxlog  # sample concurrency while held
      sleep 0.2                              # hold so jobs in a wave overlap
      rm -f "live/$1"                        # release
      echo "$1" >> processed
    }
    . lib/run_waves
    echo "MAX=$(sort -n maxlog | tail -1)"
    echo "COUNT=$(grep -c . processed)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAX=3"* ]]                          # reached the cap (real parallelism), never above
  [[ "$output" == *"COUNT=9"* ]]
}

@test "lib/run_waves: parallel=1 runs strictly serially" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    mkdir -p live; : > maxlog
    items=(i0 i1 i2); parallel=1
    _run_waves_job() {
      : > "live/$1"
      ls live | wc -l | tr -d " " >> maxlog
      sleep 0.2
      rm -f "live/$1"
    }
    . lib/run_waves
    echo "MAX=$(sort -n maxlog | tail -1)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAX=1"* ]]                          # never two at once
}

@test "lib/run_waves: failing jobs warn and are counted in _rw_failures, but do not abort" {
  run bash -c '
    exec 2>&1                                           # capture the stderr warnings too
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=(i0 i1 i2 i3); parallel=1
    _run_waves_job() { echo "$1" >> processed; case "$1" in i1|i3) return 1;; esac; return 0; }
    . lib/run_waves
    echo "COUNT=$(grep -c . processed)"
    echo "FAILURES=$_rw_failures"
  '
  [ "$status" -eq 0 ]                                   # failing jobs must not abort the run
  [[ "$output" == *"COUNT=4"* ]]                        # all four still processed
  [[ "$output" == *"Warning: failed: i1"* ]]            # each failure reported by item label
  [[ "$output" == *"Warning: failed: i3"* ]]
  [[ "$output" == *"FAILURES=2"* ]]                     # and counted in _rw_failures
}

@test "lib/run_waves: an item containing spaces is passed to the worker as one job" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=("a b" "c d"); parallel=2
    _run_waves_job() { echo "$1" >> processed; }   # must receive the whole spec, not split words
    . lib/run_waves
    echo "LINES=$(grep -c . processed)"
    sort processed | tr "\n" "|"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"LINES=2"* ]]                        # two jobs, not four words
  [[ "$output" == *"a b|c d|"* ]]                       # each spec arrived intact
}

@test "lib/run_waves: empty items[] is a no-op under set -euo pipefail" {
  run bash -c '
    set -euo pipefail                                   # how fetch / prepare actually source it
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=(); parallel=2
    _run_waves_job() { echo "$1" >> processed; }
    . lib/run_waves
    echo "COUNT=$(grep -c . processed || true)"
  '
  [ "$status" -eq 0 ]                                   # no unbound-variable error on the empty array
  [[ "$output" == *"COUNT=0"* ]]
}
