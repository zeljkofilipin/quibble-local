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

@test "setup: QUIBBLE_PORT_FLAGS defaults to -p 9413:9413" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    . lib/setup 2>/dev/null
    echo "${QUIBBLE_PORT_FLAGS[@]}"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"-p"* ]]
  [[ "$output" == *"9413:9413"* ]]
}

@test "setup: QUIBBLE_PORT_FLAGS empty when QUIBBLE_EXPOSE_PORT=0" {
  run bash -c '
    export _QUIBBLE_NO_DOCKER_CHECK=1
    export VERBOSE=1
    export QUIBBLE_EXPOSE_PORT=0
    . lib/setup 2>/dev/null
    echo "flags:${QUIBBLE_PORT_FLAGS[*]:-}:end"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"flags::end"* ]]
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
