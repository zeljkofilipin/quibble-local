# quibble-local

Simple wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) locally via Docker.

Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart), using the same one-file-per-command convention.

## Prerequisites

- [Bash](https://www.gnu.org/software/bash/)
- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)
- [ShellCheck](https://www.shellcheck.net/) (optional, for linting)
- [Bats](https://github.com/bats-core/bats-core) (optional, for unit tests)

## Environment variables

### `VERBOSE`

All commands run in **silent mode** by default (no trace output, no debug info). Use `VERBOSE=1` for full output including trace output (`set -x`) and debug info.

    ./fresh_install            # silent (default)
    VERBOSE=1 ./fresh_install  # verbose (trace output)

When commands are called from `integration_test` or `run_all`, the mode is inherited via the `VERBOSE` environment variable.

### `FAST`

`FAST=1` runs `./fresh_install` once, saves the state with `./save`, then uses `./restore` instead of re-running `./fresh_install` for each subsequent component. Used by `run_all`, `run_required`, and `minimal_dependencies`.

    FAST=1 ./run_all
    FAST=1 ./minimal_dependencies extensions/Echo

## Commands (same as mediawiki-quickstart)

### `./fresh_install`

Set up MediaWiki (without running tests). Runs `./prepare` first if needed, then `./clean` to ensure a fresh `src/`. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./fresh_install
    VERBOSE=1 ./fresh_install

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./install`

Install an extension or skin. Assumes `./fresh_install` has been run first. Run `./shellto` afterwards to open a shell with MediaWiki running.

    ./install extensions/Echo
    ./install skins/MinervaNeue
    VERBOSE=1 ./install extensions/Echo
    QUIBBLE_DEPS="" ./install extensions/Echo                    # no dependencies
    QUIBBLE_DEPS="EventLogging" ./install extensions/Echo        # only specific dependencies

See: [Install MediaWiki Core and an Extension](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core_and_an_Extension)

### `./run_selenium_tests`

Run Selenium tests. Assumes `./fresh_install` (or `./install`) has been run first.

    ./run_selenium_tests
    ./run_selenium_tests extensions/Echo
    ./run_selenium_tests --spec tests/selenium/specs/page.js
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js
    ./run_selenium_tests --spec tests/selenium/specs/user.js --mochaOpts.grep "should be able to create account"
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js --mochaOpts.grep "alerts and notices are visible"
    VERBOSE=1 ./run_selenium_tests extensions/Echo

See: [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

### `./shellto`

Open a shell in the container with MediaWiki running at http://127.0.0.1:9413. Assumes `./fresh_install` (or `./install`) has been run first.

    ./shellto
    VERBOSE=1 ./shellto

### `./integration_test`

Run all scripts and report which ones passed or failed. Useful for detecting regressions after changes. Silent by default; use `VERBOSE=1` for full output.

    ./integration_test
    VERBOSE=1 ./integration_test

**Warning:** This script inhibits sleep to prevent the machine from suspending.

### `./unit_test`

Run Bats unit tests. Fast, no Docker needed. Requires Bats in addition to the base prerequisites.

    ./unit_test
    ./unit_test test/lib_awk.bats  # run a single test file

## Commands (unique to quibble-local)

### `./prepare`

Prepare the local environment for running Quibble. Pulls the Docker image, clones bare git repos as references, and creates working directories.

    ./prepare
    VERBOSE=1 ./prepare

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./run_all`

Run Selenium tests for core and all gated repositories. For each component: `./fresh_install`, `./install` (if not core), check if Selenium tests exist, and run them. Silent by default; use `VERBOSE=1` for full output.

    ./run_all
    VERBOSE=1 ./run_all
    FAST=1 ./run_all

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./fetch`

Fetch the latest changes for all bare git repos in `ref/` from Gerrit.

    ./fetch
    VERBOSE=1 ./fetch

### `./dependencies`

Output dependencies for an extension or skin from `zuul/dependencies.yaml`.

    ./dependencies extensions/Echo
    ./dependencies skins/MinervaNeue
    VERBOSE=1 ./dependencies extensions/Echo

### `./dependency_combinations`

Output all possible combinations of dependencies for an extension or skin. One combination per line (space-separated), starting with one dependency, ending with all dependencies.

    ./dependency_combinations extensions/Echo
    ./dependency_combinations skins/MinervaNeue

### `./gated`

Output the list of gated repositories (extensions and skins) from `parameter_functions.py`. Clones `integration/config` into `src/config` if needed. Assumes `./prepare` has been run first.

    ./gated
    VERBOSE=1 ./gated

### `./run_required`

Run Selenium tests for all gated repositories using only required dependencies (from `extension.json`/`skin.json`). For each component: `./fresh_install`, `./install` with required deps only, check if Selenium tests exist, and run them. Silent by default; use `VERBOSE=1` for full output.

    ./run_required
    VERBOSE=1 ./run_required
    FAST=1 ./run_required

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./required_dependencies`

Output required dependencies for an extension or skin from its `extension.json` or `skin.json`. These are the extensions/skins listed in the `requires` field that must always be present.

    ./required_dependencies extensions/GrowthExperiments
    ./required_dependencies skins/MinervaNeue

### `./optional_dependencies`

Output optional dependencies for an extension or skin. These are dependencies in `zuul/dependencies.yaml` that are NOT in `extension.json`/`skin.json` `requires` field. Complement of `./required_dependencies`.

    ./optional_dependencies extensions/Echo
    ./optional_dependencies skins/MinervaNeue

### `./suggested_parallel`

Suggest the number of parallel workers for `./minimal_dependencies` based on available CPU and memory. Each worker needs ~2 CPU cores and ~2 GB of Docker memory. Outputs a single number.

    ./suggested_parallel
    PARALLEL=$(./suggested_parallel) ./minimal_dependencies extensions/Echo

### `./minimal_dependencies`

Find the minimum dependencies needed for a repository's Selenium tests to pass. Splits dependencies into required (from `extension.json`/`skin.json`) and optional (remaining). Required deps are always included; only optional deps are varied, testing combinations from smallest (0 optional) to largest (all optional).

    ./minimal_dependencies extensions/Echo
    VERBOSE=1 ./minimal_dependencies extensions/Echo
    FAST=1 ./minimal_dependencies extensions/Echo
    GREEDY=1 ./minimal_dependencies extensions/Echo
    GREEDY=1 FAST=1 ./minimal_dependencies extensions/Echo
    PARALLEL=$(./suggested_parallel) ./minimal_dependencies extensions/Echo
    PARALLEL=4 FAST=1 ./minimal_dependencies extensions/Echo

`GREEDY=1` starts with all dependencies and removes one at a time (O(N) instead of O(2^N)). Finds a minimal set but not necessarily the smallest possible. Combine with `FAST=1` for maximum speed.

`PARALLEL=N` runs N combinations simultaneously, each in an isolated `src_worker_$i/` directory. Use `./suggested_parallel` to determine N for your machine. Each worker needs ~2 CPU cores and ~2 GB of Docker memory.

**Warning:** Tests up to 2^N combinations (N = number of optional dependencies). Each takes ~10 minutes. This script inhibits sleep to prevent the machine from suspending.

### `./help`

List all scripts with their description and usage.

    ./help
    VERBOSE=1 ./help

### `./selenium_tests_exist`

Check if a component has Selenium tests. Exits 0 if yes, 1 if no.

    ./selenium_tests_exist
    ./selenium_tests_exist extensions/Echo
    VERBOSE=1 ./selenium_tests_exist extensions/Echo

### `./save`

Save the current state of `src/` (MediaWiki installation) for fast restore later. Uses Docker-as-root to copy files (works on both macOS and Linux).

    ./save
    VERBOSE=1 ./save

### `./restore`

Restore `src/` from a previously saved state (created by `./save`). Much faster than running `./fresh_install` again.

    ./restore
    VERBOSE=1 ./restore

### `./clean`

Remove `src/` (MediaWiki source code). Cache, logs, bare git repos, and the Docker image are kept.

    ./clean
    VERBOSE=1 ./clean

### `./deep_clean`

Remove everything created by quibble-local, including bare git repos in `ref/` and the Docker image.

    ./deep_clean
    VERBOSE=1 ./deep_clean

### `./ci`

Run the same lint check that GitLab CI runs, using Docker. Does not require ShellCheck to be installed locally.

    ./ci
    VERBOSE=1 ./ci

### `./lint`

Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts in the repo. Requires ShellCheck in addition to the base prerequisites.

    ./lint
    VERBOSE=1 ./lint

### `./deep_clean_test`

Run `./deep_clean` first, then `./integration_test`. Slower but starts from a completely clean state.

    ./deep_clean_test
    VERBOSE=1 ./deep_clean_test

**Warning:** This script inhibits sleep to prevent the machine from suspending (via `./integration_test`).

## Internal scripts (`lib/`)

These are sourced by other scripts and are not intended to be run directly.

### `lib/batch_setup`

Shared setup for batch scripts (`integration_test`, `run_all`, `run_required`, `minimal_dependencies`). Sets up verbose/silent mode, sources helper libraries (`inhibit_sleep`, `print_results`, `heartbeat`), creates log directory, and initializes result tracking variables.

### `lib/heartbeat`

Run a command, save output to a log file, and print a dot for each line of output. Sourced by `integration_test`, `run_all`, `run_required`, and `minimal_dependencies` for silent mode progress feedback. Provides `run_with_dots` function.

### `lib/debug_info`

Outputs debug information (OS, bash, git, docker versions), checks basic prerequisites (git), shows a "use VERBOSE=1 for full output" hint in silent mode, and sets up duration tracking via `lib/duration_trap`. Sourced by all scripts.

### `lib/format_duration`

Provides `_quibble_format_duration` function that formats elapsed seconds as a human-readable duration string (e.g. "1h 5m 30s"). Omits zero-value days, hours, and minutes; always shows seconds. Sourced by `lib/duration_trap` and `lib/batch_setup`.

### `lib/duration_trap`

Sets an EXIT trap to print total script duration when the script exits. Only activates when stdout is a terminal. Sources `lib/format_duration`. Sourced by `lib/debug_info`, `lib/batch_setup`, and `lint`. `lib/silent_output` overrides this trap with its own handler that also includes duration.

### `lib/setup`

Shared setup sourced by scripts that run Docker commands. Sources `lib/debug_info` for debug output, checks Docker prerequisites (docker installed, Docker daemon running), exports `QUIBBLE_IMAGE` and `QUIBBLE_VOLUMES`, sets a custom debug prompt, enables trace output (`set -x`), and sources `lib/silent_output` for output redirection.

### `lib/silent_output`

Output redirection for silent mode. Saves all output to a log file (e.g. `log/fresh_install.log`) and prints a dot per line to the terminal. On exit, prints "ok" or "FAIL" with elapsed time and the log file path. Sourced by `lib/setup`.

### `lib/resolve_deps`

Resolves dependency repos for a component, cloning bare repos as needed. Sets the `deps` array with repo paths. Reads from `QUIBBLE_DEPS` env var if set, otherwise from `./dependencies`. Sourced by `install`.

### `lib/ensure_config`

Sourced by scripts that need zuul config (`dependencies`, `gated`, `install`). Ensures the `integration/config` working copy exists in `src/config` by cloning from the bare repo.

### `lib/inhibit_sleep`

Sourced by long-running scripts (`minimal_dependencies`, `run_all`, `run_required`, `integration_test`) to prevent the machine from suspending. Uses `caffeinate` on macOS and `systemd-inhibit` on Linux.

### `lib/print_results`

Sourced by scripts that track test/step results (`run_all`, `run_required`, `integration_test`). Provides `print_results` function that prints pass/fail summary and exits with error if any failures.

### `lib/parse_requires.awk`

Awk script that parses `requires.extensions` and `requires.skins` from `extension.json` or `skin.json`. Used by `required_dependencies`.

### `lib/combinations.awk`

Awk script that generates all bitmask combinations of dependencies, ordered by size (starting from 1). Used by `dependency_combinations`.

### `lib/combinations_with_empty.awk`

Awk script that generates all bitmask combinations including the empty set, ordered by size (starting from 0). Used by `minimal_dependencies`.

### `lib/parse_yaml_list.awk`

Awk script that parses a YAML list under a given key from `zuul/dependencies.yaml`. Used by `dependencies`.

### `lib/parse_python_list.awk`

Awk script that extracts entries from a Python list assignment in `parameter_functions.py`. Used by `gated`.

### `lib/print_dep_summary`

Prints a summary of all, required, and optional dependencies plus total combinations to test. Sourced by `minimal_dependencies`.

### `lib/build_full_combo`

Builds a full dependency combination from required + optional deps. Sets the `full_combo` variable. Sourced by `minimal_dependencies`.

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
