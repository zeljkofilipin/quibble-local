#!/usr/bin/env bats
#
# Tests for lib/pluralize.

setup() {
  # shellcheck disable=SC1091
  . ./lib/pluralize
}

@test "pluralize: count of 1 is singular" {
  [ "$(pluralize 1 worker)" = "worker" ]
}

@test "pluralize: count of 2 is plural (default adds s)" {
  [ "$(pluralize 2 worker)" = "workers" ]
}

@test "pluralize: count of 0 is plural" {
  [ "$(pluralize 0 worker)" = "workers" ]
}

@test "pluralize: explicit plural for irregular words" {
  [ "$(pluralize 1 entry entries)" = "entry" ]
  [ "$(pluralize 3 entry entries)" = "entries" ]
}

@test "pluralize: composes with printf for count + noun" {
  [ "$(printf '%d %s' 1 "$(pluralize 1 worker)")" = "1 worker" ]
  [ "$(printf '%d %s' 4 "$(pluralize 4 worker)")" = "4 workers" ]
}
