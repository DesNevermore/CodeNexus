#!/bin/bash
# ===========================================================================
# rs.sh — Language support for Rust.
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
					sudo apt-get install -y rustc cargo
					export CARGO_HOME="$HOME/.cargo"
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
					apt-get install -y rustc cargo
					export CARGO_HOME="$HOME/.cargo"
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
	local CURRENT_TMPDIR="$(dirname "$1")"
	local CONFIG_TMPFILE="$CURRENT_TMPDIR/Cargo.toml"

	cat > "$CONFIG_TMPFILE" <<-TOML
		[package]
		name = "Main"
		version = "0.1.0"
		edition = "2021"

		[dependencies]
		serde = { version = "1.0", features = ["derive"] }
		serde_json = "1.0"

		[[bin]]
		name = "Main"
		path = "$1"
	TOML

	local CURRENT_DIR="$PWD"
	cd "$CURRENT_TMPDIR" \
		&& RUSTFLAGS="-C link-args=-zstack-size=268435456 -A non_snake_case" \
			cargo build --release >/dev/null \
		&& cd "$CURRENT_DIR"
	return $?
}

execute_program() {
	local EXECUTABLE="$(dirname "$1")/target/release/Main"
	"$EXECUTABLE" "${@:2}"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
