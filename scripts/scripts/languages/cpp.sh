#!/bin/bash
# ===========================================================================
# cpp.sh — Language support for C++.
# ===========================================================================

install_dependency() {
	sudo apt-get install -y lsb-release
	local os_id os_version
	os_id="$(lsb_release -si)"
	os_version="$(lsb_release -sr)"

	case "$os_id" in
		Ubuntu)
			case "$os_version" in
				20.04)
					echo "Ubuntu $os_version"
					sudo apt-get update
					sudo apt-get install -y g++ libjsoncpp-dev
					;;
				*)
					echo "Unsupported Ubuntu version: $os_version" >&2
					return 1
					;;
			esac
			;;
		Debian)
			case "$os_version" in
				12*)
					echo "Debian 12"
					apt-get update
					apt-get install -y g++ libjsoncpp-dev
					;;
				*)
					echo "Unsupported Debian version: $os_version" >&2
					return 1
					;;
			esac
			;;
		*)
			echo "Unsupported OS: $os_id" >&2
			return 1
			;;
	esac
}

compile_program() {
	local EXECUTABLE="$(dirname "$1")/Main"
	export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
	g++ -I/usr/include/jsoncpp -x c++ -g -O2 -w -std=gnu++17 "$1" -o "$EXECUTABLE" -ljsoncpp
	return $?
}

execute_program() {
	local EXECUTABLE="$(dirname "$1")/Main"
	"$EXECUTABLE" "${@:2}"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
