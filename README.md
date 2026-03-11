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

Set up MediaWiki (without running tests) and open a shell. MediaWiki will be available at http://127.0.0.1:9413. Runs `./prepare` first if needed.

See: [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core)

### `./install`

Install an extension or skin and open a shell. MediaWiki will be available at http://127.0.0.1:9413. Assumes `./fresh_install` has been run first.

    ./install extensions/Echo
    ./install skins/MinervaNeue

See: [Install MediaWiki Core and an Extension](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core_and_an_Extension)

### `./fetch`

Fetch the latest changes for all bare git repos in `ref/` from Gerrit.

### `./clean`

Clean up working directories created by `./prepare`. Bare git repos in `ref/` are kept since they are slow to re-clone (use `./fetch` to update them).

To also remove bare repos: `rm -rf ref`

Note: The Docker image pulled by `./prepare` is not removed. To remove it:

    docker rmi docker-registry.wikimedia.org/releng/quibble-bullseye-php83:latest

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
