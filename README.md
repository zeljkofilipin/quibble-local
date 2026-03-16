# quibble-local

Simple wrapper scripts for running [Quibble](https://doc.wikimedia.org/quibble/) locally via Docker.

Inspired by [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart), using the same one-file-per-command convention.

## Prerequisites

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)

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

### `./run_selenium_tests`

Run Selenium tests. Assumes `./fresh_install` (or `./install`) has been run first.

    ./run_selenium_tests
    ./run_selenium_tests extensions/Echo

See: [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

### `./fetch`

Fetch the latest changes for all bare git repos in `ref/` from Gerrit.

### `./clean`

Remove `src/` (MediaWiki source code). Cache, logs, bare git repos, and the Docker image are kept.

### `./deep_clean`

Remove everything created by quibble-local, including bare git repos in `ref/` and the Docker image.

### `./lint`

Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts in the repo.

### `./test`

Run all scripts and report which ones passed or failed. Useful for detecting regressions after changes.

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
