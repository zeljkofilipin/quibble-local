#!/usr/bin/env bash
# Host-side init for the quibble-local devcontainer. Runs on the host (NOT
# inside the container) before each container start, per devcontainer.json's
# `initializeCommand`. Works on macOS and Linux hosts.
#
# Responsibilities:
#   - Ensure the bind-mount source directory exists.
#   - Seed user-scope settings.json with bypassPermissions if missing.
#   - Capture the host's timezone so the container's status line can show
#     local time. The container is always UTC and has no way to query the
#     host directly, so detection has to happen here.

# -e: exit on error; -u: error on unset vars; pipefail: a pipeline fails if any stage fails.
set -euo pipefail

# Bind-mount source on the host. Must match `mounts` in devcontainer.json.
dir="${HOME}/.claude-devcontainers/quibble-local"
mkdir -p "$dir"

# Seed settings.json only if missing so manual edits on either machine are preserved.
if [ ! -f "$dir/settings.json" ]; then
  echo '{"permissions":{"defaultMode":"bypassPermissions"}}' > "$dir/settings.json"
fi

# Detect host timezone. `/etc/localtime` is a symlink to a tzdata file on both
# macOS (-> /var/db/timezone/zoneinfo/<TZ>) and modern Linux (-> /usr/share/zoneinfo/<TZ>).
# Strip everything up to and including "/zoneinfo/" to get the IANA TZ name (e.g. "Europe/Zagreb").
tz="$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')"

# Fallback for Linux distros that store the IANA name in /etc/timezone instead of (or in addition to) the symlink.
if [ -z "$tz" ] && [ -f /etc/timezone ]; then
  tz="$(cat /etc/timezone)"
fi

# Final fallback so the container always has *some* value (avoids empty TZ).
[ -z "$tz" ] && tz=UTC

# Write the detected TZ where the container can read it. The bind-mount surfaces
# this file at /home/vscode/.claude/host_tz inside the container; statusline.sh reads it.
echo "$tz" > "$dir/host_tz"
