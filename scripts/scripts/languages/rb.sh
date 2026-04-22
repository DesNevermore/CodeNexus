#!/bin/bash
# ===========================================================================
# rb.sh — Language support for Ruby.
# ===========================================================================

install_dependency() {
	apt-get install -y lsb-release
	local os_id os_version
	os_id="$(lsb_release -si)"
	os_version="$(lsb_release -sr)"

	case "$os_id" in
		Ubuntu)
			case "$os_version" in
				20.04)
					echo "Ubuntu $os_version"
					if which ruby >/dev/null 2>&1; then return; fi
					sudo apt update
					sudo apt install -y git curl autoconf bison build-essential \
						libssl-dev libyaml-dev libreadline6-dev zlib1g-dev \
						libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev
					curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
					echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME/.bashrc"
					echo 'eval "$(rbenv init -)"' >> "$HOME/.bashrc"
					export PATH="$HOME/.rbenv/bin:$PATH"
					eval "$(rbenv init -)"
					rbenv install 3.2.2 -f
					rbenv global 3.2.2
					echo 'export PATH="$HOME/.rbenv/shims:$PATH"' >> "$HOME/.bashrc"
					export PATH="$HOME/.rbenv/shims:$PATH"
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
					if which ruby >/dev/null 2>&1; then return; fi
					apt-get update
					apt-get install -y curl
					echo 'export rvm_prefix="$HOME"' >> "$HOME/.rvmrc"
					echo 'export rvm_path="$HOME/.rvm"' >> "$HOME/.rvmrc"
					curl -sSL https://rvm.io/mpapis.asc | gpg --import -
					curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
					curl -sSL https://get.rvm.io | bash -s stable
					export PATH="$PATH:$HOME/.rvm/bin"
					echo 'export PATH="$PATH:$HOME/.rvm/bin"' >> "$HOME/.bashrc"
					echo 'export PATH="$PATH:$HOME/.rvm/rubies/default/bin"' >> "$HOME/.bashrc"
					rvm reload
					rvm --default install ruby-3.2.2
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
	export PATH="$HOME/.rbenv/shims:$PATH"
	ruby -c "$1"
	return $?
}

execute_program() {
	local RUBY_THREAD_VM_STACK_SIZE
	RUBY_THREAD_VM_STACK_SIZE="$(ulimit -s)"
	if [[ ! "$RUBY_THREAD_VM_STACK_SIZE" =~ ^-?[0-9]+$ ]]; then
		RUBY_THREAD_VM_STACK_SIZE=$((1024 * 1024 * 1024))
	else
		RUBY_THREAD_VM_STACK_SIZE=$((RUBY_THREAD_VM_STACK_SIZE * 1024 / 8))
	fi
	export RUBY_THREAD_VM_STACK_SIZE
	ruby "$@"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
