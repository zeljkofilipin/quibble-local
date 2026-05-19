#!/usr/bin/env bats
#
# Tests for lib/setup (shared Docker setup).

@test "setup: sets QUIBBLE_IMAGE" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup 2>/dev/null
    echo "$QUIBBLE_IMAGE"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"quibble-bullseye-php83"* ]]
}

@test "setup: QUIBBLE_IMAGE can be overridden" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    export QUIBBLE_IMAGE=my-custom-quibble:dev
    . lib/setup 2>/dev/null
    echo "$QUIBBLE_IMAGE"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"my-custom-quibble:dev"* ]]
}

@test "setup: sets QUIBBLE_VOLUMES array" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_VOLUMES[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"/cache"* ]]
  [[ "$output" == *"/workspace/log"* ]]
  [[ "$output" == *"/srv/git"* ]]
  [[ "$output" == *"/workspace/src"* ]]
}

@test "setup: sets QUIBBLE_DOCKER_FLAGS to -it in verbose mode" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_DOCKER_FLAGS[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"-it"* ]]
}

@test "setup: sets QUIBBLE_DOCKER_FLAGS to -i in silent mode" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    unset VERBOSE
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_DOCKER_FLAGS[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "-i" ]]
}

@test "setup: sets QUIBBLE_DIR to current directory" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup
    echo "$QUIBBLE_DIR"
  ' 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"$(pwd)"* ]]
}

@test "setup: QUIBBLE_SRC defaults to src" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup
    echo "$QUIBBLE_SRC"
  ' 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"src"* ]]
}

@test "setup: QUIBBLE_SRC can be overridden" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    export QUIBBLE_SRC=src_worker_1
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_VOLUMES[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"src_worker_1:/workspace/src"* ]]
}


@test "setup: ENVIRONMENT sets QUIBBLE_SRC and QUIBBLE_SAVE" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    export ENVIRONMENT=0
    . lib/setup 2>/dev/null
    echo "src:$QUIBBLE_SRC save:$QUIBBLE_SAVE"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"src:src_0"* ]]
  [[ "$output" == *"save:src_save_0"* ]]
}

@test "setup: ENVIRONMENT does not override explicit QUIBBLE_SRC" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    export ENVIRONMENT=0
    export QUIBBLE_SRC=my_src
    . lib/setup 2>/dev/null
    echo "$QUIBBLE_SRC"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"my_src"* ]]
}

@test "setup: QUIBBLE_SAVE defaults to src_save" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup 2>/dev/null
    echo "$QUIBBLE_SAVE"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"src_save"* ]]
}

@test "setup: QUIBBLE_DRY_RUN is empty by default" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    unset DRY_RUN
    . lib/setup 2>/dev/null
    echo "dry:${QUIBBLE_DRY_RUN[*]:-}:end"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry::end"* ]]
}

@test "setup: QUIBBLE_DRY_RUN is --dry-run when DRY_RUN=1" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export DRY_RUN=1
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_DRY_RUN[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "--dry-run" ]]
}

@test "setup: QUIBBLE_RESOLVE_REQUIRES is --resolve-requires by default" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    unset RESOLVE_REQUIRES
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_RESOLVE_REQUIRES[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "--resolve-requires" ]]
}

@test "setup: QUIBBLE_RESOLVE_REQUIRES is --resolve-requires when RESOLVE_REQUIRES=1" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export RESOLVE_REQUIRES=1
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_RESOLVE_REQUIRES[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "--resolve-requires" ]]
}

@test "setup: QUIBBLE_RESOLVE_REQUIRES is empty when RESOLVE_REQUIRES=0" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export RESOLVE_REQUIRES=0
    . lib/setup 2>/dev/null
    echo "resolve:${QUIBBLE_RESOLVE_REQUIRES[*]:-}:end"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"resolve::end"* ]]
}

@test "setup: QUIBBLE_DOCKER_FLAGS empty in background mode" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export QUIBBLE_BACKGROUND=1
    . lib/setup 2>/dev/null
    echo "flags:${QUIBBLE_DOCKER_FLAGS[*]:-}:end"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"flags::end"* ]]
}
