#!/bin/bash
# ===========================================================================
# js.sh — Language support for JavaScript (Node.js).
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
					if which node >/dev/null 2>&1; then return; fi
					sudo apt-get update
					sudo apt-get install -y curl
					curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
					NVM_DIR="${HOME}/.nvm"
					[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
					nvm install --lts
					nvm install 18.20.8
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
					if which node >/dev/null 2>&1; then return; fi
					apt-get update
					apt-get install -y curl
					curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
					NVM_DIR="${HOME}/.nvm"
					[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
					nvm install --lts
					nvm install 18.20.8
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
	NVM_DIR="${HOME}/.nvm"
	[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
	nvm use 18.20.8 >/dev/null
	node --check "$1"
	return $?
}

execute_program() {
	local STACK_SIZE
	STACK_SIZE="$(ulimit -s)"
	if [[ ! "$STACK_SIZE" =~ ^-?[0-9]+$ ]]; then
		STACK_SIZE=$((1024 * 1024))
	fi
	node --stack-size="$STACK_SIZE" "$@"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
