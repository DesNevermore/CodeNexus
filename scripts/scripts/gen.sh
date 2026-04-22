#!/bin/bash
# ===========================================================================
# gen.sh — Generate test cases by running gentest*.sh scripts.
#
# Usage:
#   gen.sh <benchmark-dir>
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

if [[ -z "$1" ]]; then
	print_error 'missing argument'
	"$SCRIPT_DIR/help.sh" "$(basename "$SCRIPT_PATH" | sed -e 's/.sh$//')"
	exit 255
fi

source "$SCRIPT_DIR/utils/checker.sh"

make_test() {
	local FILE_PATH DIR_PATH OLD_PWD EXIT_CODE
	FILE_PATH="$(realpath "$1")"
	DIR_PATH="$(dirname "$FILE_PATH")"
	OLD_PWD="$PWD"

	cd "$DIR_PATH" || return 1

	if build_checker ./generator.cpp ./generator; then
		bash "$FILE_PATH"
		EXIT_CODE=$?
		rm -f ./generator
	else
		EXIT_CODE=$?
		print_error "failed to build $DIR_PATH/generator.cpp"
	fi

	cd "$OLD_PWD" || return 1
	return $EXIT_CODE
}

while IFS= read -r -d '' FILE; do
	print_info "Building test case with \"$FILE\""
	make_test "$FILE"
done < <(find "$1" -name 'gentest*.sh' -print0)
