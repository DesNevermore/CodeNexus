#!/bin/bash
# ===========================================================================
# register.sh — Register the `bench` command in a shell profile.
#
# Usage:
#   register.sh [--stdout | --system | <profile>]
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

register_path_environment() {
	echo '# bench'
	echo "export BENCH_SCRIPT_DIR='$SCRIPT_DIR'"
	echo 'export PATH="$BENCH_SCRIPT_DIR/bin:$PATH"     # This loads bench command'
	echo 'source "$BENCH_SCRIPT_DIR/utils/bash_completion.sh"  # This loads bench bash completion'
}

PROFILE_LOCATION="$1"

if [[ "$PROFILE_LOCATION" == "--system" ]]; then
	PROFILE_LOCATION="/etc/profile.d/bench.sh"
elif [[ "$PROFILE_LOCATION" == "--stdout" ]]; then
	register_path_environment
	exit $?
else
	[[ -e "$PROFILE_LOCATION" ]] || PROFILE_LOCATION="$HOME/.bashrc"
	[[ -e "$PROFILE_LOCATION" ]] || PROFILE_LOCATION="$HOME/.profile"
fi

if [[ -f "$PROFILE_LOCATION" ]] && grep -qF "$(register_path_environment)" "$PROFILE_LOCATION"; then
	print_warning "the bench command has already been registered in $PROFILE_LOCATION"
else
	register_path_environment >> "$PROFILE_LOCATION" || exit $?
fi

print_success 'For changes to take effect, close and re-open your current shell or run the following:'
echo ''
echo "  source '$PROFILE_LOCATION'"
echo ''
