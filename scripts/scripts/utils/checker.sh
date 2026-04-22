#!/bin/bash
# ===========================================================================
# checker.sh — Build and parse results from output checkers.
# ===========================================================================

build_checker() {
	if [[ -z "$SCRIPT_DIR" ]]; then
		echo 'error: $SCRIPT_DIR is not set' >&2
		return 1
	fi

	local SOURCE="$1"
	local TARGET="$2"

	case "$SOURCE" in
		"")
			cp "$SCRIPT_DIR/utils/default_checker.sh" "$TARGET"
			[[ -f "$TARGET" ]] && chmod +x "$TARGET"
			return 0
			;;
		*.cpp)
			g++ -std=c++17 -Wall -Wextra \
				-I "${TESTLIB_PATH:-"$SCRIPT_DIR/../testlib"}" \
				"$SOURCE" -o "$TARGET" "${@:3}"
			return $?
			;;
		*)
			echo "unknown source file type: $SOURCE" >&2
			return 1
			;;
	esac
}

parse_checker_exit_code() {
	local CHECKER_EXIT_CODE="$1"

	if [[ "$CHECKER_EXIT_CODE" -ge 16 ]]; then
		printf 'partially correct (%d/100)\n' $((CHECKER_EXIT_CODE - 16))
		return
	fi

	case "$CHECKER_EXIT_CODE" in
		0) echo 'ok';;                         # _ok
		1) echo 'wrong answer';;               # _wa
		2) echo 'presentation error';;         # _pe
		3) echo 'checker fail';;               # _fail
		4) echo 'dirty output';;               # _dirt
		5) echo 'points (see checker output)';; # _points
		8) echo 'unexpected EOF';;             # _unexpected_eof
		*) echo "unknown result ($CHECKER_EXIT_CODE)";;
	esac
}

export -f build_checker
export -f parse_checker_exit_code
