#!/usr/bin/env bats
#
# Tests for lib/remove_worker_dirs.

setup() {
  # Create a temp directory for each test and save project root
  test_dir=$(mktemp -d)
  project_root="$PWD"
}

teardown() {
  rm -rf "$test_dir" # clean up temp dir
}

@test "remove_worker_dirs: removes src_worker_* directories" {
  mkdir -p "$test_dir/src_worker_1" "$test_dir/src_worker_2"
  touch "$test_dir/src_worker_1/file1" "$test_dir/src_worker_2/file2"
  run bash -c '
    cd "'"$test_dir"'"
    . "'"$project_root"'/lib/remove_worker_dirs"
  '
  [ "$status" -eq 0 ]
  [ ! -d "$test_dir/src_worker_1" ]
  [ ! -d "$test_dir/src_worker_2" ]
}

@test "remove_worker_dirs: no error when no worker dirs exist" {
  run bash -c '
    cd "'"$test_dir"'"
    . "'"$project_root"'/lib/remove_worker_dirs"
  '
  [ "$status" -eq 0 ]
}
