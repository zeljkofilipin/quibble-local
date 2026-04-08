#!/usr/bin/env bats
#
# Tests for lib/inhibit_sleep.

@test "inhibit_sleep: skips when _QUIBBLE_NO_INHIBIT is set" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    . lib/inhibit_sleep
    echo "ok"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "inhibit_sleep: no background processes when skipped" {
  run bash -c '
    export _QUIBBLE_NO_INHIBIT=1
    . lib/inhibit_sleep
    # jobs -p lists background process PIDs; should be empty
    jobs -p
  '
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Regression test for the leak where the EXIT trap killed the inhibit helper
# (gnome-session-inhibit / systemd-inhibit) but not its `sleep infinity` child,
# which got reparented to systemd --user and lingered forever.
# Skipped on macOS (where caffeinate -w $$ self-cleans, no child to leak).
@test "inhibit_sleep: leaves no descendant processes after script exits" {
  if [ "$(uname)" = "Darwin" ]; then
    skip "macOS uses caffeinate -w which self-cleans; this leak only affects Linux"
  fi
  # Source lib/inhibit_sleep, wait until the helper is fully running (has forked
  # its sleep child), then exit. Without the wait, the script can exit before
  # setsid has run in the forked helper, leaving the EXIT trap with nothing to
  # kill — and the leak we're testing for would still happen.
  log=$(mktemp)
  bash -c '
    . lib/inhibit_sleep
    # Wait up to ~1s for the helper to fork its sleep child. Once the helper
    # has a child, we know setsid has run and the process group is established.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      if pgrep -P "$inhibit_sleep_pid" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
    echo "$inhibit_sleep_pid"
  ' > "$log"
  helper_pid=$(cat "$log")
  rm -f "$log"
  # Give the EXIT trap a moment to fire and the kill to take effect
  sleep 0.2
  # The helper itself must be gone
  ! kill -0 "$helper_pid" 2>/dev/null
  # And nothing in the helper's process group must survive (no orphaned sleep)
  [ -z "$(pgrep -g "$helper_pid" 2>/dev/null)" ]
}
