#!/bin/bash
# ===========================================================================
# install.sh — Install language compilers / runtimes.
#
# Usage:
#   install.sh              Install all supported languages
#   install.sh py cpp rs    Install only the listed languages
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

PACKAGES_TO_BE_INSTALL=()

# Callback for language scripts that need apt packages batched together.
install_apt_package() {
	print_info 'These packages will be installed later via apt:' "$@"
	PACKAGES_TO_BE_INSTALL+=("$@")
}

if [[ $# -eq 0 ]]; then
	# Install all available languages.
	while IFS= read -r -d '' FILE; do
		print_info "Installing dependencies with \"$(basename "$FILE")\""
		source "$FILE"
		install_dependency
	done < <(find "$SCRIPT_DIR/languages" -maxdepth 1 -name '*.sh' -print0)
else
	# Install only the requested languages.
	for LANG in "$@"; do
		FILE="$SCRIPT_DIR/languages/$LANG.sh"
		if [[ -e "$FILE" ]]; then
			print_info "Installing dependencies with \"$LANG.sh\""
			source "$FILE"
			install_dependency
		else
			print_warning "unknown language ($LANG)"
		fi
	done
fi

# Flush any batched apt packages.
if [[ "${#PACKAGES_TO_BE_INSTALL[@]}" -gt 0 ]]; then
	apt -q update
	print_info 'Installing the postponed packages via apt:' "${PACKAGES_TO_BE_INSTALL[@]}"
	apt install -y "${PACKAGES_TO_BE_INSTALL[@]}"
fi
