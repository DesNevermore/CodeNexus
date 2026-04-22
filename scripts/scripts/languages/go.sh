#!/bin/bash
# ===========================================================================
# go.sh — Language support for Go.
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
					if which go >/dev/null 2>&1; then return; fi
					sudo apt-get update
					sudo apt-get install -y wget tar
					wget -cq --no-verbose https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
					mkdir -p "$HOME/.local"
					rm -rf "$HOME/.local/go"
					tar -C "$HOME/.local" -xzf go1.24.4.linux-amd64.tar.gz
					echo 'export PATH=$PATH:$HOME/.local/go/bin' >> "$HOME/.bashrc"
					echo 'export GOPATH=$HOME/trans/go' >> "$HOME/.bashrc"
					export PATH="$PATH:$HOME/.local/go/bin"
					export GOPATH="$HOME/trans/go"
					rm -f go1.24.4.linux-amd64.tar.gz
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
					if which go >/dev/null 2>&1; then return; fi
					apt-get update
					apt-get install -y wget
					wget -q https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
					rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
					export PATH="$PATH:/usr/local/go/bin"
					echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
					rm -f go1.24.2.linux-amd64.tar.gz
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
	export PATH="$PATH:$HOME/.local/go/bin"
	export GOPATH="$HOME/trans/go"
	return 0
}

execute_program() {
	go run "$@"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
