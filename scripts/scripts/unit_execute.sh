#!/bin/bash
# ===========================================================================
# unit_execute.sh — Execute a single source file against one test-case input.
#
# Usage:
#   unit_execute.sh <source-file> <input-file>
#
# Unlike test.sh this script does NOT check outputs against answers.
# It simply executes the program with the given input and returns the
# program's exit code.
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

ERR_COMPILATION_ERROR=15
ERR_UNKNOWN_EXTENSION=-1
ERR_MISSING_INPUT=-2

PROGRAM_SRC="$([ -z "$1" ] || realpath "$1")"
PROGRAM_INPUT_PATH="$([ -z "$2" ] || realpath "$2")"

FILENAME="$(basename "$PROGRAM_SRC")"

# Import language-specific `compile_program` and `execute_program`.
LANGUAGE_SCRIPT="$SCRIPT_DIR/languages/${FILENAME##*.}.sh"
if [[ ! -e "$LANGUAGE_SCRIPT" ]]; then
	print_error "unknown file extension for $FILENAME"
	exit $ERR_UNKNOWN_EXTENSION
else
	source "$LANGUAGE_SCRIPT"
fi

TMPDIR="$(mktemp -d)"

# Compile.
cp "$PROGRAM_SRC" "$TMPDIR/$FILENAME"
compile_program "$TMPDIR/$FILENAME"
COMPILE_EXIT_CODE=$?
if [[ "$COMPILE_EXIT_CODE" -ne 0 ]]; then
	rm -r "$TMPDIR"
	exit $ERR_COMPILATION_ERROR
fi

# Timeout configuration.
: "${TIMEOUT_DURATION:=10s}" "${TIMEOUT_SIGNAL:=SIGTERM}"

execute_with_timeout_guard() {
	local PROGRAM="$1"
	local IN_STREAM="$2"
	(
		set -m
		execute_program "$PROGRAM" < "$IN_STREAM" &
		local CHILD_PID=$!
		trap -- "" SIGTERM
		(
			sleep "$TIMEOUT_DURATION"
			kill -s "$TIMEOUT_SIGNAL" -- -$CHILD_PID 2>/dev/null
		) &
		local GUARD_PID=$!
		set +m
		wait $CHILD_PID
		local EXIT_CODE=$?
		kill -s SIGINT -- -$GUARD_PID 2>/dev/null
		return $EXIT_CODE
	)
}

test_single() {
	local PROGRAM_IN="$1"
	if [[ ! -e "$PROGRAM_IN" ]]; then
		print_error "missing input: $PROGRAM_IN"
		return $ERR_MISSING_INPUT
	fi

	ulimit -s unlimited
	execute_with_timeout_guard "$TMPDIR/$FILENAME" "$PROGRAM_IN"
}

EXIT_CODE=0
test_single "$PROGRAM_INPUT_PATH" || EXIT_CODE=$?

rm -r "$TMPDIR"
exit $EXIT_CODE
