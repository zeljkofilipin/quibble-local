# Parse a YAML list under a given key from zuul/dependencies.yaml.
# Requires -v key="Name:" to specify which key to extract.
# Finds the key, then prints each "  - value" entry until the next top-level key.

$0 == key { f=1; next }              # when current line matches the key, set flag and skip
f && /^[^ ]/ { exit }               # if flag set and line starts with non-space, stop
f && /^ *- / { sub(/^ *- /, ""); print }  # strip the YAML list prefix and print the value
