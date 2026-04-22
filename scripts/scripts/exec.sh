#!/bin/bash
# ===========================================================================
# exec.sh — Compile and execute a single source file (stdin → stdout).
#
# Usage:
#   exec.sh <source-file>
#
# Compiler output is redirected to stderr so that only program output
# appears on stdout.
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

ERR_COMPILATION_ERROR=15
ERR_UNKNOWN_EXTENSION=-1

if [[ -z "$1" ]]; then
	print_error 'missing argument'
	"$SCRIPT_DIR/help.sh" "$(basename "$SCRIPT_PATH" | sed -e 's/.sh$//')"
	exit $ERR_UNKNOWN_EXTENSION
fi

PROGRAM_SRC="$(realpath "$1")"
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
compile_program "$TMPDIR/$FILENAME" >&2
COMPILE_EXIT_CODE=$?
if [[ "$COMPILE_EXIT_CODE" -ne 0 ]]; then
	rm -r "$TMPDIR"
	exit $ERR_COMPILATION_ERROR
fi

# Execute.
source "$SCRIPT_DIR/utils/timeout.sh"
ulimit -s unlimited
with_timeout_guard execute_program "$TMPDIR/$FILENAME"
EXECUTE_EXIT_CODE=$?

rm -r "$TMPDIR"
exit $EXECUTE_EXIT_CODE
