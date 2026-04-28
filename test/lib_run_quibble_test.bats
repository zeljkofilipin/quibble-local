#!/usr/bin/env bats
#
# Tests for lib/run_quibble_test.

@test "run_quibble_test: defines the run_quibble_test function" {
  run bash -c '
    . '"$BATS_TEST_DIRNAME"'/../lib/run_quibble_test
    type run_quibble_test
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}

@test "run_quibble_test: prints the docker command before running it" {
  # Stub docker so we capture invocation without needing a real daemon.
  # Set the variables that lib/setup would normally provide.
  run bash -c '
    docker() { echo "stub-docker $*"; }
    QUIBBLE_DOCKER_FLAGS=(-i)
    QUIBBLE_VOLUMES=(-v /tmp:/tmp)
    QUIBBLE_IMAGE=fake-image:latest
    . '"$BATS_TEST_DIRNAME"'/../lib/run_quibble_test
    run_quibble_test --run phpunit
  '
  [ "$status" -eq 0 ]
  # The banner makes the quibble command easy to find in busy logs.
  [[ "$output" == *"########################################"* ]]
  [[ "$output" == *"docker run"* ]]
  [[ "$output" == *"--run phpunit"* ]]
  [[ "$output" == *"fake-image:latest"* ]]
}
