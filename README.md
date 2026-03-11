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

## Further reading

- [Quibble documentation](https://doc.wikimedia.org/quibble/)
- [Continuous integration/Quibble](https://www.mediawiki.org/wiki/Continuous_integration/Quibble)
- [Run tests targeting Quibble](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble)

## License

[MIT](LICENSE)
