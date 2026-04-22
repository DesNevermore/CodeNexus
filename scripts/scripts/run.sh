#!/bin/bash
# ===========================================================================
# run.sh — Alias for the `test` command.
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

"$SCRIPT_DIR/test.sh" "$@"
