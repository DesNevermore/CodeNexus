#!/bin/bash
# ===========================================================================
# cs.sh — Language support for C#.
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
					if which dotnet >/dev/null 2>&1; then return; fi
					sudo apt-get update
					sudo apt-get install -y wget
					wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
					sudo dpkg -i packages-microsoft-prod.deb
					sudo apt-get update
					sudo apt-get install -y dotnet-sdk-9.0
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
					apt-get install -y wget
					wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
					dpkg -i packages-microsoft-prod.deb
					apt-get update
					apt-get install -y dotnet-sdk-9.0
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
	local DIR_PATH="$(dirname "$1")"
	dotnet new console -v q -o "$DIR_PATH/Main" --force
	cp "$1" "$DIR_PATH/Main/Program.cs"
	dotnet add package Newtonsoft.Json
	dotnet build -p:UseSharedCompilation=false -p:Nullable=disable \
		-c Release -o "$DIR_PATH/publish" -v q --nologo "$DIR_PATH/Main/Main.csproj"
	return $?
}

execute_program() {
	local DIR_PATH="$(dirname "$1")"
	local EXECUTABLE="$DIR_PATH/publish/Main"
	"$EXECUTABLE" "${@:2}"
	return $?
}

export -f install_dependency
export -f compile_program
export -f execute_program
