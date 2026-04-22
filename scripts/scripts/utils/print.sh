#!/bin/bash
# ===========================================================================
# print.sh — Color printing utilities.
# ===========================================================================

export COLOR_CLEAR='\e[0m'
export COLOR_RED='\e[0;31m'
export COLOR_GREEN='\e[0;32m'
export COLOR_YELLOW='\e[0;33m'
export COLOR_BLUE='\e[0;34m'
export COLOR_PURPLE='\e[0;35m'
export COLOR_CYAN='\e[0;36m'

set_color() {
	[[ -t 1 ]] && echo -ne "$1"
}

echo_with_color() {
	set_color "$1"
	echo "${@:2}"
	set_color "$COLOR_CLEAR"
}

printf_with_color() {
	set_color "$1"
	printf "${@:2}"
	set_color "$COLOR_CLEAR"
}

print_error() {
	printf_with_color "$COLOR_RED" 'error'
	printf ': '
	echo "$@"
}

print_warning() {
	printf_with_color "$COLOR_YELLOW" 'warning'
	printf ': '
	echo "$@"
}

print_info() {
	printf_with_color "$COLOR_BLUE" 'info'
	printf ': '
	echo "$@"
}

print_success() {
	printf_with_color "$COLOR_GREEN" 'success'
	printf ': '
	echo "$@"
}

export -f set_color
export -f echo_with_color
export -f printf_with_color
export -f print_error
export -f print_warning
export -f print_info
export -f print_success
