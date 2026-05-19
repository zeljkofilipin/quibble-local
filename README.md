# quibble-local

Simple wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) locally via Docker.

Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart), using the same one-file-per-command convention.

## Prerequisites

- [Bash](https://www.gnu.org/software/bash/)
- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)
- [ShellCheck](https://www.shellcheck.net/) (optional, for linting)
- [Bats](https://github.com/bats-core/bats-core) (optional, for unit tests)

Alternatively, open the repo in the provided [dev container](https://containers.dev/) (`.devcontainer/devcontainer.json`) to get Bash, Git, Docker (via the host socket), ShellCheck, Bats, and the [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI pre-installed.

## Environment variables

### `VERBOSE`

All commands run in **silent mode** by default (no trace output, no debug info). Use `VERBOSE=1` for full output including trace output (`set -x`) and debug info.

    ./fresh_install            # silent (default)
    VERBOSE=1 ./fresh_install  # verbose (trace output)

When commands are called from `test_integration`, `test_integration_slow`, or `run_selenium_tests_all_gated`, the mode is inherited via the `VERBOSE` environment variable.

### `TIME_UTC`

UTC timestamps in batch script output (verbose-mode separators, per-step ok/FAIL lines, wave/combination headers) are **off by default**. Set `TIME_UTC=1` to append a `YYYY-MM-DD HH:MM:SS UTC` timestamp to those lines.

    ./test_integration            # no timestamps (default)
    TIME_UTC=1 ./test_integration # append UTC timestamps

Useful for long-running batch scripts (`find_dependencies_minimal_*`, `run_selenium_tests_*_gated`, `install_each_gated`, `test_integration*`) where knowing when each step finished is helpful.

### `TIME_ELAPSED`

Elapsed-time durations (per-step / per-test `(Xs)` strings, silent-mode `ok (Xs)` / `FAIL (Xs)` lines, the EXIT-trap total `(Xs)` line, and `generate_examples`' `took (Xs)` summary) are **off by default**. Set `TIME_ELAPSED=1` to enable them.

    ./test_integration                # no durations (default)
    TIME_ELAPSED=1 ./test_integration # show durations

Combinable with `TIME_UTC=1` for full timing output:

    TIME_ELAPSED=1 TIME_UTC=1 ./test_integration

### `QUIBBLE_IMAGE`

Override the Docker image used by all commands. Useful when developing or testing changes to Quibble itself.

    QUIBBLE_IMAGE=my-quibble:dev ./fresh_install
    QUIBBLE_IMAGE=docker-registry.wikimedia.org/releng/quibble-bullseye-php83:1.2.3 ./install extensions/Echo

Default: `docker-registry.wikimedia.org/releng/quibble-bullseye-php83:latest`

### `ENVIRONMENT`

Run multiple independent sessions on the same machine simultaneously. Each environment uses isolated directories (`src_N/`, `src_save_N/`) so they don't conflict.

    # Terminal 1: install and test Echo
    ENVIRONMENT=0 ./fresh_install
    ENVIRONMENT=0 ./install extensions/Echo
    ENVIRONMENT=0 ./run_selenium_tests extensions/Echo
    ENVIRONMENT=0 ./remove

    # Terminal 2 (at the same time): run find_dependencies_minimal_greedy for MinervaNeue
    ENVIRONMENT=1 ./find_dependencies_minimal_greedy skins/MinervaNeue
    ENVIRONMENT=1 ./remove

Sets `QUIBBLE_SRC=src_N` and `QUIBBLE_SAVE=src_save_N`. Cache and ref directories are shared (safe for concurrent use). Use `./remove_srcs` to remove all environments at once.

### `FAST`

`FAST=1` runs `./fresh_install` once, saves the state with `./save`, then uses `./restore` instead of re-running `./fresh_install` for each subsequent component. Used by `install_each_gated`, `run_selenium_tests_all_gated`, and `run_selenium_tests_required_gated`. (`find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, and `find_dependencies_minimal_thorough` always use save/restore automatically.)

    FAST=1 ./run_selenium_tests_all_gated

### `DRY_RUN`

`DRY_RUN=1` passes [`--dry-run`](https://doc.wikimedia.org/quibble/) to Quibble so it prints what it would do without actually running tests or installing anything. Useful for testing wrapper-script output (especially long-running commands) without paying the cost of a real run. Applies to `./fresh_install`, `./install`, `./run_selenium_tests`, and `./run_php_unit_tests`.

    DRY_RUN=1 ./fresh_install
    DRY_RUN=1 ./install extensions/Echo
    DRY_RUN=1 ./run_selenium_tests extensions/Echo
    DRY_RUN=1 ./run_php_unit_tests extensions/Echo

## Commands (same as mediawiki-quickstart)

### `./fresh_install`

Set up MediaWiki (without running tests). Runs `./prepare` first if needed, then `./remove` to ensure a fresh `src/`. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./fresh_install
    VERBOSE=1 ./fresh_install
    DRY_RUN=1 ./fresh_install                                   # pass --dry-run to Quibble (no real install)

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./install`

Install an extension or skin. Assumes `./fresh_install` has been run first. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./install extensions/Echo
    ./install skins/MinervaNeue
    VERBOSE=1 ./install extensions/Echo
    QUIBBLE_DEPS="" ./install extensions/Echo                    # no dependencies
    QUIBBLE_DEPS="EventLogging" ./install extensions/Echo        # only specific dependencies
    DRY_RUN=1 ./install extensions/Echo                          # pass --dry-run to Quibble (no real install)

Environment variables:

- `QUIBBLE_DEPS`: Override which dependencies to install (space-separated). When set, replaces the dependencies from `zuul/dependencies.yaml`. Set to empty string for no dependencies.

See: [Install MediaWiki Core and an Extension](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core_and_an_Extension)

### `./run_selenium_tests`

Run Selenium tests. Assumes `./fresh_install` (or `./install`) has been run first.

    ./run_selenium_tests
    ./run_selenium_tests extensions/Echo
    ./run_selenium_tests --spec tests/selenium/wdio-mediawiki/specs/BlankPage.js
    ./run_selenium_tests --spec tests/selenium/specs/page.js
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js
    ./run_selenium_tests --spec tests/selenium/specs/user.js --mochaOpts.grep "should be able to create account"
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js --mochaOpts.grep "alerts and notices are visible"
    VERBOSE=1 ./run_selenium_tests extensions/Echo
    DRY_RUN=1 ./run_selenium_tests extensions/Echo  # pass --dry-run to Quibble (no real run)

See: [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

### `./run_php_unit_tests`

Run PHPUnit tests. Assumes `./fresh_install` (or `./install`) has been run first.

    ./run_php_unit_tests
    ./run_php_unit_tests --filter testValidSpecialPageAliases
    ./run_php_unit_tests extensions/Echo
    ./run_php_unit_tests extensions/Echo --filter testNotificationCount
    VERBOSE=1 ./run_php_unit_tests extensions/Echo
    DRY_RUN=1 ./run_php_unit_tests extensions/Echo  # pass --dry-run to Quibble (no real run)

See: [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

### `./shellto`

Open a shell in the container with MediaWiki running at http://127.0.0.1:9413. Assumes `./fresh_install` (or `./install`) has been run first.

    ./shellto
    VERBOSE=1 ./shellto

### `./test_integration`

Run fast integration tests (~20 minutes total) and report which ones passed or failed. Useful for detecting regressions after changes. Slow entries live in `./test_integration_slow`. Silent by default; use `VERBOSE=1` for full output.

    ./test_integration
    VERBOSE=1 ./test_integration

To start from a completely clean state, run `./remove_all` first.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

### `./test_integration_slow`

Run integration tests that are too slow for the fast suite (`./test_integration`). Includes network-heavy setup, full test suites, exhaustive algorithms, and gated repository tests. Silent by default; use `VERBOSE=1` for full output.

    ./test_integration_slow
    VERBOSE=1 ./test_integration_slow

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a long time to run.

### `./test_unit`

Run Bats unit tests. Fast, no Docker needed. Requires Bats in addition to the base prerequisites.

    ./test_unit
    ./test_unit test/lib_awk.bats  # run a single test file

## Setup and cleanup

### `./prepare`

Prepare the local environment for running Quibble. Pulls the Docker image, clones bare git repos as references, and creates working directories.

    ./prepare
    VERBOSE=1 ./prepare

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./save`

Save the current state of `src/` (MediaWiki installation) for fast restore later. Uses Docker-as-root to copy files (works on both macOS and Linux).

    ./save
    VERBOSE=1 ./save

### `./restore`

Restore `src/` from a previously saved state (created by `./save`). Much faster than running `./fresh_install` again.

    ./restore
    VERBOSE=1 ./restore

### `./fetch`

Fetch the latest changes for bare git repos in `ref/` from Gerrit. With no arguments, fetches all repos. With arguments, fetches only the specified repos.

    ./fetch
    ./fetch ref/mediawiki/core.git
    ./fetch ref/mediawiki/extensions/Echo.git ref/mediawiki/skins/Vector.git
    PARALLEL=4 ./fetch
    VERBOSE=1 ./fetch

### `./remove`

Remove `src/` (MediaWiki source code). Cache, logs, bare git repos, and the Docker image are kept.

    ./remove
    VERBOSE=1 ./remove

### `./remove_srcs`

Remove all `src/` directories across all environments (`src/`, `src_save/`, `src_N/`, `src_save_N/`, `src_worker_N/`). Keeps `ref/`, `cache/`, `log/`, and the Docker image.

    ./remove_srcs
    VERBOSE=1 ./remove_srcs

### `./remove_all`

Remove everything created by quibble-local, including bare git repos in `ref/` and the Docker image.

    ./remove_all
    VERBOSE=1 ./remove_all

## Data queries

These scripts output information and don't run Docker containers.

### `./list_dependencies`

Output dependencies for an extension or skin from `zuul/dependencies.yaml`.

    ./list_dependencies extensions/Echo
    ./list_dependencies skins/MinervaNeue

### `./list_dependencies_required`

Output required dependencies for an extension or skin from its `extension.json` or `skin.json`. These are the extensions/skins listed in the `requires` field that must always be present.

    ./list_dependencies_required extensions/Echo
    ./list_dependencies_required extensions/GrowthExperiments
    ./list_dependencies_required skins/MinervaNeue

### `./list_dependencies_optional`

Output optional dependencies for an extension or skin. These are dependencies in `zuul/dependencies.yaml` that are NOT in `extension.json`/`skin.json` `requires` field. Complement of `./list_dependencies_required`.

    ./list_dependencies_optional extensions/Echo
    ./list_dependencies_optional skins/MinervaNeue

### `./list_dependencies_combinations`

Output all possible combinations of dependencies for an extension or skin. One combination per line (space-separated), starting with one dependency, ending with all dependencies.

    ./list_dependencies_combinations extensions/Echo
    ./list_dependencies_combinations skins/MinervaNeue

### `./list_gated`

Output the list of gated repositories (extensions and skins) from `parameter_functions.py`. Clones `integration/config` into `src/config` if needed. Assumes `./prepare` has been run first.

    ./list_gated

### `./selenium_tests_exist`

Check if a component has Selenium tests. Exits 0 if `selenium-test` script exists in `package.json`, 1 otherwise. Reads `package.json` from `src/<component>` if a working copy is present, otherwise from the bare repo in `ref/` via `git show`. Clones the bare repo from Gerrit if not already cloned. No Docker or `fresh_install` required, and no host write to `src/`.

    ./selenium_tests_exist
    ./selenium_tests_exist extensions/Echo
    ./selenium_tests_exist skins/MinervaNeue
    ./selenium_tests_exist skins/Vector

### `./suggest_parallel`

Suggest the number of parallel workers based on available CPU and memory. Each worker needs ~2 CPU cores and ~2 GB of Docker memory. Outputs a single number. Used by `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, `find_dependencies_minimal_thorough`, `install_each_gated`, `run_selenium_tests_all_gated`, and `run_selenium_tests_required_gated`.

On macOS, the result may differ depending on whether Docker is running. When Docker is running, CPU and memory are read from `docker info`, which reports the Docker Desktop VM allocation (often lower than host resources). When Docker is not running, the script falls back to `sysctl`, which reports full system CPU and memory — potentially suggesting more workers than Docker can actually support.

To maximize parallel workers on macOS, increase Docker Desktop memory: Docker Desktop → Settings → Resources → Memory. The formula is: workers = min(CPUs / 2, memory / 2 GB). On a 10-core / 64 GB machine with Docker Desktop defaults (~6 GB), memory is the bottleneck (3 workers instead of 5). Increasing Docker memory to 10+ GB removes the bottleneck.

    ./suggest_parallel
    PARALLEL=$(./suggest_parallel) ./run_selenium_tests_all_gated

## Finding minimum dependencies

These scripts find which optional dependencies are actually needed for Selenium tests to pass. They are long-running.

### `./find_dependencies_minimal_greedy`

Find the minimum dependencies using a greedy algorithm: starts with all optional deps, removes one at a time. O(N). Repeats until stable to catch order-dependent removals. Good general-purpose choice.

**Pick this when:** speed matters more than guaranteed correctness (greedy can miss the true minimum). For a guaranteed minimum, use `./find_dependencies_minimal_bottom_up` (fast when few deps are needed) or `./find_dependencies_minimal_thorough` (fast when many).

    ./find_dependencies_minimal_greedy extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_greedy extensions/Echo

- **Fast for extensions/GrowthExperiments** (17 deps, ~8 needed): ~17 tests regardless of how many are needed.
- **Slower for extensions/Echo** (4 deps, 0 needed): tests all 4 before concluding none are needed, while `find_dependencies_minimal_bottom_up` finds the answer in 1 test.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

### `./find_dependencies_minimal_bottom_up`

Find the minimum dependencies by testing combinations from smallest (0 deps) to largest. Stops at the first passing combination — guaranteed smallest.

**Pick this when:** you need a guaranteed minimum and expect the answer to be small (few deps actually needed). When many deps are needed, use `./find_dependencies_minimal_thorough` instead — its greedy upper bound prunes the search space.

    ./find_dependencies_minimal_bottom_up extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_bottom_up extensions/Echo
    PARALLEL=$(./suggest_parallel) ./find_dependencies_minimal_bottom_up extensions/Echo

- **Fast for extensions/Echo** (4 deps, 0 needed): tests empty set first, passes in 1 test.
- **Extremely slow for extensions/GrowthExperiments** (17 deps, ~8 needed): tests up to 2^17 = 131,072 combinations (~10 min each).

Environment variables:

- `PARALLEL=N`: Run N combinations simultaneously, each in an isolated `src_worker_$i/` directory. Use `./suggest_parallel` to determine N for your machine. Each worker needs ~2 CPU cores and ~2 GB of Docker memory.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

### `./find_dependencies_minimal_thorough`

Find and verify the minimum dependencies. Phase 1: greedy for a fast estimate. Phase 2: exhaustive verification of all smaller combinations. Confirms the result is truly minimal.

**Pick this when:** you need a guaranteed minimum and expect the answer to be large (many deps actually needed). Always slower than `./find_dependencies_minimal_greedy` (it runs greedy plus verification); when few deps are needed, `./find_dependencies_minimal_bottom_up` is faster.

    ./find_dependencies_minimal_thorough extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_thorough extensions/Echo
    PARALLEL=$(./suggest_parallel) ./find_dependencies_minimal_thorough extensions/Echo

- **Fast for extensions/Echo** (4 deps, 0 needed): greedy finds 0 in ~4 tests, verification confirms immediately.
- **Moderate for extensions/GrowthExperiments** (17 deps, ~8 needed): greedy finds ~8 in ~17 tests, then verifies by testing combinations of size 0–7 only (not all 131,072).

Environment variables:

- `PARALLEL=N`: Run N combinations simultaneously, each in an isolated `src_worker_$i/` directory. Use `./suggest_parallel` to determine N for your machine. Each worker needs ~2 CPU cores and ~2 GB of Docker memory.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

## Commands (all gated repositories)

These scripts operate on all gated extensions and skins (from `./list_gated`). They take a long time to run.

### `./prepare_gated`

Clone or fetch bare repos for all gated repositories. Extends `./prepare` by cloning bare repos for all gated extensions and skins. Assumes `./prepare` has been run first (needs `ref/integration/config.git`).

    ./prepare_gated
    VERBOSE=1 ./prepare_gated

### `./install_all_gated`

Install all gated extensions and skins into a single MediaWiki. Runs `./fresh_install` for core, then installs each gated component on top. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./install_all_gated
    VERBOSE=1 ./install_all_gated

### `./install_each_gated`

Install each gated extension or skin into its own fresh MediaWiki, one at a time. For each component: `./fresh_install`, then `./install`. Reports per-step and total duration. Unlike `./install_all_gated` (which stacks everything into one MediaWiki), this gives each component a clean MediaWiki so per-component install times are comparable.

    ./install_each_gated
    ./install_each_gated extensions/Echo
    VERBOSE=1 ./install_each_gated
    FAST=1 ./install_each_gated
    PARALLEL=$(./suggest_parallel) ./install_each_gated
    PARALLEL=4 FAST=1 ./install_each_gated

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./run_selenium_tests_all_gated`

Run Selenium tests for core and all gated repositories. For each component: `./fresh_install`, `./install` (if not core), check if Selenium tests exist, and run them. Silent by default; use `VERBOSE=1` for full output.

    ./run_selenium_tests_all_gated
    ./run_selenium_tests_all_gated extensions/Echo
    VERBOSE=1 ./run_selenium_tests_all_gated
    FAST=1 ./run_selenium_tests_all_gated
    PARALLEL=$(./suggest_parallel) ./run_selenium_tests_all_gated
    PARALLEL=4 FAST=1 ./run_selenium_tests_all_gated

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./run_selenium_tests_gated`

Install all gated extensions and skins into a single MediaWiki, then run all Selenium tests. Unlike `./run_selenium_tests_all_gated` (which does `./fresh_install` per component), this installs everything together into one `src/`.

    ./run_selenium_tests_gated
    VERBOSE=1 ./run_selenium_tests_gated

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a long time to run (50+ components).

### `./run_selenium_tests_required_gated`

Run Selenium tests for all gated repositories using only required dependencies (from `extension.json`/`skin.json`). For each component: `./fresh_install`, `./install` with required deps only, check if Selenium tests exist, and run them. Silent by default; use `VERBOSE=1` for full output.

    ./run_selenium_tests_required_gated
    ./run_selenium_tests_required_gated extensions/Echo
    VERBOSE=1 ./run_selenium_tests_required_gated
    FAST=1 ./run_selenium_tests_required_gated
    PARALLEL=$(./suggest_parallel) ./run_selenium_tests_required_gated
    PARALLEL=4 FAST=1 ./run_selenium_tests_required_gated

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./find_dependencies_minimal_gated`

Find minimum dependencies for all gated repositories (or a single component). For each component: check if Selenium tests exist, check if it has optional dependencies, and run `./find_dependencies_minimal_greedy` to find the minimum set.

    ./find_dependencies_minimal_gated
    ./find_dependencies_minimal_gated extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_gated
    PARALLEL=$(./suggest_parallel) ./find_dependencies_minimal_gated

Environment variables:

- `PARALLEL=N`: Run N components simultaneously, each in an isolated `ENVIRONMENT=N`. Use `./suggest_parallel` to determine N for your machine. Each worker needs ~2 CPU cores and ~2 GB of Docker memory.

See also: `./find_dependencies_minimal_greedy` for single-component usage.

**Warning:** Without arguments, this will take a very long time to run (50+ components). This script inhibits sleep to prevent the machine from suspending.

## Development and CI

### `./help`

List all scripts with their description and usage.

    ./help
    ./help install
    ./help ./install

### `./ci`

Run the same lint check that GitLab CI runs, using Docker. Does not require ShellCheck to be installed locally.

    ./ci

### `./lint`

Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts in the repo. Requires ShellCheck in addition to the base prerequisites.

    ./lint

### `./generate_example`

Generate an example output file by running a command and capturing its output. Used to refresh the example `.txt` files in `examples/`. Writes a `$ <command>` header followed by the captured stdout+stderr. The captured command is allowed to fail, so usage-on-failure outputs can also be captured.

    ./generate_example examples/help.txt './help'
    ./generate_example examples/install.txt './install'

### `./generate_examples`

Regenerate example output files in `examples/` in bulk by iterating each project-root script's `# Usage:` block. Runs every `Usage:` line of every script; filenames are derived from the command via `lib/cmd_to_filename`. Useful for refreshing `examples/` after script renames or behavior changes.

    ./generate_examples
    PREVIEW=1 ./generate_examples
    FAST=1 ./generate_examples

`PREVIEW` and `FAST` do different things:

- `PREVIEW=1 ./generate_examples` — outer-level preview. Prints `Would generate ...` for each Usage line. No files are written, no inner scripts run. Named `PREVIEW` to avoid overloading the inner Quibble [`DRY_RUN`](#dry_run) env var, which has a different meaning.
- `FAST=1 ./generate_examples` — actually generate every file, but prepend `DRY_RUN=1` to each Usage command so Quibble short-circuits. Inner scripts that honor `DRY_RUN` (`install`, `fresh_install`, `run_php_unit_tests`, `run_selenium_tests`, and batch scripts that propagate the env var to them) finish in seconds instead of minutes. Other scripts ignore the unused env var.

The two can be combined: `PREVIEW=1 FAST=1 ./generate_examples` previews the FAST-mode command list. Use `FAST=1` to iterate on `generate_examples` itself or to validate the pipeline end-to-end. **Do not commit `examples/*.txt` produced under `FAST=1` — they do not reflect real script behavior.**

## Internal scripts (`lib/`)

These are sourced by other scripts and are not intended to be run directly.

### `lib/batch_setup`

Shared setup for batch scripts (`test_integration`, `test_integration_slow`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, `find_dependencies_minimal_thorough`). Sets up verbose/silent mode, sources helper libraries (`inhibit_sleep`, `print_results`, `heartbeat`), creates log directory, and initializes result tracking variables.

### `lib/heartbeat`

Run a command, save output to a log file, and print a dot for each line of output. Sourced by `test_integration`, `test_integration_slow`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, and `find_dependencies_minimal_thorough` for silent mode progress feedback. Provides `run_with_dots` function.

### `lib/debug_info`

Outputs debug information (OS, CPU, RAM, bash, git, docker version, docker CPUs and RAM), checks basic prerequisites (git), shows a "use VERBOSE=1 for full output" hint in silent mode, and sets up duration tracking via `lib/duration_trap`. Sourced by all scripts.

### `lib/format_duration`

Provides `_quibble_format_duration` function that formats elapsed seconds as a human-readable duration string (e.g. "1h 5m 30s"). Omits zero-value days, hours, and minutes; always shows seconds. Gated on the `TIME_ELAPSED` environment variable: off by default (returns empty), set `TIME_ELAPSED=1` to enable. Sourced by `lib/duration_trap` and `lib/batch_setup`.

### `lib/duration_trap`

Sets an EXIT trap to print total script duration when the script exits. Only activates when stdout is a terminal. Output is empty unless `TIME_ELAPSED=1`. Sources `lib/format_duration`. Sourced by `lib/debug_info`, `lib/batch_setup`, and `lint`. `lib/silent_output` overrides this trap with its own handler that also includes duration.

### `lib/setup`

Shared setup sourced by scripts that run Docker commands. Sources `lib/debug_info` for debug output, checks Docker prerequisites (docker installed, Docker daemon running), exports `QUIBBLE_IMAGE` and `QUIBBLE_VOLUMES`, sets a custom debug prompt, enables trace output (`set -x`), and sources `lib/silent_output` for output redirection.

### `lib/silent_output`

Output redirection for silent mode. Saves all output to a log file (e.g. `log/fresh_install.log`) and prints a dot per line to the terminal. On exit, prints "ok" or "FAIL" with the log file path; the elapsed-time portion appears only when `TIME_ELAPSED=1`. Sourced by `lib/setup`.

### `lib/docker_chmod`

Provides `docker_chmod` function that sets directories to world-writable (`chmod 777`), falling back to Docker-as-root when directories are owned by root from previous container runs. Sourced by `fresh_install`, `save`, and `restore`.

### `lib/parse_component_args`

Parses optional component path (`extensions/X` or `skins/X`) and extra arguments from the command line. Sets `component`, `zuul_project`, and `extra_args` variables. Sourced by `run_selenium_tests` and `run_php_unit_tests`.

### `lib/run_quibble_test`

Provides `run_quibble_test` function that runs a Quibble test command in Docker with `--skip-zuul` and `--skip-deps`. Takes Quibble arguments (e.g. `--run selenium`). Expects `lib/setup` and `lib/parse_component_args` to be sourced first. Sourced by `run_selenium_tests` and `run_php_unit_tests`.

### `lib/build_component_list`

Builds the `components` array from either `$1` (single component) or `./list_gated` (all gated extensions/skins). Sourced by `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_required_gated`, and `find_dependencies_minimal_gated`.

### `lib/clone_or_fetch`

Provides `clone_or_fetch` function that clones or fetches a bare repo from Gerrit into `ref/`. If the repo already exists, fetches updates; otherwise clones it. Accepts optional `--quiet` flag. Sourced by `install`, `prepare_gated`, `selenium_tests_exist`, and `lib/resolve_deps`.

### `lib/dep_repo_path`

Provides `dep_repo_path` function that converts a dependency name to a Gerrit repo path. Extensions (e.g. `Echo`) map to `mediawiki/extensions/Echo`. Skins (e.g. `skins/MinervaNeue`) map to `mediawiki/skins/MinervaNeue`. Sourced by `lib/resolve_deps` and `lib/minimal_setup`.

### `lib/resolve_deps`

Resolves dependency repos for a component, cloning bare repos as needed. Sets the `deps` array with repo paths. Reads from `QUIBBLE_DEPS` env var if set, otherwise from `./list_dependencies`. Sourced by `install`.

### `lib/ensure_config`

Sourced by scripts that need zuul config (`list_dependencies`, `list_gated`, `install`). Ensures the `integration/config` working copy exists in `src/config` by cloning from the bare repo.

### `lib/inhibit_sleep`

Sourced by long-running scripts (`find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, `find_dependencies_minimal_thorough`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `test_integration`, `test_integration_slow`, `generate_examples`) to prevent the machine from suspending. Uses `caffeinate` on macOS and `systemd-inhibit` on Linux.

### `lib/print_results`

Sourced by scripts that track test/step results (`install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `find_dependencies_minimal_gated`, `test_integration`, `test_integration_slow`). Provides `print_results` function that prints pass/fail summary and exits with error if any failures.

### `lib/utc_timestamp`

Provides `utc_timestamp` function that prints the current UTC time in `YYYY-MM-DD HH:MM:SS UTC` format. Gated on the `TIME_UTC` environment variable: off by default, set `TIME_UTC=1` to enable. Sourced by `lib/batch_setup`.

### `lib/print_header`

Provides `print_header` function that prints a section header for a component in batch scripts. In verbose mode: separator box with label (and a UTC timestamp when `TIME_UTC=1`). In silent mode: label followed by a space. Sourced by `lib/batch_setup`.

### `lib/record_passed`

Provides `record_passed` function that records a component as passed (if not already in the failed list). Sourced by `lib/batch_setup`.

### `lib/run_test`

Provides `run_test` function and `test_counter` for `test_integration`-style scripts. Runs a command, prints what it does, and records pass/fail in `$passed`/`$failed`. In verbose mode prints a separator box and full output; in silent mode saves output to a numbered log file (e.g. `log/silent/01-help.log`) and prints a dot per line. Must be sourced after `lib/batch_setup`. Sourced by `test_integration` and `test_integration_slow`.

### `lib/run_waves`

Generic wave-based parallel worker orchestration. Processes an array of items in waves of `$parallel` workers, each in an isolated `src_worker_N/` directory. The caller defines `_run_worker` and `_collect_result` functions to customize worker behavior and result handling. Sourced by `install_each_gated`, `run_selenium_tests_all_gated`, and `run_selenium_tests_required_gated` in parallel mode.

### `lib/remove_worker_dirs`

Cleans up `src_worker_*` directories created by parallel execution. Tries `rm -rf` first (works on macOS). Falls back to Docker-as-root for container-owned files (Linux). Sourced by `lib/run_waves` and `lib/parallel` after parallel runs complete.

### `lib/worker_init`

Common setup for parallel worker subshells. Sets `QUIBBLE_SRC` and `QUIBBLE_BACKGROUND`, redirects output to a log file, and runs `./restore` (fast mode) or `./fresh_install`. Sourced inside worker subshells by `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_required_gated`, and `lib/parallel`.

### `lib/parse_requires.awk`

Awk script that parses `requires.extensions` and `requires.skins` from `extension.json` or `skin.json`. Used by `list_dependencies_required`.

### `lib/combinations.awk`

Awk script that generates all bitmask combinations of dependencies, ordered by size (starting from 1). Used by `list_dependencies_combinations`.

### `lib/combinations_with_empty.awk`

Awk script that generates all bitmask combinations including the empty set, ordered by size (starting from 0). Used by `find_dependencies_minimal_bottom_up` and `find_dependencies_minimal_thorough`.

### `lib/parse_yaml_list.awk`

Awk script that parses a YAML list under a given key from `zuul/dependencies.yaml`. Used by `list_dependencies`.

### `lib/parse_python_list.awk`

Awk script that extracts entries from a Python list assignment in `parameter_functions.py`. Used by `list_gated`.

### `lib/parse_usage.awk`

Awk script that extracts the `# Usage:` block from a script header. Used by `generate_examples`.

### `lib/cmd_to_filename`

Provides `cmd_to_filename`, a Bash function that converts a Usage command string (e.g. `./install extensions/Echo`) to an `examples/*.txt` filename (e.g. `examples/install-extensions_echo.txt`). Sourced by `generate_examples`.

### `lib/minimal_setup`

Shared setup for `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, and `find_dependencies_minimal_thorough`. Reads dependencies, classifies them into required/optional, pre-clones bare repos. Sets up `fresh_or_restore` function and all shared variables.

### `lib/print_dep_summary`

Prints a summary of all, required, and optional dependencies plus total combinations to test. Sourced by `lib/minimal_setup`.

### `lib/build_full_combo`

Builds a full dependency combination from required + optional deps. Sets the `full_combo` variable. Sourced by `lib/greedy`.

### `lib/fresh_or_restore`

Defines the `fresh_or_restore` function: runs `./fresh_install` or `./restore` depending on FAST mode. In fast mode, saves state after first `fresh_install` + `install` so subsequent calls restore instead. Sourced by `lib/minimal_setup`.

### `lib/greedy`

Greedy algorithm for `find_dependencies_minimal_greedy`: starts with all optional deps, removes one at a time. O(N) instead of O(2^N). Repeats until stable to catch order-dependent removals. Sourced by `find_dependencies_minimal_greedy`.

### `lib/parallel`

Parallel exhaustive search: tests combinations in waves of N workers, each in an isolated `src_worker_$i/` directory. Sourced by `find_dependencies_minimal_bottom_up` and `find_dependencies_minimal_thorough` when `PARALLEL > 1`.

### `lib/print_found`

Prints the "minimum dependencies found" results (header, required deps, optional deps). Sourced by `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, and `find_dependencies_minimal_thorough`.

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
