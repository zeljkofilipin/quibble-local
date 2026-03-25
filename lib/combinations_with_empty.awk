# Generate all bitmask combinations of items, ordered by size, including the empty set.
# Reads item names from stdin (one per line).
# Output is ordered by size: 0 items (empty line), 1 item, 2 items, ..., n items.
# Each combination is space-separated on one line. Empty set is a blank line.

{
  items[NR] = $0  # store each item name by line number (1-indexed)
}
END {
  n = NR                      # number of items
  total = 2 ^ n               # total subsets including empty set
  for (size = 0; size <= n; size++) {          # iterate by combination size (0 = empty set)
    for (mask = 0; mask < total; mask++) {     # iterate through all bitmasks
      # Count set bits in mask
      bits = 0                                 # number of 1-bits in mask
      tmp = mask                               # work on a copy so mask is unchanged
      while (tmp > 0) {
        bits += int(tmp) % 2                   # add lowest bit (0 or 1); int() for safety
        tmp = int(tmp / 2)                     # right shift (awk has no >> operator)
      }
      if (bits != size) continue               # skip if not the current combination size

      # Build space-separated list of items for this bitmask
      combo = ""
      check = mask                             # work on a copy to extract individual bits
      for (i = 1; i <= n; i++) {               # i is 1-indexed to match items[] array
        if (int(check) % 2 == 1) {             # check if lowest bit is set
          combo = (combo == "" ? "" : combo " ") items[i]  # append with space separator
        }
        check = int(check / 2)                 # right shift to check next bit
      }
      print combo                              # one combination per line (empty line for empty set)
    }
  }
}
