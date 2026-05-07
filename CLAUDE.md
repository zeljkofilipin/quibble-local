# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) (MediaWiki CI test runner) locally via Docker. Targets macOS and Ubuntu. Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart).

## Prerequisites

Bash, Git, and Docker. Optional: [ShellCheck](https://www.shellcheck.net/) (for linting), [Bats](https://github.com/bats-core/bats-core) (for unit tests). When adding a new dependency, also add it to the prerequisites section in `README.md`.

## CI

GitLab CI must pass for every commit. The pipeline runs ShellCheck (lint), Bats (unit tests), and security scans. Test CI locally before pushing:

- **Local:** `./lint` (ShellCheck) and `./test_unit` (Bats) — fast, requires local installs
- **Docker (same images as CI):** `./ci` — authoritative check, run after every change

## Lint and test

- **Lint:** `./lint` — runs ShellCheck on all scripts locally (requires ShellCheck installed)
- **Unit test:** `./test_unit` — runs Bats unit tests locally (fast, no Docker needed, requires Bats installed)
- **CI:** `./ci` — runs ShellCheck and Bats in Docker (same images as GitLab CI). Run after every change. This is the authoritative check — if `./ci` passes, GitLab CI will pass.
- **Integration test:** `./test_integration` — runs fast scripts end-to-end (~20 minutes total; requires Docker)
- **Slow integration test:** `./test_integration_slow` — runs tests that are too slow for the fast suite (network-heavy setup, full test suites, exhaustive algorithms, gated repository tests). Kept separate from `./test_integration` so that suite stays fast.

There is no build step. `./test_integration` is an integration test that exercises every script. Unit tests use [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System). All scripts should have Bats tests where possible. Bats tests go in the `test/` directory. Write code in a way that maximizes testability with Bats — extract logic into small scripts or `lib/` functions that can be tested without Docker or network access. Every new feature (script, environment variable, flag, etc.) should have both a unit test and an integration test, if possible.

## Script conventions

- Scripts must work with bash 3.2 (macOS default) — avoid bash 4+ features (associative arrays, `mapfile`, `${var,,}`, `|&`)
- All commands in all scripts must work on both Ubuntu and macOS. If a command is not available on both, check the OS and run the appropriate command (e.g. `caffeinate` on macOS, `systemd-inhibit` on Linux)
- Users of this tool are likely familiar with [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart). All user-facing scripts, command names, options, and output should be as similar to mediawiki-quickstart as possible. When adding a new feature or option, check how mediawiki-quickstart does it first. If `src/mediawiki-quickstart` is not available, clone it: `git clone --bare https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart.git ref/test-platform/mediawiki-quickstart.git && git clone --reference ref/test-platform/mediawiki-quickstart.git https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart.git src/mediawiki-quickstart`
- Each script should do as little as possible. Any logic that can sensibly be a separate script should be extracted into one. Prefer composing small scripts over building large monolithic ones.
- When refactoring, make small incremental changes so each step can be a separate git commit. Do not batch multiple independent changes together — complete one change fully (including lint and tests), then stop and let the user commit before starting the next change.
- Do not embed awk (or sed, python, perl, etc.) code inline as strings in bash scripts. Extract them into separate files in `lib/` (e.g. `lib/parse_requires.awk`) and call them with `awk -f`. Inline tool code gets no syntax highlighting and cannot be linted.
- One executable file per command, no `.sh` extensions
- Most scripts source `lib/debug_info` which outputs debug information (OS, bash, git, docker versions) and a hint on how to enable verbose mode. Exception: data scripts (`dependencies`, `dependencies_combinations`, `gated`, `dependencies_optional`, `dependencies_required`, `selenium_tests_exist`) skip `lib/debug_info` because their stdout is consumed by other scripts and debug output would corrupt the data. Scripts that run Docker commands also source `lib/setup` (which checks Docker prerequisites, sets up Docker config, and in verbose mode enables `set -x` with a custom `PS4`). Exception: utility scripts (`ci`, `help`, `lint`, `test_unit`, `test_integration`, `test_integration_slow`, `test_remove_all`, `dependencies`, `dependencies_combinations`, `gated`, `dependencies_minimal_greedy`, `dependencies_minimal_bottom_up`, `dependencies_minimal_gated`, `dependencies_minimal_thorough`, `dependencies_optional`, `dependencies_required`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_required_gated`, `selenium_tests_exist`, `suggested_parallel`) skip `lib/setup` because trace output would bury their actual output in noise.
- Batch scripts (`test_integration`, `test_integration_slow`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_required_gated`, `dependencies_minimal_greedy`, `dependencies_minimal_bottom_up`, `dependencies_minimal_gated`, `dependencies_minimal_thorough`) source `lib/batch_setup` for shared verbose/silent mode setup, log directory creation, and result tracking variables.
- All scripts have silent and verbose modes. Silent mode is the default. In silent mode, scripts output debug information (OS, bash, git, docker versions) and a "use VERBOSE=1 for full output" hint, then every line of output produces a dot on the terminal for progress feedback, and full output is saved to a log file (e.g. `log/fresh_install.log`). Use `VERBOSE=1` for full output including trace output (`set -x`) and debug info (e.g. `VERBOSE=1 ./fresh_install`). `shellto` is an exception: it is interactive and always shows output. Verbose mode is controlled by the `VERBOSE` environment variable (matching mediawiki-quickstart's convention).
- `lib/debug_info` checks basic prerequisites (git) and outputs debug information only when stdout is a terminal (`[ -t 1 ]`). This prevents debug output from corrupting data when a script's stdout is piped or captured (e.g. `./dependencies` called from `./install` via process substitution). `lib/setup` additionally checks Docker-specific prerequisites (docker installed, docker running)
- Long-running scripts (`dependencies_minimal_greedy`, `dependencies_minimal_bottom_up`, `dependencies_minimal_gated`, `dependencies_minimal_thorough`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_required_gated`, `test_integration`, `test_integration_slow`) source `lib/inhibit_sleep` to prevent the machine from suspending
- All scripts must have a comment block at the top describing what the script does, with example usage if it takes arguments
- Every line of code must have an inline comment explaining what it does. Comments should be plentiful, especially around bash quirks and non-obvious syntax (e.g. `${0##*/}`, `${arr[@]+"..."}`, `$@` vs `$*`, process substitution `< <(...)`, file descriptor redirection `<&3`, `set -euo pipefail` flags, docker flags). Most users and developers will not be familiar with bash.
- When changing a script, check that all comments (header and inline) still accurately describe the code
- `README.md` and script comment headers (the block shown by `./help <script>`) must always contain the same information. When updating one, update the other to match. This includes descriptions, usage examples, environment variables, performance notes, warnings, and "See:" links.
- When adding or updating a script, ensure `README.md` and the appropriate integration test suite (`test_integration` or `test_integration_slow`) are kept in sync, and run `./lint`. `lint` and `help` auto-discover scripts (by checking the first line for a bash shebang or shellcheck directive), so they do not need manual updates when adding new scripts. Verify new scripts appear in `./help` output.
- Do not explicitly list all scripts in code. Use auto-discovery (checking first line for shebang/shellcheck directive) instead, so new scripts are picked up automatically.
- Internal scripts (sourced helpers in `lib/` like `lib/setup`, `lib/inhibit_sleep`) must be documented in a separate section in `README.md` to make it clear they are not intended to be run directly
- Every new argument to a script must have a corresponding test in the appropriate integration test suite (see next bullet for which suite)
- Integration test entries are split across two suites by observed runtime: `test_integration` (fast — ~10 minutes total, each entry ≤1 minute) and `test_integration_slow` (slow — tests too slow for the fast suite). Annotate each entry's approximate runtime in its inline comment as `# Nm: ...` or `# <1m: ...`.
- Scripts that are destructive across environments (e.g. `remove_srcs`, `remove_all`) must NOT be in `test_integration`, so it can run safely while other environments are active
- Long-running scripts that can be scoped to a single component should be tested with one component (e.g. `./run_selenium_tests_all_gated extensions/Echo`). Scripts that cannot be scoped and are already tested implicitly by another integration test entry do not need their own entry (e.g. `install_all_gated` is tested by `run_selenium_tests_gated` in `test_integration_slow`).
- Docker container runs as a different user, so `chmod 777` is used on shared directories
- `remove` and `remove_all` use Docker (as root) to remove container-owned files before `rm -rf`
- The `--entrypoint=quibble-with-supervisord` flag is used on all `docker run` commands that run Quibble (cleanup commands in `remove`, `remove_all`, and `fresh_install` use `--entrypoint bash` instead)
- Port 9413 is exposed via `-p 9413:9413` (macOS; not `--network host`)
- All functionality shared across two or more files must be extracted into a helper file in `lib/` (like `lib/setup` and `lib/inhibit_sleep`)
- When adding a new file type (e.g. `.bats`, `.awk`), add a corresponding `files.associations` entry in `.vscode/settings.json` so VS Code applies correct syntax highlighting

## Directory layout (runtime, all gitignored)

- `ref/` — bare git repos cloned from Gerrit, used as `--reference` to speed up clones
- `src/` — MediaWiki working copy (created by Quibble inside the container)
- `src_save/` — saved copy of `src/` for fast restore (created by `./save`)
- `src_worker_*/` — isolated src directories for parallel workers (created by `PARALLEL=N ./dependencies_minimal_thorough`)
- `cache/` — Quibble cache (composer, npm)
- `log/` — Quibble logs

**Do not read or search** `cache/`, `log/`, `ref/`, `src/`, `src_save/`, or `src_worker_*/` unless explicitly asked. These are large runtime directories (gigabytes of cloned repos, build artifacts, and logs) that are not part of the project source code.

**Do not read or search** `examples/` unless explicitly working on it. It contains captured command output (regenerated via `./generate_examples`), not project source code.
