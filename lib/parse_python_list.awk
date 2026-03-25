# Extract entries from a Python list assignment in parameter_functions.py.
# Requires -v list="listname" to specify which list to extract.
# Finds "listname = [", then prints each single-quoted entry until "]".

$0 ~ "^" list " = \\[" { found=1; next }  # start of the list
found && /^\]/ { exit }                     # end of the list
found && /'/ {                              # line with a quoted string
  gsub(/^[[:space:]]*'/, "")               # strip leading whitespace and opening quote
  gsub(/'.*/, "")                          # strip closing quote and everything after
  print                                     # print the extracted name
}
