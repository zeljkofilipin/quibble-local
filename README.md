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

UTC timestamps in batch script output (verbose-mode separators, per-step result lines, wave/combination headers, and the EXIT-trap total UTC line) are **off by default**. Set `TIME_UTC=1` to append a `YYYY-MM-DD HH:MM:SS UTC` timestamp to those lines.

    ./test_integration            # no timestamps (default)
    TIME_UTC=1 ./test_integration # append UTC timestamps

Useful for long-running batch scripts (`find_dependencies_minimal_*`, `run_selenium_tests_*_gated`, `install_all_gated`, `install_each_gated`, `test_integration*`) where knowing when each step finished is helpful.

### `TIME_ELAPSED`

Elapsed-time durations (per-step / per-test `(Xs)` strings, silent-mode `(Xs)` (success) / `FAIL (Xs)` lines, the EXIT-trap total `(Xs)` line, and `generate_examples`' `took (Xs)` summary plus, at `PARALLEL=N`, its per-item pool completion times and a sorted `Slowest items:` list) are **off by default**. Set `TIME_ELAPSED=1` to enable them.

    ./test_integration                # no durations (default)
    TIME_ELAPSED=1 ./test_integration # show durations

Combinable with `TIME_UTC=1` for full timing output:

    TIME_ELAPSED=1 TIME_UTC=1 ./test_integration

### `QUIBBLE_IMAGE`

Override the Docker image used by all commands. Useful when developing or testing changes to Quibble itself.

    QUIBBLE_IMAGE=my-quibble:dev ./fresh_install
    QUIBBLE_IMAGE=docker-registry.wikimedia.org/releng/quibble-bookworm-php83:1.2.3 ./install extensions/Echo

Default: `docker-registry.wikimedia.org/releng/quibble-bookworm-php83:latest`

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

`FAST=1` runs `./fresh_install` once, saves the state with `./save`, then uses `./restore` instead of re-running `./fresh_install` for each subsequent component (or, for `find_dependencies_minimal_*`, each combination).

Used by `./install_each_gated`, `./run_selenium_tests_all_gated`, `./run_selenium_tests_required_gated`, and `./find_dependencies_minimal_*` (`find_dependencies_minimal_gated` propagates `FAST` to its `find_dependencies_minimal_greedy` children).

    FAST=1 ./install_each_gated
    FAST=1 ./run_selenium_tests_all_gated
    FAST=1 ./find_dependencies_minimal_greedy extensions/Echo

### `DRY_RUN`

`DRY_RUN=1` passes [`--dry-run`](https://doc.wikimedia.org/quibble/) to Quibble so it prints what it would do without actually running tests or installing anything. Useful for testing wrapper-script output (especially long-running commands) without paying the cost of a real run.

Applied directly by `./fresh_install`, `./install`, `./run_selenium_tests`, and `./run_php_unit_tests`. Inherited via the env by wrapper scripts that call them: `./generate_examples`, `./find_dependencies_minimal_*`, `./install_each_gated`, `./install_all_gated`, `./run_selenium_tests_all_gated`, and `./run_selenium_tests_required_gated`. Their inner Quibble-running calls short-circuit too.

    DRY_RUN=1 ./fresh_install
    DRY_RUN=1 ./install extensions/Echo
    DRY_RUN=1 ./run_selenium_tests extensions/Echo
    DRY_RUN=1 ./run_php_unit_tests extensions/Echo
    DRY_RUN=1 ./generate_examples
    DRY_RUN=1 ./find_dependencies_minimal_greedy extensions/Echo

### `RESOLVE_REQUIRES`

`RESOLVE_REQUIRES` controls whether `--resolve-requires` is passed to Quibble. Default `1` (on): Quibble reads each repo's `extension.json`/`skin.json` `requires` field and installs transitive dependencies automatically. Set to `0` to install exactly the deps listed in `QUIBBLE_DEPS` (or `zuul/dependencies.yaml`) with no auto-resolution.

    RESOLVE_REQUIRES=0 ./install extensions/Echo

`./find_dependencies_minimal_*` sets `RESOLVE_REQUIRES=0` automatically (via the shared `lib/minimal_setup`) — otherwise Quibble silently re-installs an optional dependency the algorithm just removed (via some kept dep's transitive `requires`), and the reported minimum is artificially small.

### `BRANCH`

`BRANCH` selects which git branch to install and check out, matching [mediawiki-quickstart's `BRANCH`](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart). When set, it passes [`--branch`](https://doc.wikimedia.org/quibble/) to Quibble (which branch to clone for core and any components) and then re-attaches `HEAD` to that branch, so `src/` ends up on a named branch. Unset (the default), `src/` is left in Quibble's detached `HEAD` state.

    BRANCH="wmf/1.44.0-wmf.20" ./fresh_install
    BRANCH="REL1_44" ./install extensions/Echo

Applied by `./fresh_install` and `./install`. Repos that lack the requested branch fall back to their own default branch (the same fallback Quibble uses), so no repo is left detached. If a repo can't be put on the branch or its fallback, the command fails — since `BRANCH` is explicit, an unmet request is surfaced rather than silently ignored.

## Commands (same as mediawiki-quickstart)

### `./fresh_install`

Set up MediaWiki (without running tests). Runs `./prepare` first if needed, then `./remove` to ensure a fresh `src/`. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./fresh_install
    VERBOSE=1 ./fresh_install
    DRY_RUN=1 ./fresh_install                                   # pass --dry-run to Quibble (no real install)
    BRANCH=REL1_44 ./fresh_install                              # install and check out a branch (default: leave detached HEAD)

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./install`

Install an extension or skin. Assumes `./fresh_install` has been run first. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./install extensions/Echo
    ./install skins/MinervaNeue
    VERBOSE=1 ./install extensions/Echo
    QUIBBLE_DEPS="" ./install extensions/Echo                    # no dependencies
    QUIBBLE_DEPS="EventLogging" ./install extensions/Echo        # only specific dependencies
    DRY_RUN=1 ./install extensions/Echo                          # pass --dry-run to Quibble (no real install)
    RESOLVE_REQUIRES=0 ./install extensions/Echo                 # install only QUIBBLE_DEPS; do not auto-resolve transitive requires
    BRANCH=REL1_44 ./install extensions/Echo                     # install and check out a branch (default: leave detached HEAD)

Environment variables:

- `QUIBBLE_DEPS`: Override which dependencies to install (space-separated). When set, replaces the dependencies from `zuul/dependencies.yaml`. Set to empty string for no dependencies.
- `RESOLVE_REQUIRES`: Default `1`. Set to `0` to install exactly the deps listed in `QUIBBLE_DEPS` without Quibble auto-resolving transitive `requires`. See [`RESOLVE_REQUIRES`](#resolve_requires).
- `BRANCH`: When set, install and check out this branch (passed to Quibble as `--branch`, then `HEAD` re-attached); unset leaves Quibble's detached `HEAD`. See [`BRANCH`](#branch).

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
    PARALLEL=1 ./fetch
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
    PARALLEL=1 ./run_selenium_tests_all_gated extensions/Echo

## Finding minimum dependencies

These scripts find which optional dependencies are actually needed for Selenium tests to pass. They are long-running.

### `./find_dependencies_minimal_greedy`

Find the minimum dependencies using a greedy algorithm: starts with all optional deps, removes one at a time. O(N). Repeats until stable to catch order-dependent removals. Good general-purpose choice.

**Pick this when:** speed matters more than guaranteed correctness (greedy can miss the true minimum). For a guaranteed minimum, use `./find_dependencies_minimal_bottom_up` (fast when few deps are needed) or `./find_dependencies_minimal_thorough` (fast when many).

    ./find_dependencies_minimal_greedy extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_greedy extensions/Echo
    FAST=1 ./find_dependencies_minimal_greedy extensions/Echo

- **Fast for extensions/GrowthExperiments** (17 deps, ~8 needed): ~17 tests regardless of how many are needed.
- **Slower for extensions/Echo** (4 deps, 0 needed): tests all 4 before concluding none are needed, while `find_dependencies_minimal_bottom_up` finds the answer in 1 test.

Environment variables:

- `FAST=1`: Runs `./fresh_install` once, saves state, then restores instead of re-running `./fresh_install` for each combination.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

### `./find_dependencies_minimal_bottom_up`

Find the minimum dependencies by testing combinations from smallest (0 deps) to largest. Stops at the first passing combination — guaranteed smallest.

**Pick this when:** you need a guaranteed minimum and expect the answer to be small (few deps actually needed). When many deps are needed, use `./find_dependencies_minimal_thorough` instead — its greedy upper bound prunes the search space.

    ./find_dependencies_minimal_bottom_up extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_bottom_up extensions/Echo
    FAST=1 ./find_dependencies_minimal_bottom_up extensions/Echo
    PARALLEL=1 ./find_dependencies_minimal_bottom_up extensions/Echo
    PARALLEL=1 FAST=1 ./find_dependencies_minimal_bottom_up extensions/Echo

- **Fast for extensions/Echo** (4 deps, 0 needed): tests empty set first, passes in 1 test.
- **Extremely slow for extensions/GrowthExperiments** (17 deps, ~8 needed): tests up to 2^17 = 131,072 combinations (~10 min each).

Environment variables:

- `FAST=1`: Runs `./fresh_install` once, saves state, then restores instead of re-running `./fresh_install` for each combination.
- `PARALLEL=N`: Run N combinations simultaneously, each in an isolated `ENVIRONMENT=N` (`src_N/`). Use `./suggest_parallel` to determine N for your machine. Each worker needs ~2 CPU cores and ~2 GB of Docker memory.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

### `./find_dependencies_minimal_thorough`

Find and verify the minimum dependencies. Phase 1: greedy for a fast estimate. Phase 2: exhaustive verification of all smaller combinations. Confirms the result is truly minimal.

**Pick this when:** you need a guaranteed minimum and expect the answer to be large (many deps actually needed). Always slower than `./find_dependencies_minimal_greedy` (it runs greedy plus verification); when few deps are needed, `./find_dependencies_minimal_bottom_up` is faster.

    ./find_dependencies_minimal_thorough extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_thorough extensions/Echo
    FAST=1 ./find_dependencies_minimal_thorough extensions/Echo
    PARALLEL=1 ./find_dependencies_minimal_thorough extensions/Echo
    PARALLEL=1 FAST=1 ./find_dependencies_minimal_thorough extensions/Echo

- **Fast for extensions/Echo** (4 deps, 0 needed): greedy finds 0 in ~4 tests, verification confirms immediately.
- **Moderate for extensions/GrowthExperiments** (17 deps, ~8 needed): greedy finds ~8 in ~17 tests, then verifies by testing combinations of size 0–7 only (not all 131,072).

Environment variables:

- `FAST=1`: Runs `./fresh_install` once, saves state, then restores instead of re-running `./fresh_install` for each combination.
- `PARALLEL=N`: Run N combinations simultaneously, each in an isolated `ENVIRONMENT=N` (`src_N/`). Use `./suggest_parallel` to determine N for your machine. Each worker needs ~2 CPU cores and ~2 GB of Docker memory.

**Warning:** This script inhibits sleep to prevent the machine from suspending.

## Commands (all gated repositories)

These scripts operate on all gated extensions and skins (from `./list_gated`). They take a long time to run.

### `./prepare_gated`

Clone or fetch bare repos for all gated repositories. Extends `./prepare` by cloning bare repos for all gated extensions and skins. Assumes `./prepare` has been run first (needs `ref/integration/config.git`). `PARALLEL=N` clones/fetches N repos at a time (default: sequential).

    ./prepare_gated
    PARALLEL=1 ./prepare_gated
    VERBOSE=1 ./prepare_gated

### `./install_all_gated`

Install all gated extensions and skins into a single MediaWiki. Runs `./fresh_install` for core, then installs each gated component on top. Reports per-step and total duration. Unlike `./install_each_gated` (which gives each component its own MediaWiki), this stacks everything into one MediaWiki. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./install_all_gated
    VERBOSE=1 ./install_all_gated

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./install_each_gated`

Install each gated extension or skin into its own fresh MediaWiki, one at a time. For each component: `./fresh_install`, then `./install`. Reports per-step and total duration. Unlike `./install_all_gated` (which stacks everything into one MediaWiki), this gives each component a clean MediaWiki so per-component install times are comparable.

    ./install_each_gated
    ./install_each_gated extensions/Echo
    VERBOSE=1 ./install_each_gated extensions/Echo
    FAST=1 ./install_each_gated extensions/Echo
    PARALLEL=1 ./install_each_gated extensions/Echo
    PARALLEL=1 FAST=1 ./install_each_gated extensions/Echo

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./run_selenium_tests_all_gated`

Run Selenium tests for core and all gated repositories. For each component: `./fresh_install`, `./install` (if not core), check if Selenium tests exist, and run them. Silent by default; use `VERBOSE=1` for full output.

    ./run_selenium_tests_all_gated
    ./run_selenium_tests_all_gated extensions/Echo
    VERBOSE=1 ./run_selenium_tests_all_gated extensions/Echo
    FAST=1 ./run_selenium_tests_all_gated extensions/Echo
    PARALLEL=1 ./run_selenium_tests_all_gated extensions/Echo
    PARALLEL=1 FAST=1 ./run_selenium_tests_all_gated extensions/Echo

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./run_selenium_tests_gated`

Install all gated extensions and skins into a single MediaWiki, then run all Selenium tests. Unlike `./run_selenium_tests_all_gated` (which does `./fresh_install` per component), this installs everything together into one `src/`.

    ./run_selenium_tests_gated

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a long time to run (50+ components).

### `./run_selenium_tests_required_gated`

Run Selenium tests for all gated repositories using only required dependencies (from `extension.json`/`skin.json`). For each component: `./fresh_install`, `./install` with required deps only, check if Selenium tests exist, and run them. Silent by default; use `VERBOSE=1` for full output.

    ./run_selenium_tests_required_gated
    ./run_selenium_tests_required_gated extensions/Echo
    VERBOSE=1 ./run_selenium_tests_required_gated extensions/Echo
    FAST=1 ./run_selenium_tests_required_gated extensions/Echo
    PARALLEL=1 ./run_selenium_tests_required_gated extensions/Echo
    PARALLEL=1 FAST=1 ./run_selenium_tests_required_gated extensions/Echo

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./find_dependencies_minimal_gated`

Find minimum dependencies for all gated repositories (or a single component). For each component: check if Selenium tests exist, check if it has optional dependencies, and run `./find_dependencies_minimal_greedy` to find the minimum set.

    ./find_dependencies_minimal_gated
    ./find_dependencies_minimal_gated extensions/Echo
    VERBOSE=1 ./find_dependencies_minimal_gated extensions/Echo
    FAST=1 ./find_dependencies_minimal_gated extensions/Echo
    PARALLEL=1 ./find_dependencies_minimal_gated extensions/Echo
    PARALLEL=1 FAST=1 ./find_dependencies_minimal_gated extensions/Echo

Environment variables:

- `FAST=1`: Propagated to each `./find_dependencies_minimal_greedy` child. The child runs `./fresh_install` once, saves state, then restores instead of re-running `./fresh_install` for each combination.
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
    DRY_RUN=1 ./generate_examples
    PARALLEL=N ./generate_examples
    PARALLEL=N DRY_RUN=1 ./generate_examples

`PREVIEW`, `DRY_RUN`, and `PARALLEL` do different things:

- `PREVIEW=1 ./generate_examples` — outer-level preview. Prints `Would generate ...` for each Usage line. No files are written, no inner scripts run. Named `PREVIEW`, not `DRY_RUN`, because `PREVIEW` skips execution entirely; [`DRY_RUN`](#dry_run) still runs the wrapper scripts (see below).
- `DRY_RUN=1 ./generate_examples` — actually generate every file, but `DRY_RUN=1` is inherited by every inner Usage command via the env so Quibble short-circuits. Inner scripts that honor `DRY_RUN` (`install`, `fresh_install`, `run_php_unit_tests`, `run_selenium_tests`, and batch scripts that propagate the env var to them via `lib/setup`) finish in seconds instead of minutes. Other scripts ignore the unused env var. This matches how `DRY_RUN` already propagates in `find_dependencies_minimal_*` and other batch scripts.
- `PARALLEL=N ./generate_examples` — run middle-phase Usage lines (not whole scripts) concurrently across N reusable worker slots (`lib/run_pool`): as each line finishes, its slot is refilled, so a script's slow variants spread across slots and no slot idles while work remains. Per-line (not per-script) granularity means the slowest single command — not the slowest script's total across all its variants — bounds the run. Each slot runs in an isolated `ENVIRONMENT=N` (`src_N/`) seeded from the shared `src_save` (so every line runs against a clean baseline), with its own `QUIBBLE_LOG_DIR` (`log/silent/slot-N`) so concurrent batch scripts don't clobber each other's logs. Each worker also unsets `PARALLEL` so a bare inner command captures serial output (an inline `PARALLEL=1 ...` in a Usage line still wins). Early scripts (`prepare`, `prepare_gated`, `fresh_install`, `save`) and late scripts (`remove_srcs`, `remove`, `remove_all`) stay serial — they prepare/destroy state every middle worker depends on. Per-worker output goes to `log/silent/slot-N/`. `PREVIEW=1` forces serial regardless of `PARALLEL` because parallel worker output would interleave unhelpfully when previewing the work plan.

Combinations: `PREVIEW=1 DRY_RUN=1 ./generate_examples` previews the `DRY_RUN` command list (PREVIEW wins — nothing runs). `PARALLEL=N DRY_RUN=1 ./generate_examples` runs the parallel path while short-circuiting Quibble. Use `DRY_RUN=1` to iterate on `generate_examples` itself or to validate the pipeline end-to-end. **Do not commit `examples/*.txt` produced under `DRY_RUN=1` — they do not reflect real script behavior.**

## Internal scripts (`lib/`)

These are sourced by other scripts and are not intended to be run directly.

### `lib/batch_setup`

Shared setup for batch scripts (`test_integration`, `test_integration_slow`, `install_all_gated`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, `find_dependencies_minimal_thorough`). Sets up verbose/silent mode, sources helper libraries (`inhibit_sleep`, `print_results`, `heartbeat`), creates log directory, and initializes result tracking variables. Defines and exports `QUIBBLE_LOG_DIR` (default `log/silent`), the directory for silent-mode per-step log files; the startup cleanup, `run_step`, `lib/run_test`, and `lib/minimal_setup` all write there. A parent that runs batch scripts concurrently (e.g. `generate_examples`' pool workers) overrides it per worker (e.g. `log/silent/slot-3`) so concurrent workers don't clobber each other's logs or delete a log a sibling is reading back. The user-facing "logs:" hint stays the canonical `log/silent/` (not the per-worker path) so it can't leak into captured `examples/`.

### `lib/heartbeat`

Run a command, save output to a log file, and print a dot for each line of output. Sourced by `test_integration`, `test_integration_slow`, `install_all_gated`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, and `find_dependencies_minimal_thorough` for silent mode progress feedback. Provides `run_with_dots` function.

### `lib/debug_info`

Outputs debug information (OS, CPU, RAM, bash, git, docker version, docker CPUs and RAM), checks basic prerequisites (git), shows a "use VERBOSE=1 for full output" hint in silent mode, and sets up duration tracking via `lib/duration_trap`. Sourced by most scripts, except the data scripts (`list_dependencies`, `list_dependencies_combinations`, `list_gated`, `list_dependencies_optional`, `list_dependencies_required`, `selenium_tests_exist`) whose stdout is consumed by other scripts and would be corrupted by debug output.

### `lib/format_duration`

Provides `_quibble_format_duration` function that formats elapsed seconds as a human-readable duration string (e.g. "1h 5m 30s"). Omits zero-value days, hours, and minutes; always shows seconds. Gated on the `TIME_ELAPSED` environment variable: off by default (returns empty), set `TIME_ELAPSED=1` to enable. Sourced by `lib/duration_trap` and `lib/batch_setup`.

### `lib/pluralize`

Provides the `pluralize` function that returns the singular or plural form of a word for a given count, so counts read grammatically (e.g. "1 worker" vs "2 workers"). Usage: `pluralize COUNT SINGULAR [PLURAL]`; `PLURAL` defaults to `SINGULAR` + "s", or pass it explicitly for irregular words. Sourced by `lib/run_pool`, `lib/greedy`, `find_dependencies_minimal_gated`, and `find_dependencies_minimal_thorough`.

### `lib/exit_trap`

Composable EXIT-trap registry. Bash allows only one handler per signal, so a second `trap ... EXIT` replaces the first; this installs a single dispatcher and runs every registered handler, in registration order, preserving the script's exit code. Handlers are keyed, so registering an existing key replaces it (the mutually-exclusive display handlers `lib/duration_trap` and `lib/silent_output` share the `display` key — last wins) while a cleanup handler under its own key always runs too. This is what stops `lib/duration_trap` from clobbering `lib/inhibit_sleep`'s cleanup. Provides `quibble_register_exit_trap`. Sourced by `lib/inhibit_sleep`, `lib/duration_trap`, and `lib/silent_output`.

### `lib/duration_trap`

Registers (via `lib/exit_trap`, under the shared `display` key) an EXIT handler that prints total script duration when the script exits. Only activates when stdout is a terminal. Output is empty unless `TIME_ELAPSED=1`. Sources `lib/format_duration` and `lib/exit_trap`. Sourced by `lib/debug_info`, `lib/batch_setup`, and `lint`. `lib/silent_output` registers the same `display` key, so when both are sourced its handler replaces this one.

### `lib/setup`

Shared setup sourced by scripts that run Docker commands. Sources `lib/debug_info` for debug output, checks Docker prerequisites (docker installed, Docker daemon running), sources `lib/default_image` and exports `QUIBBLE_IMAGE` (defaulting to `QUIBBLE_DEFAULT_IMAGE`) and `QUIBBLE_VOLUMES`, sets a custom debug prompt, enables trace output (`set -x`), and sources `lib/silent_output` for output redirection.

### `lib/default_image`

Single source of truth for the default Quibble Docker image, as `QUIBBLE_DEFAULT_IMAGE`. Sourced by `lib/setup` to seed `QUIBBLE_IMAGE` for the user-facing scripts. To move to a newer image (e.g. a new Debian base), edit only this file. Override at runtime with `QUIBBLE_IMAGE`.

### `lib/silent_output`

Output redirection for silent mode. Saves all output to a log file (e.g. `log/fresh_install.log`) and prints a dot per line to the terminal. On success the progress dots are the only feedback (optionally followed by the elapsed time when `TIME_ELAPSED=1`); on failure it prints "FAIL" with the log file path. Registers its exit handler via `lib/exit_trap` under the shared `display` key, replacing `lib/duration_trap`'s handler. Sourced by `lib/setup`.

### `lib/docker_chmod`

Provides `docker_chmod` function that sets directories to world-writable (`chmod 777`), falling back to Docker-as-root when directories are owned by root from previous container runs. Sourced by `fresh_install`, `save`, and `restore`.

### `lib/checkout_branch`

Provides the `checkout_branch` function: after a Quibble run, checks out the branch named by `BRANCH` in the MediaWiki repos under `src/` (core, `vendor`, skins, extensions), so they end up on a named branch instead of Quibble's detached `HEAD`. No-op unless `BRANCH` is set (and skipped when `DRY_RUN=1`). Runs the re-attach inside the Quibble image as the file-owning user — so host UID and file ownership don't matter, the same reason `./remove` and `lib/docker_chmod` use Docker; the git logic lives in `lib/checkout_branch_worker`. Sourced by `fresh_install` and `install`.

### `lib/checkout_branch_worker`

The git logic run by `lib/checkout_branch`, executed inside the Quibble Docker container (mounted read-only), not sourced. Walks the MediaWiki layout (core, `vendor`, `skins/*`, `extensions/*`) and, for each repo still in detached `HEAD`, checks out the requested branch — falling back to the repo's own default branch (`origin/HEAD`) when it lacks the requested one, mirroring Quibble's fallback. Exits non-zero if any detached repo can't be put on a branch, so an unmet `BRANCH` request fails the run rather than being silently ignored. Kept as a separate file so it can be unit-tested with Bats on the host without Docker.

### `lib/print_quibble_command`

Provides `print_quibble_command` function that pretty-prints a docker command with one logical option per line, framed by a `#` banner so it stands out in busy logs. Flag-and-value pairs stay on the same line and continuation backslashes make the output a valid copy-pasteable shell command. Sourced by `fresh_install`, `install`, `shellto`, and `lib/run_quibble_test`.

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

Sourced by long-running scripts (`find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, `find_dependencies_minimal_gated`, `find_dependencies_minimal_thorough`, `install_all_gated`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `test_integration`, `test_integration_slow`, `generate_examples`) to prevent the machine from suspending. Uses `caffeinate` on macOS and `systemd-inhibit` on Linux. On Linux it registers its cleanup via `lib/exit_trap` (under its own key) so a later-sourced EXIT handler such as `lib/duration_trap` cannot clobber it.

### `lib/print_results`

Sourced by scripts that track test/step results (`install_all_gated`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_gated`, `run_selenium_tests_required_gated`, `find_dependencies_minimal_gated`, `test_integration`, `test_integration_slow`). Provides `print_results` function that prints pass/fail summary and exits with error if any failures.

### `lib/utc_timestamp`

Provides `utc_timestamp` function that prints the current UTC time in `YYYY-MM-DD HH:MM:SS UTC` format. Gated on the `TIME_UTC` environment variable: off by default, set `TIME_UTC=1` to enable. Sourced by `lib/batch_setup`.

### `lib/print_header`

Provides `print_header` function that prints a section header for a component in batch scripts. In verbose mode: separator box with label (and a UTC timestamp when `TIME_UTC=1`). In silent mode: label followed by a space. Sourced by `lib/batch_setup`.

### `lib/record_passed`

Provides `record_passed` function that records a component as passed (if not already in the failed list). Sourced by `lib/batch_setup`.

### `lib/run_test`

Provides `run_test` function and `test_counter` for `test_integration`-style scripts. Runs a command, prints what it does, and records pass/fail in `$passed`/`$failed`. In verbose mode prints a separator box and full output; in silent mode saves output to a numbered log file (e.g. `log/silent/01-help.log`) and prints a dot per line. Must be sourced after `lib/batch_setup`. Sourced by `test_integration` and `test_integration_slow`.

### `lib/run_pool`

Generic dynamic worker pool: keeps `$parallel` reusable slots busy and refills each slot the instant its item finishes, so one slow item never idles the rest. The caller sets `items[]` and `parallel` and defines `_run_pool_worker SLOT ITEM INDEX` (runs in a background subshell; `SLOT` is a stable `1..parallel` id reused as items complete, for per-slot isolation; `INDEX` is the item's 0-based position in `items[]`), plus optional `_pool_worker_label` (custom per-dispatch progress line) and `_pool_reap SLOT ITEM INDEX` (called the instant a slot's item finishes, so a caller can surface results live rather than after the pool drains) hooks. A caller may also set `_quibble_run_pool_stop` (e.g. inside `_pool_reap`) to stop dispatching new items and drain the in-flight slots — the ordered-search early exit used by `lib/parallel`. Because bash 3.2 has no `wait -n`, completion is detected via a per-slot sentinel file written by an `EXIT` trap inside each worker and polled (interval overridable with `_QUIBBLE_POOL_POLL_SECONDS`, default 1s); the sentinel temp dir is removed on normal completion and via an `INT`/`TERM` trap. Sourced by `generate_examples`, `find_dependencies_minimal_gated`, `install_each_gated`, `run_selenium_tests_all_gated`, `run_selenium_tests_required_gated`, and `lib/parallel` in parallel mode.

### `lib/run_waves`

Bounded-concurrency wave runner: runs independent background jobs `$parallel` at a time, waiting for each full wave before launching the next and draining the final partial wave. A job that exits non-zero only warns (it never aborts the run). The caller sets `items[]` and `parallel` and defines `_run_waves_job ITEM` (run in the background by the helper). Simpler than `lib/run_pool` (no dynamic refill, sentinel polling, or per-slot `src_N` isolation) — a good fit for short, uniform jobs like git clone/fetch. Sourced by `fetch` in parallel mode.

### `lib/heavy_scripts`

Curated list of the heaviest middle scripts (defines `_quibble_heavy_scripts`, most-expensive first), used only as a scheduling hint by `generate_examples`' parallel pool: their Usage lines are dispatched before everything else so the long-running jobs start immediately and the many short jobs backfill the tail, keeping every worker slot busy to the end. Best-effort hint only — `lib/run_pool` is correct in any order, so a stale or missing entry only costs a little scheduling efficiency. Sourced by `generate_examples` in parallel mode.

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

### `lib/scrub_pwd.awk`

Awk script that replaces literal occurrences of the project's absolute path (`$PWD`) with the placeholder `$PWD`, keeping captured output in `examples/*.txt` machine-independent so the files don't churn when regenerated on different machines. Used by `generate_example`.

### `lib/scrub_ansi.awk`

Awk script that strips ANSI CSI escape sequences (color codes like `[33m`, cursor moves like `[2K`) from captured output. Tools running inside the Quibble image (colorlog, composer, npm) emit these when they think their stdout is a terminal; without scrubbing they land in `examples/*.txt` as literal escape sequences and make the files noisy to read and to diff. Used by `generate_example`.

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

Parallel exhaustive search for the minimum dependencies, built on `lib/run_pool`: dispatches size-ordered combinations across N reusable slots, each in an isolated `src_N/` directory (`ENVIRONMENT=N`). The lowest-index passing combination is the minimum, so it sets `lib/run_pool`'s `_quibble_run_pool_stop` on the first pass and takes the lowest passing index across the drained in-flight slots as the winner. Defines run_pool's worker/label/reap hooks; cleanup and the `INT`/`TERM` trap come from `run_pool`. Sourced by `find_dependencies_minimal_bottom_up` and `find_dependencies_minimal_thorough` when `PARALLEL` ≥ 1.

### `lib/print_found`

Prints the "minimum dependencies found" results (header, required deps, optional deps). Sourced by `find_dependencies_minimal_greedy`, `find_dependencies_minimal_bottom_up`, and `find_dependencies_minimal_thorough`.

### `lib/extract_found_block.awk`

Awk script that extracts the "FOUND: minimum dependencies" block (produced by `lib/print_found`) from a `find_dependencies_minimal_*` log file, stopping before the trailing duration line added by `lib/duration_trap`. Used by `find_dependencies_minimal_gated`.

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
