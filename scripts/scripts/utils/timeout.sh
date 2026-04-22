#!/bin/bash
# ===========================================================================
# timeout.sh — Provides a timeout guard wrapper for program execution.
#
# Usage (after sourcing):
#   with_timeout_guard <command> [args...]
#
# Environment variables:
#   TIMEOUT_DURATION  — e.g. "10s", "500ms" (empty = no timeout)
#   TIMEOUT_SIGNAL    — signal to send on timeout (default: SIGTERM)
# ===========================================================================

with_timeout_guard() (
	# Run in a sub-shell to:
	#   1. Suppress job-control messages.
	#   2. Avoid interrupting other processes in the parent shell.
	if [[ -n "$TIMEOUT_DURATION" ]]; then
		if [[ ! "$TIMEOUT_DURATION" =~ ^[.0-9]+[smhd]?$ ]]; then
			echo "invalid duration: $TIMEOUT_DURATION" >&2
			return 255
		fi

		local THIS_PID
		THIS_PID="$("$SHELL" -c 'echo "$PPID"')"

		with_timeout_guard::kill() {
			local SIGNAL="$1"
			local PARENT_PID="$2"
			pkill --signal "$SIGNAL" -P "$PARENT_PID"
		}

		# Spawn a background guard that kills the child after the timeout.
		(
			sleep "$TIMEOUT_DURATION" && \
			with_timeout_guard::kill "${TIMEOUT_SIGNAL:-SIGTERM}" "$THIS_PID"
		) 2>/dev/null &
		disown
		trap 'with_timeout_guard::kill SIGTERM $! 2>/dev/null' EXIT
	fi

	(
		: # Force a new sub-shell so the timeout signal is received correctly.
		"$@"
	)
	return $?
)
