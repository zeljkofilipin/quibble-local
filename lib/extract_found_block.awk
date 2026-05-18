# Extract the "FOUND: minimum dependencies" block from a find_dependencies_minimal_* log file.
# The block is produced by lib/print_found and ends just before the duration line
# "(Nm Ns)" added by lib/duration_trap when the inner script exits.
# Prints from the "===" line that precedes "= FOUND:" through the last body line.

{
  if (in_block) {                                # currently inside the FOUND block
    if ($0 ~ /^\([0-9]+(m [0-9]+)?s\)$/) {       # stop at the trailing duration line, e.g. "(27m 48s)" or "(45s)"
      exit                                       # done extracting; ignore everything after
    }
    print                                        # print every line inside the block until the duration
  } else if ($0 ~ /^= FOUND:/) {                 # entering the block — this is the second line of the banner
    print prev                                   # print the "===" header line that preceded "= FOUND:"
    print                                        # print this "= FOUND:" line
    in_block = 1                                 # mark that we are now inside the block
  }
  prev = $0                                      # remember each line in case the next one matches "= FOUND:"
}
