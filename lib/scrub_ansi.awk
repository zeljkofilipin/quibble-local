# Strip ANSI CSI escape sequences (color codes, cursor moves) from captured output.
#
# Quibble's Python logger (colorlog), composer, npm, and other tools running inside the
# Quibble Docker image emit color codes and cursor-control sequences when they think
# their stdout is a terminal (most often when generate_example uses VERBOSE=1, which
# adds `-t` to `docker run` — see lib/setup). When generate_example then captures that
# output to a file, the codes land as literal escape sequences (e.g. "[33mWARNING[0m"
# instead of yellow "WARNING"), making the examples/*.txt files noisy to read and to
# diff. This scrubber strips them post-capture.
#
# Matches CSI sequences: ESC [ <optional ?> <digits and semicolons> <letter>.
# Covers SGR color codes ([33m, [0m, [30;43m), private mode toggles ([?25h, [?25l),
# and cursor moves ([2K, [G). Bare ESC characters and OSC sequences are left alone:
# they are rare in this project's captured output and harmless when they do appear.
#
# Usage: awk -f lib/scrub_ansi.awk

BEGIN {
  # Build the pattern dynamically: POSIX awk does not portably support \033 inside a
  # regex literal, but it does support sprintf("%c", 27) and gsub compiles the resulting
  # string variable as a regex.
  esc = sprintf("%c", 27)            # literal ESC byte (0x1B)
  pat = esc "\\[[?]?[0-9;]*[a-zA-Z]" # ESC [ optional ? digits/semis final-letter
}

{
  gsub(pat, "")  # remove every CSI sequence from the line
  print          # emit the line (or what remains of it) verbatim
}
