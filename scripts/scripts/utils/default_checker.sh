#!/bin/bash
# ===========================================================================
# default_checker.sh — Default output checker (line-by-line diff + JSON).
#
# Arguments:
#   $1  Input file  (unused by this checker)
#   $2  Actual output file
#   $3  Expected answer file
#
# Exit codes:
#   0 — ok
#   1 — wrong answer
#   3 — checker failure
# ===========================================================================

trim-trailing-newlines() {
	sed -e ':a;N;$!ba;s/\n*$//' "$@"
}

# First attempt: plain text diff (whitespace-tolerant).
diff -NZ --text --strip-trailing-cr \
	<(trim-trailing-newlines "$2") \
	<(trim-trailing-newlines "$3") >/dev/null
EXIT_CODE=$?

if [[ "$EXIT_CODE" -eq 0 ]]; then
	echo "File $(basename "$2") and $(basename "$3") are identical" >&2
else
	echo "===== ACTUAL OUTPUT =====" >&2
	cat "$2" >&2
	echo "===== EXPECTED ANSWER =====" >&2
	cat "$3" >&2

	# Second attempt: structured JSON comparison.
	echo "===== JSON CHECKER =====" >&2
	output="$(python3 /tp_workspace/scripts/scripts/utils/json_checker.py --output "$2" --answer "$3")"
	EXIT_CODE=$?
	echo "$output" >&2

	if [[ "$EXIT_CODE" -eq 0 ]]; then
		echo "File $(basename "$2") and $(basename "$3") are identical" >&2
	else
		echo "File $(basename "$2") and $(basename "$3") differ" >&2
	fi
fi

case "$EXIT_CODE" in
	0) exit 0;; # ok
	1) exit 1;; # wrong answer
	*) exit 3;; # checker failure
esac
