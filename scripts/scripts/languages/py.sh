#!/bin/bash
# ===========================================================================
# py.sh — Language support for Python.
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
					sudo apt-get install -y python3 python3-pip python3-venv
					export PATH="$HOME/.local/bin:$PATH"
					local venv_dir="$HOME/trans"
					if [[ ! -d "$venv_dir" ]]; then
						python3 -m venv "$venv_dir"
					fi
					source "$venv_dir/bin/activate"
					pip install --upgrade pip
					pip install psutil pandas deepdiff astor
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
					apt-get install -y python3 python3-pip python3-venv
					cd "$HOME" && python3 -m venv trans
					source "$HOME/trans/bin/activate" && pip3 install psutil pandas
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
	source "$HOME/trans/bin/activate" && python3 -m py_compile "$1"
	return $?
}

execute_program() {
	source "$HOME/trans/bin/activate" && python3 "$@"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
