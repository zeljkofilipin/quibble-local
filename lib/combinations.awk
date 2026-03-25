# Generate all bitmask combinations of dependencies, ordered by size.
# Reads dependency names from stdin (one per line).
# Each number from 1 to 2^n-1 represents a subset via its binary bits.
# Bit i set means deps[i] is included.
# Output is ordered by size: 1 dep, 2 deps, ..., n deps.

{
  deps[NR] = $0  # store each dependency name by line number (1-indexed)
}
END {
  n = NR                      # number of dependencies
  total = 2 ^ n               # total subsets (equivalent to 1 << n)
  for (size = 1; size <= n; size++) {          # iterate by combination size
    for (mask = 1; mask < total; mask++) {     # iterate through all non-empty bitmasks
      # Count set bits in mask
      bits = 0                                 # number of 1-bits in mask
      tmp = mask                               # work on a copy so mask is unchanged
      while (tmp > 0) {
        bits += int(tmp) % 2                   # add lowest bit (0 or 1); int() for safety
        tmp = int(tmp / 2)                     # right shift (awk has no >> operator)
      }
      if (bits != size) continue               # skip if not the current combination size

      # Build space-separated list of deps for this bitmask
      combo = ""
      check = mask                             # work on a copy to extract individual bits
      for (i = 1; i <= n; i++) {               # i is 1-indexed to match deps[] array
        if (int(check) % 2 == 1) {             # check if lowest bit is set
          combo = (combo == "" ? "" : combo " ") deps[i]  # append with space separator
        }
        check = int(check / 2)                 # right shift to check next bit
      }
      print combo                              # one combination per line
    }
  }
}
