#!/bin/bash
# ===========================================================================
# test.sh — Compile a source file and evaluate it against test cases.
#
# Usage:
#   test.sh <source-file> <test-dir> [checker]
#   test.sh <benchmark-dir>
#
# Exit codes:
#   0   — all tests passed (ok)
#   3   — checker compilation failed
#   13  — time limit exceeded
#   14  — runtime error
#   15  — compilation error
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

# --- Error codes -----------------------------------------------------------
ERR_COMPILATION_ERROR=15
ERR_RUNTIME_ERROR=14
ERR_TIME_LIMIT_EXCEEDED=13
ERR_CHECKER_FAIL=3
ERR_UNKNOWN_EXTENSION=-1
ERR_MISSING_INPUT=-2
ERR_MISSING_ANSWER=-3

# --- Argument parsing ------------------------------------------------------
if [[ -z "$1" ]]; then
	print_error 'missing argument'
	"$SCRIPT_DIR/help.sh" "$(basename "$SCRIPT_PATH" | sed -e 's/.sh$//')"
	exit $ERR_UNKNOWN_EXTENSION
fi

# Single argument: treat as a benchmark directory (src/ + test/).
if [[ $# -eq 1 ]] && [[ -d "$1" ]] && [[ -d "$1/src" ]] && [[ -d "$1/test" ]]; then
	PROGRAM_SRC="$1/src"
	PROGRAM_INPUT_PATH="$1/test"
	CHECKER_SRC="$(find "$1" -name 'checker*' -print -quit)"
else
	PROGRAM_SRC=$([ -z "$1" ] || realpath "$1")
	PROGRAM_INPUT_PATH=$([ -z "$2" ] || realpath "$2")
	CHECKER_SRC=$([ -z "$3" ] || realpath "$3")
fi

# If test-case dir is the benchmark root, descend into test/.
if [[ -d "$PROGRAM_INPUT_PATH" ]] \
	&& [[ -n "$(find "$PROGRAM_INPUT_PATH" -maxdepth 1 -name '*.in' -print -quit)" ]] \
	&& [[ -d "$PROGRAM_INPUT_PATH/test" ]]; then
	PROGRAM_INPUT_PATH="$PROGRAM_INPUT_PATH/test"
fi

# --- Batch handler (directory of Main.* files) -----------------------------
if_test_in_batch() {
	local DIR_PATH="$1"
	if [[ -d "$DIR_PATH" ]] && [[ -n "$(find "$DIR_PATH" -maxdepth 1 -name 'Main.*' -print -quit)" ]]; then
		while IFS= read -r -d '' FILE; do
			echo "------ $(basename "$FILE") ------"
			"$SCRIPT_PATH" "$FILE" "$PROGRAM_INPUT_PATH" "$CHECKER_SRC"
		done < <(find "$DIR_PATH" -maxdepth 1 -name 'Main.*' -print0)
		return 0
	else
		return 1
	fi
}

if [[ -d "$PROGRAM_SRC" ]]; then
	# Validate checker — abort early on compilation failure.
	source "$SCRIPT_DIR/utils/checker.sh"
	build_checker "$CHECKER_SRC" /dev/null
	CHECKER_BUILDER_EXIT_CODE=$?
	if [[ "$CHECKER_BUILDER_EXIT_CODE" -ne 0 ]]; then
		print_error "checker compilation failed (error code: $CHECKER_BUILDER_EXIT_CODE)"
		exit $ERR_CHECKER_FAIL
	fi

	(if_test_in_batch "$PROGRAM_SRC" || if_test_in_batch "$PROGRAM_SRC/src") && exit
	print_error "no source code found in $PROGRAM_SRC"
	exit 1
fi

# --- Single-file path ------------------------------------------------------
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

# --- Build checker ---------------------------------------------------------
source "$SCRIPT_DIR/utils/checker.sh"
build_checker "$CHECKER_SRC" "$TMPDIR/checker" >&2
CHECKER_BUILDER_EXIT_CODE=$?
if [[ "$CHECKER_BUILDER_EXIT_CODE" -ne 0 ]]; then
	print_error "checker compilation failed (error code: $CHECKER_BUILDER_EXIT_CODE)"
	rm -r "$TMPDIR"
	exit $ERR_CHECKER_FAIL
fi

# --- Compile program -------------------------------------------------------
cp "$PROGRAM_SRC" "$TMPDIR/$FILENAME"
compile_program "$TMPDIR/$FILENAME" >&2
COMPILE_EXIT_CODE=$?
if [[ "$COMPILE_EXIT_CODE" -ne 0 ]]; then
	echo_with_color "$COLOR_BLUE" "compilation error (error code: $COMPILE_EXIT_CODE)"
	rm -r "$TMPDIR"
	exit $ERR_COMPILATION_ERROR
fi

# --- Timeout configuration -------------------------------------------------
source "$SCRIPT_DIR/utils/timeout.sh"
: "${TIMEOUT_DURATION:="10s"}" "${TIMEOUT_SIGNAL:="SIGTERM"}"

# --- Run a single test case ------------------------------------------------
test_single() {
	local PROGRAM_IN="$1"
	local PROGRAM_ANS="$2"
	local PROGRAM_OUT
	PROGRAM_OUT="$(mktemp -u -p "$TMPDIR")"
	: "${PROGRAM_ANS:="${PROGRAM_IN/.in/.ans}"}"

	if [[ ! -e "$PROGRAM_IN" ]]; then
		print_error "missing input: $PROGRAM_IN"
		return $ERR_MISSING_INPUT
	fi
	if [[ ! -e "$PROGRAM_ANS" ]]; then
		print_error "missing answer: $PROGRAM_ANS"
		return $ERR_MISSING_ANSWER
	fi

	# Execute with resource limits.
	ulimit -s unlimited
	ulimit -v 5242880
	with_timeout_guard execute_program "$TMPDIR/$FILENAME" < "$PROGRAM_IN" > "$PROGRAM_OUT"
	local EXECUTE_EXIT_CODE=$?

	if [[ "$EXECUTE_EXIT_CODE" -eq $((128 + $(kill -l "$TIMEOUT_SIGNAL"))) ]]; then
		echo_with_color "$COLOR_YELLOW" "time limit exceeded (${TIMEOUT_DURATION})"
		[[ -e "$PROGRAM_OUT" ]] && rm "$PROGRAM_OUT"
		return $ERR_TIME_LIMIT_EXCEEDED
	fi
	if [[ "$EXECUTE_EXIT_CODE" -ne 0 ]]; then
		echo_with_color "$COLOR_PURPLE" "runtime error (error code: $EXECUTE_EXIT_CODE)"
		[[ -e "$PROGRAM_OUT" ]] && rm "$PROGRAM_OUT"
		return $ERR_RUNTIME_ERROR
	fi

	# Check output against expected answer.
	"$TMPDIR/checker" "$PROGRAM_IN" "$PROGRAM_OUT" "$PROGRAM_ANS"
	local CHECKER_EXIT_CODE=$?
	if [[ "$CHECKER_EXIT_CODE" -eq 0 ]]; then
		set_color "$COLOR_GREEN"
	else
		set_color "$COLOR_RED"
	fi
	parse_checker_exit_code "$CHECKER_EXIT_CODE"
	set_color "$COLOR_CLEAR"
	[[ -e "$PROGRAM_OUT" ]] && rm "$PROGRAM_OUT"
	return $CHECKER_EXIT_CODE
}

# --- Iterate over all test cases -------------------------------------------
EXIT_CODE=0

while IFS= read -r -d '' FILE; do
	printf '> %s: ' "$(basename "$FILE")"
	if [[ -t 1 ]]; then
		echo '' >&2
	else
		echo ''
	fi
	test_single "$FILE" || EXIT_CODE=$?
done < <(find "$PROGRAM_INPUT_PATH" -maxdepth 1 -name '*.in' -print0 | sort -z)

rm -r "$TMPDIR"
exit $EXIT_CODE
