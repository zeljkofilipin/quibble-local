#!/usr/bin/env bats
#
# Tests for generate_examples script.
# Driven via PREVIEW=1 against the real examples/ directory so we don't run dozens of commands.
# _QUIBBLE_NO_INHIBIT=1 skips lib/inhibit_sleep so no background sleep helper is spawned during tests.

@test "generate_examples: PREVIEW lists what would be generated" {
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Should print one "Would generate ..." line per project-root script with a Usage block.
  [[ "$output" == *"Would generate examples/"* ]]
}

@test "generate_examples: PREVIEW runs every Usage line per script" {
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Both first and non-first Usage lines of help should appear.
  [[ "$output" == *"Would generate examples/help.txt from: ./help"* ]]
  [[ "$output" == *"Would generate examples/help-install.txt from: ./help install"* ]]
}

@test "generate_examples: PREVIEW skips itself and generate_example" {
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" != *"examples/generate_examples.txt"* ]]
  [[ "$output" != *"examples/generate_example.txt"* ]]
}

@test "generate_examples: PREVIEW skips shellto (interactive, can't be captured)" {
  # shellto drops the user into an interactive Docker bash shell. ./generate_example's
  # eval would block forever waiting for keyboard input, so generate_examples skips it.
  # See CLAUDE.md ("shellto is an exception").
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" != *"examples/shellto"* ]]
}

@test "generate_examples: prints a labeled summary line with counts and total runtime" {
  # The summary line gives the user a single anchor at end-of-run with totals and overall
  # runtime — without it, the trailing `(Xs)` from lib/duration_trap is visually identical
  # to the per-file `(Xs)` lines from ./generate_example and easy to lose in scrollback.
  # Goes to stderr in the script; bats' $output captures both streams, which is what we
  # want here. PREVIEW walks every Usage line without invoking ./generate_example, so the
  # generated count will be non-zero.
  # TIME_ELAPSED=1 enables the duration in the summary line (_quibble_format_duration is
  # gated off by default; this test specifically asserts the duration appears, so opt in).
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 TIME_ELAPSED=1 ./generate_examples
  [ "$status" -eq 0 ]
  # Match: "generate_examples: generated <N>, skipped <M>, took <duration>".
  # N must be > 0 (PREVIEW sees every Usage variant); M can be 0 or more. Duration always
  # ends in "s" (seconds component is always present per lib/format_duration).
  [[ "$output" =~ generate_examples:\ generated\ [1-9][0-9]*,\ skipped\ [0-9]+,\ took\ [^[:space:]]+s ]]
}

@test "generate_examples: warns and skips filename collisions" {
  # The same command appears in run_selenium_tests_all_gated's Usage block and
  # suggest_parallel's Usage block, producing the same derived filename.
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [[ "$output" == *"filename collision"* ]]
}

@test "generate_examples: Usage-line loop reads from FD 3, not stdin" {
  # Regression guard: the loop must use `read -r cmd <&3` with the herestring on FD 3
  # (`done 3<<< "$usage_block"`). If it used `<<< "$usage_block"` (stdin), any child
  # process that drains stdin — notably `docker run -i ...` — would swallow every
  # remaining Usage line and the loop would exit after generating only the first one.
  # See the comment block in generate_examples for the full explanation.
  run grep -E "read -r cmd <&3" generate_examples
  [ "$status" -eq 0 ]
  run grep -E "done 3<<< \"\\\$usage_block\"" generate_examples
  [ "$status" -eq 0 ]
}

@test "generate_examples: pins prep scripts first and destructive scripts last" {
  # Iteration order is critical: prep scripts (prepare, prepare_gated, fresh_install, save)
  # must run before everything else so cache/, log/, src/, ref/, and the Docker image exist.
  # Destructive scripts (remove_srcs, remove, remove_all) must run last so they don't wipe
  # state needed by later scripts. The rest stays alphabetical.
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]

  # First-line index (1-based) of the first output line matching a pattern; empty if none.
  pos() {
    echo "$output" | awk -v p="$1" '$0 ~ p { print NR; exit }'
  }

  # Early-block: pinned order = prepare → prepare_gated → fresh_install → save.
  # Match the default Usage filename (the *.txt root, no flag/env suffix) so each anchor is unique.
  p_prepare=$(pos "Would generate examples/prepare\\.txt ")
  p_prepare_gated=$(pos "Would generate examples/prepare_gated\\.txt ")
  p_fresh_install=$(pos "Would generate examples/fresh_install\\.txt ")
  p_save=$(pos "Would generate examples/save\\.txt ")
  [ -n "$p_prepare" ]
  [ -n "$p_prepare_gated" ]
  [ -n "$p_fresh_install" ]
  [ -n "$p_save" ]
  [ "$p_prepare" -lt "$p_prepare_gated" ]
  [ "$p_prepare_gated" -lt "$p_fresh_install" ]
  [ "$p_fresh_install" -lt "$p_save" ]

  # Late-block: pinned order = remove_srcs → remove → remove_all (least → most destructive).
  p_remove_srcs=$(pos "Would generate examples/remove_srcs\\.txt ")
  p_remove=$(pos "Would generate examples/remove\\.txt ")
  p_remove_all=$(pos "Would generate examples/remove_all\\.txt ")
  [ -n "$p_remove_srcs" ]
  [ -n "$p_remove" ]
  [ -n "$p_remove_all" ]
  [ "$p_remove_srcs" -lt "$p_remove" ]
  [ "$p_remove" -lt "$p_remove_all" ]

  # Cross-block invariants: every early line strictly before every middle line; every middle
  # line strictly before every late line. Middle scripts include install*, restore*, run_*.
  last_early=$(echo "$output" | awk '/Would generate examples\/(prepare|fresh_install|save)/ { last = NR } END { print last+0 }')
  first_middle=$(echo "$output" | awk '/Would generate examples\/(install|restore|run_)/ { print NR; exit }')
  last_middle=$(echo "$output" | awk '/Would generate examples\/(install|restore|run_)/ { last = NR } END { print last+0 }')
  first_late=$(echo "$output" | awk '/Would generate examples\/remove/ { print NR; exit }')

  [ "$last_early" -gt 0 ]
  [ "$first_middle" -gt 0 ]
  [ "$last_middle" -gt 0 ]
  [ "$first_late" -gt 0 ]
  [ "$last_early" -lt "$first_middle" ]
  [ "$last_middle" -lt "$first_late" ]
}

