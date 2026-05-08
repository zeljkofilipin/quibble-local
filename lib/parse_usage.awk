# Parse the # Usage: block from a script header.
# Outputs one command per line, with the "# Usage: " prefix or continuation indent stripped.
# Convention: a line "# Usage: <cmd>" followed by zero or more continuation lines
# starting with "#" plus 2 or more spaces. The block ends at the first non-matching line.
# The 2-space minimum on continuation lines distinguishes them from regular comments
# like "# FAST=1: explanation" that may follow the Usage block.

/^# Usage:/ { flag=1; sub(/^# Usage:[[:space:]]*/, ""); sub(/[[:space:]]+#.*$/, ""); if (NF) print; next }  # first Usage line; also strip any trailing " #..." inline comment
flag && /^#  +[^ ]/ { sub(/^#[[:space:]]+/, ""); sub(/[[:space:]]+#.*$/, ""); if (NF) print; next }         # continuation line (# + 2+ spaces + non-space)
flag { exit }                                                                                                  # block ends at first non-continuation line
