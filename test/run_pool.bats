#!/usr/bin/env bats
#
# Orchestration tests for lib/run_pool — the dynamic refill-as-you-go worker pool.
# These exercise the control flow (bounded concurrency, slot reuse, failure tolerance,
# the label hook) with mock workers, so they need no Docker. Concurrency is measured by
# having each worker mark itself "live" under a unique-per-item path while it sleeps, then
# sampling how many are live at once — a per-item marker (not per-slot) so premature slot
# reuse would show up as over-concurrency.

setup() {
  # Isolate cwd: lib/run_pool sources lib/pluralize via "$(dirname "$0")"/lib, and $0 is
  # "bash" in the `bash -c` below (dirname -> "."), so copy the libs into a throwaway lib/.
  mkdir -p "$BATS_TEST_TMPDIR/lib"
  cp lib/run_pool lib/pluralize "$BATS_TEST_TMPDIR/lib/"
}

@test "lib/run_pool: processes every item exactly once" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=(i0 i1 i2 i3 i4 i5); parallel=2
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { echo "$2" >> processed; }   # SLOT=$1, ITEM=$2
    . lib/run_pool
    echo "COUNT=$(grep -c . processed)"
    echo "UNIQ=$(sort -u processed | grep -c .)"
    echo "ITEMS=$(sort processed | tr "\n" " ")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"COUNT=6"* ]]                       # all six ran
  [[ "$output" == *"UNIQ=6"* ]]                        # none ran twice
  [[ "$output" == *"ITEMS=i0 i1 i2 i3 i4 i5 "* ]]
}

@test "lib/run_pool: never exceeds parallel concurrent workers and reaches it" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    mkdir -p live; : > maxlog; : > processed
    items=(i0 i1 i2 i3 i4 i5 i6 i7 i8); parallel=3
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() {
      : > "live/$2"                                    # mark THIS item running (unique per dispatch)
      ls live | wc -l | tr -d " " >> maxlog            # sample concurrency while held
      sleep 0.2                                        # hold the slot so workers overlap
      rm -f "live/$2"                                  # release
      echo "$2" >> processed
    }
    . lib/run_pool
    echo "MAX=$(sort -n maxlog | tail -1)"
    echo "COUNT=$(grep -c . processed)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAX=3"* ]]                          # reached the cap (real parallelism) and never above it
  [[ "$output" == *"COUNT=9"* ]]
}

@test "lib/run_pool: parallel=1 runs strictly serially (guards premature slot reuse)" {
  # With one slot, no two workers may overlap. A stale-sentinel bug (reusing a slot before
  # its worker truly finished) would dispatch the next item early -> two live at once.
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    mkdir -p live; : > maxlog
    items=(i0 i1 i2); parallel=1
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() {
      : > "live/$2"
      ls live | wc -l | tr -d " " >> maxlog
      sleep 0.2
      rm -f "live/$2"
    }
    . lib/run_pool
    echo "MAX=$(sort -n maxlog | tail -1)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAX=1"* ]]                          # never two at once -> slot not reused early
}

@test "lib/run_pool: reuses slots across more items than slots" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > slots
    items=(i0 i1 i2 i3 i4 i5); parallel=2
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { echo "$1" >> slots; sleep 0.05; }   # record the slot id used
    . lib/run_pool
    echo "DISTINCT=$(sort -u slots | tr -d "\n")"
    echo "DISPATCHES=$(grep -c . slots)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"DISTINCT=12"* ]]                    # only slots 1 and 2 ever used
  [[ "$output" == *"DISPATCHES=6"* ]]                   # but six items ran -> slots were reused
}

@test "lib/run_pool: a worker exiting non-zero does not abort the pool" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=(i0 i1 i2 i3); parallel=1
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { echo "$2" >> processed; [ "$2" = i1 ] && return 1; return 0; }
    . lib/run_pool
    echo "COUNT=$(grep -c . processed)"
    echo "HAS_LAST=$(grep -c "^i3$" processed)"
  '
  [ "$status" -eq 0 ]                                   # one failing worker must not abort the run
  [[ "$output" == *"COUNT=4"* ]]                        # all four still processed
  [[ "$output" == *"HAS_LAST=1"* ]]                     # the slot was reused after the failure
}

@test "lib/run_pool: default slot label when no hook is defined" {
  run bash -c '
    exec 2>&1                                           # run_pool prints progress to stderr
    cd "'"$BATS_TEST_TMPDIR"'"
    items=(alpha); parallel=1
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { :; }
    . lib/run_pool
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Slot 1: alpha"* ]]
}

@test "lib/run_pool: uses the _pool_worker_label hook when the caller defines one" {
  run bash -c '
    exec 2>&1
    cd "'"$BATS_TEST_TMPDIR"'"
    items=(alpha); parallel=1
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { :; }
    _pool_worker_label() { printf "LABELED s=%s i=%s\n" "$1" "$2"; }
    . lib/run_pool
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"LABELED s=1 i=alpha"* ]]            # hook gets slot id and item
}

@test "lib/run_pool: calls the _pool_reap hook once per item, with slot id and item, as each finishes" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > reaped
    items=(i0 i1 i2); parallel=1
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { :; }                                        # body irrelevant; we test the hook
    _pool_reap() { printf "REAP s=%s i=%s\n" "$1" "$2" >> reaped; }  # SLOT=$1, ITEM=$2
    . lib/run_pool
    echo "REAPS=$(grep -c . reaped)"
    sort reaped | tr "\n" " "
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"REAPS=3"* ]]                                     # fired once per item (not per slot)
  [[ "$output" == *"REAP s=1 i=i0 REAP s=1 i=i1 REAP s=1 i=i2"* ]]   # each call gets its slot id + item
}

@test "lib/run_pool: passes the 0-based items[] index as the 3rd arg to the worker and _pool_reap" {
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > idx
    items=(a b c); parallel=1
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { printf "worker %s=%s\n" "$2" "$3" >> idx; }  # ITEM=$2, INDEX=$3
    _pool_reap() { printf "reap %s=%s\n" "$2" "$3" >> idx; }          # ITEM=$2, INDEX=$3
    . lib/run_pool
    cat idx
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"worker a=0"* ]]   # index tracks the item: a=0, b=1, c=2
  [[ "$output" == *"worker c=2"* ]]
  [[ "$output" == *"reap b=1"* ]]
}

@test "lib/run_pool: a _pool_reap that sets _quibble_run_pool_stop halts dispatch but drains in-flight" {
  # Ordered-search early exit: once the caller signals stop, no NEW item is dispatched, but the
  # slots already in flight still run and get reaped. With 2 slots, only the first wave (i0,i1)
  # ever launches; i2.. are never dispatched.
  run bash -c '
    cd "'"$BATS_TEST_TMPDIR"'"
    : > processed
    items=(i0 i1 i2 i3 i4); parallel=2
    export _QUIBBLE_POOL_POLL_SECONDS=0.05
    _run_pool_worker() { echo "$2" >> processed; }   # record each item that actually launches
    _pool_reap() { _quibble_run_pool_stop=1; }        # stop the instant the first item finishes
    . lib/run_pool
    echo "COUNT=$(grep -c . processed)"
    echo "RAN=$(sort -u processed | tr "\n" " ")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"COUNT=2"* ]]      # only the 2 in-flight slots ran
  [[ "$output" == *"i0"* ]]
  [[ "$output" == *"i1"* ]]
  [[ "$output" != *"i2"* ]]           # nothing dispatched after the stop
}
