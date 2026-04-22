#!/bin/bash
# ===========================================================================
# java.sh — Language support for Java.
# ===========================================================================

install_dependency() {
	sudo apt-get install -y lsb-release wget
	local os_id os_version
	os_id="$(lsb_release -si)"
	os_version="$(lsb_release -sr)"

	case "$os_id" in
		Ubuntu)
			case "$os_version" in
				20.04)
					echo "Ubuntu $os_version"
					sudo apt-get update
					sudo apt-get install -y openjdk-17-jdk
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
					apt-get install -y openjdk-17-jdk
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
	local JACKSON_VERSION="2.15.2"
	local JACKSON_DIR="$HOME/tmp/jackson-$JACKSON_VERSION"
	local JACKSON_FILES=(
		"jackson-annotations-$JACKSON_VERSION.jar"
		"jackson-core-$JACKSON_VERSION.jar"
		"jackson-databind-$JACKSON_VERSION.jar"
	)
	local JACKSON_BASE_URL="https://repo1.maven.org/maven2/com/fasterxml/jackson/core"

	mkdir -p "$JACKSON_DIR"
	for file in "${JACKSON_FILES[@]}"; do
		local path="$JACKSON_DIR/$file"
		if [[ ! -f "$path" ]]; then
			wget -O "$path" "$JACKSON_BASE_URL/${file%-*}/$JACKSON_VERSION/$file"
		fi
	done

	local JACKSON_CP="$JACKSON_DIR/jackson-annotations-$JACKSON_VERSION.jar"
	JACKSON_CP="$JACKSON_CP:$JACKSON_DIR/jackson-core-$JACKSON_VERSION.jar"
	JACKSON_CP="$JACKSON_CP:$JACKSON_DIR/jackson-databind-$JACKSON_VERSION.jar"

	local DIR_PATH="$(dirname "$1")"
	javac -encoding UTF-8 -Xlint:unchecked \
		-sourcepath "$DIR_PATH" -d "$DIR_PATH" \
		-classpath "$JACKSON_CP" "$1"
	return $?
}

execute_program() {
	local JACKSON_VERSION="2.15.2"
	local JACKSON_DIR="$HOME/tmp/jackson-$JACKSON_VERSION"
	local JACKSON_CP="$JACKSON_DIR/jackson-annotations-$JACKSON_VERSION.jar"
	JACKSON_CP="$JACKSON_CP:$JACKSON_DIR/jackson-core-$JACKSON_VERSION.jar"
	JACKSON_CP="$JACKSON_CP:$JACKSON_DIR/jackson-databind-$JACKSON_VERSION.jar"

	local ORIGINAL_PWD="$PWD"
	cd "$(dirname "$1")" || return 1
	java -Dfile.encoding=UTF-8 -XX:+UseSerialGC -Xss64m -Xms1920m -Xmx1920m \
		-classpath ".:$JACKSON_CP" Main
	local EXIT_CODE=$?
	cd "$ORIGINAL_PWD" || return 1
	return $EXIT_CODE
}

export -f install_dependency
export -f compile_program
export -f execute_program
