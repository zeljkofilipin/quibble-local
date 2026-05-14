#!/usr/bin/env bats
#
# Tests for awk scripts in lib/.

# combinations.awk — generate all non-empty bitmask combinations

@test "combinations.awk: single item" {
  result=$(printf "A\n" | awk -f lib/combinations.awk)
  [ "$result" = "A" ]
}

@test "combinations.awk: two items" {
  result=$(printf "A\nB\n" | awk -f lib/combinations.awk)
  expected=$(printf "A\nB\nA B")
  [ "$result" = "$expected" ]
}

@test "combinations.awk: three items ordered by size" {
  result=$(printf "A\nB\nC\n" | awk -f lib/combinations.awk)
  # Size 1, then size 2, then size 3
  expected=$(printf "A\nB\nC\nA B\nA C\nB C\nA B C")
  [ "$result" = "$expected" ]
}

@test "combinations.awk: empty input produces no output" {
  result=$(printf "" | awk -f lib/combinations.awk)
  [ -z "$result" ]
}

# combinations_with_empty.awk — same but includes the empty set

@test "combinations_with_empty.awk: single item includes empty line" {
  result=$(printf "A\n" | awk -f lib/combinations_with_empty.awk)
  # First line is empty (empty set), second line is "A"
  expected=$(printf "\nA")
  [ "$result" = "$expected" ]
}

@test "combinations_with_empty.awk: two items includes empty line" {
  result=$(printf "A\nB\n" | awk -f lib/combinations_with_empty.awk)
  expected=$(printf "\nA\nB\nA B")
  [ "$result" = "$expected" ]
}

@test "combinations_with_empty.awk: empty input produces one empty line" {
  result=$(printf "" | awk -f lib/combinations_with_empty.awk)
  [ "$result" = "" ]
}

# parse_yaml_list.awk — extract YAML list entries under a key

@test "parse_yaml_list.awk: extracts list under matching key" {
  input=$(printf "Other:\n  - X\nEcho:\n  - Dep1\n  - Dep2\nAnother:\n  - Y\n")
  result=$(echo "$input" | awk -v key="Echo:" -f lib/parse_yaml_list.awk)
  expected=$(printf "Dep1\nDep2")
  [ "$result" = "$expected" ]
}

@test "parse_yaml_list.awk: returns nothing for missing key" {
  input=$(printf "Echo:\n  - Dep1\n")
  result=$(echo "$input" | awk -v key="Missing:" -f lib/parse_yaml_list.awk)
  [ -z "$result" ]
}

@test "parse_yaml_list.awk: stops at next top-level key" {
  input=$(printf "Echo:\n  - Dep1\nNext:\n  - Other\n")
  result=$(echo "$input" | awk -v key="Echo:" -f lib/parse_yaml_list.awk)
  [ "$result" = "Dep1" ]
}

# parse_python_list.awk — extract entries from a Python list assignment

@test "parse_python_list.awk: extracts list entries" {
  input=$(printf "gatedextensions = [\n    'Foo',\n    'Bar',\n]\n")
  result=$(echo "$input" | awk -v list="gatedextensions" -f lib/parse_python_list.awk)
  expected=$(printf "Foo\nBar")
  [ "$result" = "$expected" ]
}

@test "parse_python_list.awk: returns nothing for missing list" {
  input=$(printf "gatedextensions = [\n    'Foo',\n]\n")
  result=$(echo "$input" | awk -v list="other" -f lib/parse_python_list.awk)
  [ -z "$result" ]
}

@test "parse_python_list.awk: handles multiple lists" {
  input=$(printf "first = [\n    'A',\n]\nsecond = [\n    'B',\n    'C',\n]\n")
  result=$(echo "$input" | awk -v list="second" -f lib/parse_python_list.awk)
  expected=$(printf "B\nC")
  [ "$result" = "$expected" ]
}

# parse_requires.awk — extract requires.extensions and requires.skins from JSON

@test "parse_requires.awk: extracts required extensions" {
  input=$(cat <<'JSON'
{
  "requires": {
    "extensions": {
      "Echo": "*",
      "Flow": "*"
    }
  }
}
JSON
  )
  result=$(echo "$input" | awk -f lib/parse_requires.awk)
  expected=$(printf "Echo\nFlow")
  [ "$result" = "$expected" ]
}

@test "parse_requires.awk: extracts required skins with prefix" {
  input=$(cat <<'JSON'
{
  "requires": {
    "skins": {
      "Vector": "*"
    }
  }
}
JSON
  )
  result=$(echo "$input" | awk -f lib/parse_requires.awk)
  [ "$result" = "skins/Vector" ]
}

@test "parse_requires.awk: extracts both extensions and skins" {
  input=$(cat <<'JSON'
{
  "requires": {
    "extensions": {
      "Echo": "*"
    },
    "skins": {
      "MinervaNeue": "*"
    }
  }
}
JSON
  )
  result=$(echo "$input" | awk -f lib/parse_requires.awk)
  expected=$(printf "Echo\nskins/MinervaNeue")
  [ "$result" = "$expected" ]
}

