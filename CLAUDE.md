# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) (MediaWiki CI test runner) locally via Docker. Targets macOS and Ubuntu. Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart).

## Prerequisites

Bash, Git, and Docker. Optional: [ShellCheck](https://www.shellcheck.net/) (for linting).

## Lint and test

- **Lint:** `./lint` — runs ShellCheck on all scripts (CI also runs this). Run after every change.
- **Test:** `./test` — runs all scripts end-to-end (slow; requires Docker, clones repos from Gerrit)

There is no build step. There are no unit tests — `./test` is an integration test that exercises every script.

## Script conventions

- Scripts must work with bash 3.2 (macOS default) — avoid bash 4+ features (associative arrays, `mapfile`, `${var,,}`, `|&`)
- All commands in all scripts must work on both Ubuntu and macOS. If a command is not available on both, check the OS and run the appropriate command (e.g. `caffeinate` on macOS, `systemd-inhibit` on Linux)
- Command names and interfaces should match [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart) whenever possible
- One executable file per command, no `.sh` extensions
- All bash scripts start with `set -euo pipefail` and source `lib` (which enables `set -x` with a custom `PS4`). Exception: utility scripts (`help`, `lint`, `test`, `deep_test`, `dependencies`) skip `lib` because trace output would bury their actual output in noise.
- Long-running scripts (`run_all`, `test`) source `inhibit_sleep` to prevent the machine from suspending
- All scripts must have a comment block at the top describing what the script does, with example usage if it takes arguments
- Every line of code must have an inline comment explaining what it does
- When changing a script, check that all comments (header and inline) still accurately describe the code
- When adding or updating a script, ensure `help`, `README.md`, `lint`, and `test` are kept in sync, and run `./lint`
- Every new argument to a script must have a corresponding test in `test`
- Docker container runs as a different user, so `chmod 777` is used on shared directories
- `clean` and `deep_clean` use Docker (as root) to remove container-owned files before `rm -rf`
- The `--entrypoint=quibble-with-supervisord` flag is used on all `docker run` commands
- Port 9413 is exposed via `-p 9413:9413` (macOS; not `--network host`)

## Directory layout (runtime, all gitignored)

- `ref/` — bare git repos cloned from Gerrit, used as `--reference` to speed up clones
- `src/` — MediaWiki working copy (created by Quibble inside the container)
- `cache/` — Quibble cache (composer, npm)
- `log/` — Quibble logs
