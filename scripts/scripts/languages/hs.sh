#!/bin/bash
# ===========================================================================
# hs.sh — Language support for Haskell.
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
					sudo apt-get install -y ghc cabal-install
					cabal update
					mkdir -p "$HOME/.cabal/lib"
					cabal install aeson --libdir="$HOME/.cabal/lib"
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
					apt-get install -y ghc cabal-install
					cabal update
					cabal install aeson --lib
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
	ghc -rtsopts -v --make -O2 "$1" >/dev/null
	return $?
}

execute_program() {
	local EXECUTABLE="$(dirname "$1")/Main"
	"$EXECUTABLE" +RTS -K256m -A8m -RTS "${@:2}"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