@test "generate_examples: PARALLEL+PREVIEW forces serial (output identical to PREVIEW alone)" {
  # PREVIEW must take the serial path regardless of PARALLEL — parallel worker output would
  # interleave unhelpfully when previewing the work plan. The strongest assertion: the output
  # is byte-identical whether PARALLEL is unset, =1, =2, or =4.
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  serial_output="$output"
  run env PREVIEW=1 PARALLEL=4 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [ "$serial_output" = "$output" ]
}

@test "generate_examples: PREVIEW forces serial even at PARALLEL=1" {
  # PARALLEL=1 is now the smallest value that takes the parallel path (dispatch is -lt 1),
  # but PREVIEW must still force serial — companion to the PARALLEL=4 case above. Assert the
  # PREVIEW output is byte-identical with PARALLEL unset and with PARALLEL=1.
  run env PREVIEW=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  unset_output="$output"
  run env PREVIEW=1 PARALLEL=1 _QUIBBLE_NO_INHIBIT=1 ./generate_examples
  [ "$status" -eq 0 ]
  [ "$unset_output" = "$output" ]
}

@test "generate_examples: parallel path centralises ENVIRONMENT and QUIBBLE_BACKGROUND" {
  # Regression guard: the per-worker subshell must export ENVIRONMENT=N (so lib/setup
  # derives QUIBBLE_SRC=src_N) and QUIBBLE_BACKGROUND=1 (so lib/setup drops Docker -i/-t
  # flags). Without these, workers would race on the canonical src/ and Docker would
  # block waiting for stdin from a non-existent terminal.
  run grep -E 'export ENVIRONMENT=' generate_examples
  [ "$status" -eq 0 ]
  run grep -E 'export QUIBBLE_BACKGROUND=1' generate_examples
  [ "$status" -eq 0 ]
}

@test "generate_examples: parallel path seeds src_N from shared src_save via ./restore" {
  # Regression guard: each worker must seed its isolated src_N once before running its
  # Usage lines. The cheapest correct path is `QUIBBLE_SAVE=src_save ./restore` (concurrent
  # reads from the shared src_save are safe; restore writes to src_N derived from
  # ENVIRONMENT=N). Without seeding, scripts that read from src/ would find an empty tree.
  run grep -E 'QUIBBLE_SAVE=src_save ./restore' generate_examples
  [ "$status" -eq 0 ]
}

@test "generate_examples: parallel path pre-walks centrally to avoid worker collision races" {
  # Regression guard: the `seen` filename-collision tracker is a string mutated in the
  # main process. If workers tracked collisions independently, two scripts producing the
  # same examples/*.txt filename would both succeed and one would overwrite the other.
  # The fix is a centralised pre-walk (`_prewalk_script`) that populates `seen` and
  # writes pre-filtered per-script work files before any worker spawns.
  run grep -E '^_prewalk_script\(\)' generate_examples
  [ "$status" -eq 0 ]
  run grep -E '^_execute_work_file\(\)' generate_examples
  [ "$status" -eq 0 ]
}

@test "generate_examples: FD 3 loop pattern survives a child draining stdin" {
  # Demonstrate the underlying fix in isolation: a loop reading from FD 3 keeps
  # iterating even when the body spawns a child that drains stdin (cat > /dev/null
  # simulates docker -i). The same loop with the herestring on stdin would print
  # only "got: line1" and then exit.
  # The loop's stdin is provided by a separate herestring so `cat` has something
  # finite to drain — otherwise, when bats runs in an interactive terminal, `cat`
  # would block waiting for the user to type and ^D. The fix being demonstrated
  # is that the loop reads from FD 3, so what's on stdin doesn't matter.
  result=$(while IFS= read -r line <&3; do
    echo "got: $line"
    cat >/dev/null    # drain stdin — simulates docker run -i
  done 3<<< 'line1
line2
line3' <<< 'stdin content for cat to drain')
  [[ "$result" == *"got: line1"* ]]
  [[ "$result" == *"got: line2"* ]]
  [[ "$result" == *"got: line3"* ]]
}
