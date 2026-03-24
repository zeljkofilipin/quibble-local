# quibble-local

Simple wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) locally via Docker.

Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart), using the same one-file-per-command convention.

## Prerequisites

- [Bash](https://www.gnu.org/software/bash/)
- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)
- [ShellCheck](https://www.shellcheck.net/) (optional, for linting)

## Silent and verbose modes

All commands run in **silent mode** by default (no trace output, no debug info). Use `--verbose` for full output including trace output (`set -x`) and debug info.

    ./fresh_install            # silent (default)
    ./fresh_install --verbose  # verbose (trace output)

When commands are called from `test` or `run_all`, the mode is inherited via the `QUIBBLE_VERBOSE` environment variable.

## Commands (same as mediawiki-quickstart)

### `./fresh_install`

Set up MediaWiki (without running tests) and open a shell. MediaWiki will be available at http://127.0.0.1:9413. Runs `./prepare` first if needed, then `./clean` to ensure a fresh `src/`.

    ./fresh_install
    ./fresh_install --verbose

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./install`

Install an extension or skin and open a shell. MediaWiki will be available at http://127.0.0.1:9413. Assumes `./fresh_install` has been run first.

    ./install extensions/Echo
    ./install skins/MinervaNeue
    ./install --verbose extensions/Echo

See: [Install MediaWiki Core and an Extension](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core_and_an_Extension)

### `./run_selenium_tests`

Run Selenium tests. Assumes `./fresh_install` (or `./install`) has been run first.

    ./run_selenium_tests
    ./run_selenium_tests extensions/Echo
    ./run_selenium_tests --spec tests/selenium/specs/page.js
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js
    ./run_selenium_tests --spec tests/selenium/specs/user.js --mochaOpts.grep "should be able to create account"
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js --mochaOpts.grep "alerts and notices are visible"
    ./run_selenium_tests --verbose extensions/Echo

See: [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

### `./shellto`

Open a shell in the container with MediaWiki running at http://127.0.0.1:9413. Assumes `./fresh_install` (or `./install`) has been run first.

    ./shellto
    ./shellto --verbose

### `./test`

Run all scripts and report which ones passed or failed. Useful for detecting regressions after changes. Silent by default; use `--verbose` for full output.

    ./test
    ./test --verbose

**Warning:** This script inhibits sleep to prevent the machine from suspending.

## Commands (unique to quibble-local)

### `./prepare`

Prepare the local environment for running Quibble. Pulls the Docker image, clones bare git repos as references, and creates working directories.

    ./prepare
    ./prepare --verbose

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./run_all`

Run Selenium tests for core and all gated repositories. For each component: `./fresh_install`, `./install` (if not core), check if Selenium tests exist, and run them. Silent by default; use `--verbose` for full output.

    ./run_all
    ./run_all --verbose

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./fetch`

Fetch the latest changes for all bare git repos in `ref/` from Gerrit.

    ./fetch
    ./fetch --verbose

### `./dependencies`

Output dependencies for an extension or skin from `zuul/dependencies.yaml`.

    ./dependencies extensions/Echo
    ./dependencies skins/MinervaNeue
    ./dependencies --verbose extensions/Echo

### `./gated`

Output the list of gated repositories (extensions and skins) from `parameter_functions.py`. Clones `integration/config` into `src/config` if needed. Assumes `./prepare` has been run first.

    ./gated
    ./gated --verbose

### `./help`

List all scripts with their description and usage.

    ./help
    ./help --verbose

### `./selenium_tests_exist`

Check if a component has Selenium tests. Exits 0 if yes, 1 if no.

    ./selenium_tests_exist
    ./selenium_tests_exist extensions/Echo
    ./selenium_tests_exist --verbose extensions/Echo

### `./clean`

Remove `src/` (MediaWiki source code). Cache, logs, bare git repos, and the Docker image are kept.

    ./clean
    ./clean --verbose

### `./deep_clean`

Remove everything created by quibble-local, including bare git repos in `ref/` and the Docker image.

    ./deep_clean
    ./deep_clean --verbose

### `./ci`

Run the same lint check that GitLab CI runs, using Docker. Does not require ShellCheck to be installed locally.

    ./ci
    ./ci --verbose

### `./lint`

Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts in the repo.

    ./lint
    ./lint --verbose

### `./deep_test`

Run `./deep_clean` first, then `./test`. Slower but starts from a completely clean state.

    ./deep_test
    ./deep_test --verbose

**Warning:** This script inhibits sleep to prevent the machine from suspending (via `./test`).

## Internal scripts (`lib/`)

These are sourced by other scripts and are not intended to be run directly.

### `lib/verbose`

Parse `--verbose` flag and set `QUIBBLE_VERBOSE` environment variable. Silent mode (default) suppresses trace output and debug info. If `QUIBBLE_VERBOSE` is already set by a parent script (e.g. `test`, `run_all`), that value is kept. Removes `--verbose` from the argument list. Sourced by all scripts as the first `lib/` include.

### `lib/heartbeat`

Run a command, save output to a log file, and print a dot for each line of output. Sourced by `test` and `run_all` for silent mode progress feedback. Provides `run_with_dots` function.

### `lib/debug_info`

Checks prerequisites (git, docker, Docker daemon running) and outputs debug information (OS, bash, git, docker versions). Sourced by `lib/setup` (for scripts that run Docker commands) and by `test`/`run_all` (which skip `lib/setup` but still want debug info in silent mode).

### `lib/setup`

Shared setup sourced by scripts that run Docker commands. Sources `lib/debug_info` for prerequisites and debug output, exports `QUIBBLE_IMAGE` and `QUIBBLE_VOLUMES`, sets a custom debug prompt, and enables trace output (`set -x`).

### `lib/ensure_config`

Sourced by scripts that need zuul config (`gated`, `install`). Ensures the `integration/config` working copy exists in `src/config` by cloning from the bare repo.

### `lib/inhibit_sleep`

Sourced by long-running scripts (`run_all`, `test`) to prevent the machine from suspending. Uses `caffeinate` on macOS and `systemd-inhibit` on Linux.

### `lib/print_results`

Sourced by scripts that track test/step results (`run_all`, `test`). Provides `print_results` function that prints pass/fail summary and exits with error if any failures.

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
