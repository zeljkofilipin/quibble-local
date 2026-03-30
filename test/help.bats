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

@test "help SCRIPT: shows detailed help for a script" {
  run ./help install
  [ "$status" -eq 0 ]
  [[ "$output" == *"./install"* ]]
  # detailed mode shows the full comment header including multi-line usage
  [[ "$output" == *"Installs an extension or skin"* ]]
  [[ "$output" == *"./install extensions/Echo"* ]]
  [[ "$output" == *"./install skins/MinervaNeue"* ]]
}

@test "help SCRIPT: accepts ./ prefix" {
  run ./help ./install
  [ "$status" -eq 0 ]
  [[ "$output" == *"./install"* ]]
}

@test "help SCRIPT: fails for nonexistent script" {
  run ./help nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

@test "help SCRIPT: fails for non-bash file" {
  run ./help README.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a bash script"* ]]
}
