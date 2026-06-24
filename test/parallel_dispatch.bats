#!/usr/bin/env bats
#
# Regression guard for the PARALLEL=1 dispatch fix (T427615): PARALLEL=1 must run as a
# 1-worker parallel run (its own isolated src dir), NOT serially in the shared src/.
# The old convention (`parallel="${PARALLEL:-1}"` + `if [ "$parallel" -le 1 ]`) made both
# PARALLEL=1 and unset serial. The fix defaults to 0 and dispatches on `-lt 1`, so only
# unset/0 is serial and PARALLEL>=1 takes the parallel path.
#
# Auto-discovers every project-root script that sets a PARALLEL default (so a new parallel
# script is covered automatically) and asserts the new forms are present and the old ones
# are gone. Pure grep over sources — no Docker, fast. Bats runs from the repo root.

@test "PARALLEL scripts: default 0 and dispatch on -lt 1 (PARALLEL=1 runs parallel, not serial)" {
  count=0 # number of PARALLEL-dispatching scripts discovered
  # `for f in *` globs the repo root only (not the gigabyte runtime dirs); bats runs from root.
  for f in *; do
    [ -f "$f" ] || continue                              # skip directories
    head -n 1 "$f" | grep -qE '^#!' || continue          # project scripts only (skip .md, data files)
    grep -qE 'parallel="\$\{PARALLEL:-' "$f" || continue # only scripts that set a PARALLEL default
    count=$((count + 1))

    # New default is 0 (unset/0 = sequential); the old default of 1 must be gone.
    # `run` + status check (not `! grep`) because bats uses set -e, which ignores `!`-inverted failures.
    run grep -qE 'parallel="\$\{PARALLEL:-0\}"' "$f"
    [ "$status" -eq 0 ]
    run grep -qE 'parallel="\$\{PARALLEL:-1\}"' "$f"
    [ "$status" -ne 0 ]

    # New dispatch branches on -lt 1; the old -le 1 form (which caught PARALLEL=1) must be gone.
    run grep -qE '\[ "\$parallel" -lt 1 \]' "$f"
    [ "$status" -eq 0 ]
    run grep -qE '\[ "\$parallel" -le 1 \]' "$f"
    [ "$status" -ne 0 ]
  done

  # All 10 known PARALLEL scripts: fetch, prepare, prepare_gated, install_each_gated, the 3
  # find_dependencies_minimal_* (bottom_up, thorough, gated), the 2 run_selenium_tests_*_gated,
  # and generate_examples.
  [ "$count" -ge 10 ]
}
