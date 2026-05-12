#!/usr/bin/env bash
# Claude Code status line: prints "[model] effort:LEVEL N% session (resets in H:MM at HH:MM)".
#
# Reads the status JSON from stdin (per Claude Code's statusLine contract) and
# emits a single line. Installed to ~/.claude/statusline.sh by
# .devcontainer/devcontainer.json on every container start, so the script stays
# in sync across machines via this checked-in copy.
#
# See: https://code.claude.com/docs/en/statusline

# -e: exit on error; -u: error on unset vars; pipefail: a pipeline fails if any stage fails.
set -euo pipefail

# The container's /etc/localtime is UTC, so jq's `localtime` would show UTC by
# default. .devcontainer/initialize.sh runs on the host and writes the host's
# IANA timezone (e.g. "Europe/Zagreb") to this file via the ~/.claude bind-mount;
# we read it and export $TZ so libc (and therefore jq) uses local time.
TZ_FILE=/home/vscode/.claude/host_tz
[ -f "$TZ_FILE" ] && export TZ="$(cat "$TZ_FILE")"

# Hand stdin to jq and replace this shell process (no extra fork). The jq script:
#   - secs_to_hm: turns a seconds count into "H:MM" (zero-pads minutes).
#   - reads model.display_name, effort.level, and rate_limits.five_hour fields.
#   - formats the reset clock time via `localtime | strftime` so it shows the
#     user's local time (jq's strftime is UTC; localtime applies $TZ first).
#   - omits the "(resets …)" suffix when rate_limits isn't in the payload yet
#     — happens on the very first status event of a session.
exec jq -r '
  def secs_to_hm(s):
    (if s <= 0 then 0 else (s / 60 | floor) end) as $m
    | (($m / 60) | floor) as $h
    | ($m - $h * 60) as $mm
    | "\($h):\(if $mm < 10 then "0\($mm)" else "\($mm)" end)";

  "[\(.model.display_name)] "
  + "effort:\(.effort.level // "?") "
  + "\(.rate_limits.five_hour.used_percentage // 0 | floor)% session"
  + ( if (.rate_limits.five_hour.resets_at // null) != null then
        (.rate_limits.five_hour.resets_at) as $r
        | (now | floor) as $n
        | " (resets in \(secs_to_hm($r - $n)) at \($r | localtime | strftime("%H:%M")))"
      else "" end )
'
