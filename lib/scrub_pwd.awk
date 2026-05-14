# Replace literal occurrences of the project's absolute path with the placeholder "$PWD".
# Keeps captured output in examples/*.txt machine-independent — without this, Docker -v
# mount lines (e.g. "-v /home/z/.../quibble-local/cache:/cache") embed whatever absolute
# path the generating machine has, producing pointless diff churn when the same examples
# are regenerated on a different machine.
#
# Only the prefix "<pwd>/" is rewritten (note the trailing slash) so a directory whose
# name shares the prefix (e.g. "/abs/proj-backup/...") is left alone. Bare "<pwd>" without
# a trailing path component is never seen in real captured output (docker volume mounts
# always continue into a subpath), so the trailing-slash anchor is safe.
#
# Uses index()/substr() rather than gsub() so the search is a literal substring match —
# path components can in principle contain regex metacharacters (".", "[", etc.) and
# escaping them all for gsub would be brittle.
#
# Usage: awk -v pwd="$PWD" -f lib/scrub_pwd.awk

BEGIN {
  needle = pwd "/"               # match the path only when followed by a "/", to avoid scrubbing similarly-prefixed paths
  replacement = "$PWD/"          # literal placeholder (the file is documentation, not executable shell)
  nlen = length(needle)          # length cached so the inner loop doesn't recompute it
}

{
  out = ""                       # accumulator for the rewritten line so far
  s = $0                         # remaining tail of the current line
  while ((i = index(s, needle)) > 0) {           # index() returns 1-based position of first match, or 0
    out = out substr(s, 1, i - 1) replacement    # copy everything before the match, then append the placeholder
    s = substr(s, i + nlen)                      # advance past the match
  }
  print out s                    # print accumulated prefix + the rest (no more matches)
}
