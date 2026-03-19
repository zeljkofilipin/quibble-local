# quibble-local

Simple wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) locally via Docker.

Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart), using the same one-file-per-command convention.

## Prerequisites

- [Bash](https://www.gnu.org/software/bash/)
- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)
- [ShellCheck](https://www.shellcheck.net/) (optional, for linting)

## Commands

### `./prepare`

Prepare the local environment for running Quibble. Pulls the Docker image, clones bare git repos as references, and creates working directories.

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./fresh_install`

Set up MediaWiki (without running tests) and open a shell. MediaWiki will be available at http://127.0.0.1:9413. Runs `./prepare` first if needed, then `./clean` to ensure a fresh `src/`.

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./install`

Install an extension or skin and open a shell. MediaWiki will be available at http://127.0.0.1:9413. Assumes `./fresh_install` has been run first.

    ./install extensions/Echo
    ./install skins/MinervaNeue

See: [Install MediaWiki Core and an Extension](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core_and_an_Extension)

### `./run_all`

Run Selenium tests for core and all gated repositories. For each component: `./fresh_install`, `./install` (if not core), check if Selenium tests exist, and run them.

**Warning:** This script inhibits sleep to prevent the machine from suspending. This will take a very long time to run (50+ components).

### `./run_selenium_tests`

Run Selenium tests. Assumes `./fresh_install` (or `./install`) has been run first.

    ./run_selenium_tests
    ./run_selenium_tests extensions/Echo
    ./run_selenium_tests --spec tests/selenium/specs/page.js
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js
    ./run_selenium_tests --spec tests/selenium/specs/user.js --mochaOpts.grep "should be able to create account"
    ./run_selenium_tests extensions/Echo --spec tests/selenium/specs/notifications.js --mochaOpts.grep "alerts and notices are visible"

See: [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

### `./fetch`

Fetch the latest changes for all bare git repos in `ref/` from Gerrit.

### `./dependencies`

Output dependencies for an extension or skin from `zuul/dependencies.yaml`.

    ./dependencies extensions/Echo
    ./dependencies skins/MinervaNeue

### `./gated`

Output the list of gated repositories (extensions and skins) from `parameter_functions.py`. Clones `integration/config` into `src/config` if needed. Assumes `./prepare` has been run first.

### `./help`

List all scripts with their description and usage.

### `./selenium_tests_exist`

Check if a component has Selenium tests. Exits 0 if yes, 1 if no.

    ./selenium_tests_exist
    ./selenium_tests_exist extensions/Echo

### `./shellto`

Open a shell in the container with MediaWiki running at http://127.0.0.1:9413. Assumes `./fresh_install` (or `./install`) has been run first.

### `./clean`

Remove `src/` (MediaWiki source code). Cache, logs, bare git repos, and the Docker image are kept.

### `./deep_clean`

Remove everything created by quibble-local, including bare git repos in `ref/` and the Docker image.

### `./lint`

Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts in the repo.

### `./test`

Run all scripts and report which ones passed or failed. Useful for detecting regressions after changes.

### `./deep_test`

Run `./deep_clean` first, then `./test`. Slower but starts from a completely clean state.

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
