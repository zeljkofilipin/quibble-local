#!/usr/bin/env bats
#
# Tests for help script.

@test "help: exits 0" {
  run ./help
  [ "$status" -eq 0 ]
}

@test "help: lists scripts" {
  run ./help
  [[ "$output" == *"./fresh_install"* ]]
  [[ "$output" == *"./install"* ]]
  [[ "$output" == *"./clean"* ]]
  [[ "$output" == *"./help"* ]]
}

@test "help: includes descriptions" {
  run ./help
  # fresh_install has a description in its comment header
  [[ "$output" == *"Installs MediaWiki core"* ]]
}

@test "help: includes usage lines" {
  run ./help
  # install has a Usage: line in its comment header
  [[ "$output" == *"Usage:"* ]]
}

@test "help: shows silent/verbose hint" {
  run ./help
  [[ "$output" == *"silent by default"* ]]
}
