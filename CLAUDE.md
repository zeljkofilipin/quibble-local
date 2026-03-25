# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) (MediaWiki CI test runner) locally via Docker. Targets macOS and Ubuntu. Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart).

## Prerequisites

Bash, Git, and Docker. Optional: [ShellCheck](https://www.shellcheck.net/) (for linting), [Bats](https://github.com/bats-core/bats-core) (for unit tests). When adding a new dependency, also add it to the prerequisites section in `README.md`.

## CI

GitLab CI must pass for every commit. The pipeline runs ShellCheck (lint) and security scans. Test CI locally before pushing:

- **Local lint (requires ShellCheck installed):** `./lint`
- **Local lint (Docker, same image as CI):** `./ci`

## Lint and test

- **Lint:** `./lint` — runs ShellCheck on all scripts (CI also runs this). Run after every change.
- **CI:** `./ci` — runs ShellCheck in Docker (same image as GitLab CI). Run after every change.
- **Integration test:** `./integration_test` — runs all scripts end-to-end (slow; requires Docker, clones repos from Gerrit)
- **Unit test:** `./unit_test` — runs Bats unit tests (fast, no Docker needed)

There is no build step. `./integration_test` is an integration test that exercises every script. Unit tests use [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System). All scripts should have Bats tests where possible. Bats tests go in the `test/` directory. Write code in a way that maximizes testability with Bats — extract logic into small scripts or `lib/` functions that can be tested without Docker or network access.

## Script conventions

- Scripts must work with bash 3.2 (macOS default) — avoid bash 4+ features (associative arrays, `mapfile`, `${var,,}`, `|&`)
- All commands in all scripts must work on both Ubuntu and macOS. If a command is not available on both, check the OS and run the appropriate command (e.g. `caffeinate` on macOS, `systemd-inhibit` on Linux)
- Users of this tool are likely familiar with [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart). All user-facing scripts, command names, options, and output should be as similar to mediawiki-quickstart as possible. When adding a new feature or option, check how mediawiki-quickstart does it first (clone is at `src/mediawiki-quickstart` if available, otherwise see the GitLab repo)
- Each script should do as little as possible. Any logic that can sensibly be a separate script should be extracted into one. Prefer composing small scripts over building large monolithic ones.
- When refactoring, make small incremental changes so each step can be a separate git commit.
- Do not embed awk (or sed, python, perl, etc.) code inline as strings in bash scripts. Extract them into separate files in `lib/` (e.g. `lib/parse_requires.awk`) and call them with `awk -f`. Inline tool code gets no syntax highlighting and cannot be linted.
- One executable file per command, no `.sh` extensions
- Most scripts source `lib/debug_info` which outputs debug information (OS, bash, git, docker versions) and a hint on how to enable verbose mode. Exception: data scripts (`dependencies`, `dependency_combinations`, `gated`, `optional_dependencies`, `required_dependencies`, `selenium_tests_exist`) skip `lib/debug_info` because their stdout is consumed by other scripts and debug output would corrupt the data. Scripts that run Docker commands also source `lib/setup` (which checks Docker prerequisites, sets up Docker config, and in verbose mode enables `set -x` with a custom `PS4`). Exception: utility scripts (`ci`, `help`, `lint`, `unit_test`, `integration_test`, `deep_clean_test`, `dependencies`, `dependency_combinations`, `gated`, `minimal_dependencies`, `optional_dependencies`, `required_dependencies`, `run_all`, `run_required`, `selenium_tests_exist`) skip `lib/setup` because trace output would bury their actual output in noise.
- Batch scripts (`integration_test`, `run_all`, `run_required`, `minimal_dependencies`) source `lib/batch_setup` for shared verbose/silent mode setup, log directory creation, and result tracking variables.
- All scripts have silent and verbose modes. Silent mode is the default. In silent mode, scripts output debug information (OS, bash, git, docker versions) and a "use VERBOSE=1 for full output" hint, then every line of output produces a dot on the terminal for progress feedback, and full output is saved to a log file (e.g. `log/fresh_install.log`). Use `VERBOSE=1` for full output including trace output (`set -x`) and debug info (e.g. `VERBOSE=1 ./fresh_install`). `shellto` is an exception: it is interactive and always shows output. Verbose mode is controlled by the `VERBOSE` environment variable (matching mediawiki-quickstart's convention).
- `lib/debug_info` checks basic prerequisites (git) and outputs debug information only when stdout is a terminal (`[ -t 1 ]`). This prevents debug output from corrupting data when a script's stdout is piped or captured (e.g. `./dependencies` called from `./install` via process substitution). `lib/setup` additionally checks Docker-specific prerequisites (docker installed, docker running)
- Long-running scripts (`minimal_dependencies`, `run_all`, `run_required`, `integration_test`) source `lib/inhibit_sleep` to prevent the machine from suspending
- All scripts must have a comment block at the top describing what the script does, with example usage if it takes arguments
- Every line of code must have an inline comment explaining what it does. Comments should be plentiful, especially around bash quirks and non-obvious syntax (e.g. `${0##*/}`, `${arr[@]+"..."}`, `$@` vs `$*`, process substitution `< <(...)`, file descriptor redirection `<&3`, `set -euo pipefail` flags, docker flags). Most users and developers will not be familiar with bash.
- When changing a script, check that all comments (header and inline) still accurately describe the code
- When adding or updating a script, ensure `README.md` and `integration_test` are kept in sync, and run `./lint`. `lint` and `help` auto-discover scripts (by checking the first line for a bash shebang or shellcheck directive), so they do not need manual updates when adding new scripts. Verify new scripts appear in `./help` output.
- Do not explicitly list all scripts in code. Use auto-discovery (checking first line for shebang/shellcheck directive) instead, so new scripts are picked up automatically.
- Internal scripts (sourced helpers in `lib/` like `lib/setup`, `lib/inhibit_sleep`) must be documented in a separate section in `README.md` to make it clear they are not intended to be run directly
- Every new argument to a script must have a corresponding test in `integration_test`
- Docker container runs as a different user, so `chmod 777` is used on shared directories
- `clean` and `deep_clean` use Docker (as root) to remove container-owned files before `rm -rf`
- The `--entrypoint=quibble-with-supervisord` flag is used on all `docker run` commands that run Quibble (cleanup commands in `clean`, `deep_clean`, and `fresh_install` use `--entrypoint bash` instead)
- Port 9413 is exposed via `-p 9413:9413` (macOS; not `--network host`)
- All functionality shared across two or more files must be extracted into a helper file in `lib/` (like `lib/setup` and `lib/inhibit_sleep`)
- When adding a new file type (e.g. `.bats`, `.awk`), add a corresponding `files.associations` entry in `.vscode/settings.json` so VS Code applies correct syntax highlighting

## Directory layout (runtime, all gitignored)

- `ref/` — bare git repos cloned from Gerrit, used as `--reference` to speed up clones
- `src/` — MediaWiki working copy (created by Quibble inside the container)
- `cache/` — Quibble cache (composer, npm)
- `log/` — Quibble logs

**Do not read or search** `cache/`, `log/`, `ref/`, or `src/` unless explicitly asked. These are large runtime directories (gigabytes of cloned repos, build artifacts, and logs) that are not part of the project source code.
