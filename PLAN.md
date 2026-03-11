# Plan: quibble-local scripts

## Context

Create a tool that simplifies running Quibble (MediaWiki CI test runner) locally via Docker. The CLI follows [mediawiki-quickstart](https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart) conventions — one file per command, same command names where applicable.

Quibble differs from quickstart: it uses a single one-shot Docker container (not docker-compose), so some quickstart commands don't apply.

## Files to create

### 1. `config` (sourced by all scripts, not executable)

Shared configuration and helpers:
- `QUIBBLE_IMAGE` — default: `docker-registry.wikimedia.org/releng/quibble-bullseye-php83:latest`
- `QUIBBLE_DIR` — resolved via `BASH_SOURCE[0]` to repo root
- `REF_DIR`, `CACHE_DIR`, `LOG_DIR`, `SRC_DIR`
- `GERRIT_URL` — `https://gerrit.wikimedia.org/r`
- Platform detection: `-p 9413:9413` on macOS, `--network host` on Linux
- `ensure_dirs()` — create cache/, log/, src/ with chmod 777
- `clone_ref()` — clone a bare repo into ref/ if not present
- `quibble_run()` — common `docker run` with all volume mounts, accepts docker args before `--` and quibble args after

### 2. `fresh_install`

Setup Quibble locally (everything from [Install MediaWiki Core](https://www.mediawiki.org/wiki/Selenium/How-to/Run_tests_targeting_Quibble#Install_MediaWiki_Core) except running the docker command): `./fresh_install`
1. Pull Docker image (`docker pull`)
2. Create directories: ref/mediawiki/skins, cache, log, src
3. `chmod 777 cache log src`
4. Clone bare repos:
   - `git clone --bare .../mediawiki/core ref/mediawiki/core.git`
   - `git clone --bare .../mediawiki/vendor ref/mediawiki/vendor.git`
   - `git clone --bare .../mediawiki/skins/Vector ref/mediawiki/skins/Vector.git`
5. Does NOT run the docker command (that's what `install` or test scripts do)

### 3. `install`

Install extensions/skins: `./install extensions/Echo` or `./install skins/MinervaNeue`
- Accepts multiple: `./install extensions/Echo skins/MinervaNeue`
- Clones bare repo(s) into ref/
- Runs Quibble with `-e ZUUL_PROJECT=mediawiki/extensions/Echo`
- Extra dependency repos as trailing args: `./install extensions/ProofreadPage mediawiki/extensions/ParserFunctions`
- Supports `--resolve-requires` passthrough

### 4. `run_selenium_tests`

Matches quickstart interface:
- `./run_selenium_tests` — core tests
- `./run_selenium_tests extensions/Echo` — extension tests
- `./run_selenium_tests extensions/Echo --spec "tests/selenium/specs/echo.js"` — specific file
- `./run_selenium_tests extensions/Echo --spec "..." --mochaOpts.grep "test name"` — specific test
- Uses `--skip-zuul --skip-deps` (assumes prior install)
- First arg checked: if `extensions/*` or `skins/*`, it's the component; rest are wdio flags
- When wdio flags present: builds `--command "npm run selenium-test -- ..."` (with `cd` into component dir if needed)
- When no wdio flags: uses `--run selenium`

### 5. `run_php_unit_tests`

- `./run_php_unit_tests` — all PHPUnit tests
- `./run_php_unit_tests --group Cache` — specific group
- Uses `--skip-zuul --skip-deps --run phpunit`
- Args passed through

### 6. `run_qunit`

- `./run_qunit` — all QUnit tests
- Uses `--skip-zuul --skip-deps --run qunit`

### 7. `shellto`

- `./shellto` — bash shell with services running
- Uses `--skip-zuul --skip-deps --command bash`

### 8. `remove`

- Removes src/, cache/, log/
- Prompts for confirmation (skip with `FORCE=1`)
- Optionally offers to remove ref/ too (slow to re-clone)

### 9. `.gitignore`

```
/ref/
/cache/
/log/
/src/
```

### 10. `README.md` (replace template)

Document all commands with examples.

## Script conventions

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- Source config: `source "$(dirname "$0")/config"`
- No `.sh` extension
- All executable (`chmod +x`)
- `-h`/`--help` support

## Commands NOT included

| quickstart command | Why omitted |
|---|---|
| `start` / `stop` / `restart` | Quibble is one-shot, no persistent containers |
| `install_all` | Impractical with bare repo model |
| `make_skin_default` / `use_skin` | Not applicable |
| `run_jest` / `run_parser_tests` / `list_selenium_tests` | Doable via `./shellto`; can add later |

## Implementation order

1. `config` → 2. `.gitignore` → 3. `fresh_install` → 4. `remove` → 5. `shellto` → 6. `install` → 7. `run_selenium_tests` → 8. `run_php_unit_tests` → 9. `run_qunit` → 10. `README.md`

## Verification

1. `./fresh_install` — pulls image, clones repos, creates dirs, runs Quibble
2. `./run_selenium_tests` — runs core Selenium tests
3. `./install extensions/Echo` then `./run_selenium_tests extensions/Echo` — install and test Echo
4. `./shellto` — opens interactive bash
5. `./remove` — cleans up directories
