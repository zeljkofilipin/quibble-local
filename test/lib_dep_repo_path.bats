#!/usr/bin/env bats
#
# Tests for lib/dep_repo_path.

@test "dep_repo_path: converts extension name to repo path" {
  run bash -c '
    . lib/dep_repo_path
    dep_repo_path "Echo"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mediawiki/extensions/Echo" ]
}

@test "dep_repo_path: converts skin name to repo path" {
  run bash -c '
    . lib/dep_repo_path
    dep_repo_path "skins/MinervaNeue"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mediawiki/skins/MinervaNeue" ]
}

@test "dep_repo_path: handles nested extension name" {
  run bash -c '
    . lib/dep_repo_path
    dep_repo_path "EventLogging"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mediawiki/extensions/EventLogging" ]
}