@test "parse_requires.awk: returns nothing when no requires" {
  input=$(cat <<'JSON'
{
  "name": "SomeExtension"
}
JSON
  )
  result=$(echo "$input" | awk -f lib/parse_requires.awk)
  [ -z "$result" ]
}

# parse_usage.awk — extract the # Usage: block from a script header

@test "parse_usage.awk: single-line Usage" {
  input=$(printf '#!/usr/bin/env bash\n#\n# Some description\n#\n# Usage: ./foo\n#\nset -e\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  [ "$result" = "./foo" ]
}

@test "parse_usage.awk: multi-line Usage with continuations" {
  input=$(printf '#!/usr/bin/env bash\n# Usage: ./foo\n#        ./foo bar\n#        VERBOSE=1 ./foo\n#\nset -e\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  expected=$(printf './foo\n./foo bar\nVERBOSE=1 ./foo')
  [ "$result" = "$expected" ]
}

@test "parse_usage.awk: stops at blank comment line" {
  input=$(printf '# Usage: ./foo\n#        ./foo bar\n#\n#        ./not_a_continuation\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  expected=$(printf './foo\n./foo bar')
  [ "$result" = "$expected" ]
}

@test "parse_usage.awk: stops at non-comment line" {
  input=$(printf '# Usage: ./foo\n#        ./foo bar\nset -e\n#        ./not_a_continuation\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  expected=$(printf './foo\n./foo bar')
  [ "$result" = "$expected" ]
}

@test "parse_usage.awk: stops at single-space comment line" {
  # "# FOO=1: explanation" has only one space after # — distinct from continuation.
  input=$(printf '# Usage: ./foo\n#        ./foo bar\n# FAST=1: explanation\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  expected=$(printf './foo\n./foo bar')
  [ "$result" = "$expected" ]
}

@test "parse_usage.awk: returns nothing when no Usage block" {
  input=$(printf '#!/usr/bin/env bash\n# Some description\nset -e\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  [ -z "$result" ]
}

@test "parse_usage.awk: strips trailing inline # comment" {
  input=$(printf '# Usage: ./foo\n#        DRY_RUN=1 ./foo bar  # pass --dry-run\n')
  result=$(echo "$input" | awk -f lib/parse_usage.awk)
  expected=$(printf './foo\nDRY_RUN=1 ./foo bar')
  [ "$result" = "$expected" ]
}

# scrub_pwd.awk — replace the project's absolute path with the placeholder "$PWD"

@test "scrub_pwd.awk: replaces single occurrence with \$PWD placeholder" {
  result=$(echo "  -v /abs/proj/cache:/cache" | awk -v pwd="/abs/proj" -f lib/scrub_pwd.awk)
  [ "$result" = "  -v \$PWD/cache:/cache" ]
}

@test "scrub_pwd.awk: leaves unrelated paths alone" {
  result=$(echo "  -v /other/cache:/cache" | awk -v pwd="/abs/proj" -f lib/scrub_pwd.awk)
  [ "$result" = "  -v /other/cache:/cache" ]
}

@test "scrub_pwd.awk: leaves prefix-only matches alone (requires trailing slash)" {
  # "/abs/project-backup" shares the prefix with "/abs/project" but is a different dir.
  # The awk script only scrubs "<pwd>/", so the substring match must not fire here.
  result=$(echo "/abs/project-backup/file" | awk -v pwd="/abs/project" -f lib/scrub_pwd.awk)
  [ "$result" = "/abs/project-backup/file" ]
}

@test "scrub_pwd.awk: handles multiple occurrences on one line" {
  result=$(echo "/abs/proj/a and /abs/proj/b" | awk -v pwd="/abs/proj" -f lib/scrub_pwd.awk)
  [ "$result" = "\$PWD/a and \$PWD/b" ]
}

@test "scrub_pwd.awk: treats path as a literal string (no regex metachars)" {
  # If the script used gsub with the pwd interpolated into a regex, the "." in the path
  # would match any character — and a line containing "/abs/PRO_/file" would be wrongly
  # scrubbed. With index()/substr() the match is byte-literal.
  result=$(echo "/abs/PRO_/file" | awk -v pwd="/abs/pro." -f lib/scrub_pwd.awk)
  [ "$result" = "/abs/PRO_/file" ]
}

@test "scrub_pwd.awk: passes lines through unchanged when no path appears" {
  result=$(echo "no path here" | awk -v pwd="/abs/proj" -f lib/scrub_pwd.awk)
  [ "$result" = "no path here" ]
}

@test "scrub_pwd.awk: calls fflush() per line so tail -f on the destination streams in real time" {
  # Regression guard: awk full-buffers stdout when it's a pipe or file (~8KB chunks), so
  # without fflush() after each print, files written via `./generate_example` only update
  # for `tail -f` watchers in big bursts (or all at script exit on a small run). The
  # fflush() keeps line-by-line streaming working. Easier to assert as a static check than
  # to time the streaming behavior reliably under CI.
  run grep -E "fflush\\(\\)" lib/scrub_pwd.awk
  [ "$status" -eq 0 ]
}
