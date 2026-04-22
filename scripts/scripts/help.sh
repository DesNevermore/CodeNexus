#!/bin/bash
# ===========================================================================
# help.sh — Display usage information for bench commands.
#
# Usage:
#   help.sh             Show general help
#   help.sh <command>   Show help for a specific command
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

COMMAND="$1"

if [[ -n "$COMMAND" ]]; then
	if [[ ! "$COMMAND" =~ ^[a-z]+$ ]]; then
		print_error "invalid command: $COMMAND"
		COMMAND=""
	elif [[ ! -e "$SCRIPT_DIR/$COMMAND.sh" ]]; then
		print_error "unknown command: $COMMAND"
		COMMAND=""
	fi
fi

help_for_command() {
	if [[ "$COMMAND" == "$1" ]]; then
		echo ''
		cat -
	fi
}

# --- General help ----------------------------------------------------------
help_for_command '' << 'EOF'
Usage:
  bench <command> [<args>]

Valid bench commands:
  test          Evaluate a submission with test cases
  run           Alias for the command `test`
  exec          Execute the source code of a submission
  gen           Generate test cases for a benchmark
  install       Install compilers for supported programming languages
  register      Register the bench command in your shell profile
  container     Create a Docker container with language compilers installed
  help          Show this help message

Run 'bench help <command>' for more information on a command.
EOF

[[ "$COMMAND" == 'run' ]] && COMMAND='test'

# --- bench test / bench run ------------------------------------------------
help_for_command 'test' << 'EOF'
Usage:
  bench test <source-code> <test-case> [verifier]
  bench test <benchmark>

The second usage is equivalent to:
  bench test <benchmark>/src <benchmark>/test [<benchmark>/verifier.cpp]

Arguments:
  <source-code>     Path to the source code file, the src/ directory in the
                    benchmark, or the benchmark directory.
  <test-case>       Path to a single input file, a directory with input/answer
                    file pairs, or the benchmark directory.
  [verifier]        Path to a custom verifier (.cpp source using "testlib.h").
  <benchmark>       A benchmark directory containing both source files and
                    test case files.

Environment Variables:
  TIMEOUT_DURATION  Maximum time allowed per test case (default: '10s').
  TIMEOUT_SIGNAL    Signal sent on timeout (default: 'SIGTERM').

Aliases:
  bench run
EOF

# --- bench exec ------------------------------------------------------------
help_for_command 'exec' << 'EOF'
Usage:
  bench exec <source-code>

Arguments:
  <source-code>     Path to the source code file.

Environment Variables:
  TIMEOUT_DURATION  Maximum time allowed for execution (default: '',
                    i.e., no timeout guard).
  TIMEOUT_SIGNAL    Signal sent on timeout (default: 'SIGTERM').

Compiler output is redirected to stderr. The program reads from stdin and
writes to stdout.
EOF

# --- bench gen -------------------------------------------------------------
help_for_command 'gen' << 'EOF'
Usage:
  bench gen <dir>

Arguments:
  <dir>             Path to the benchmark directory. All files matching
                    "gentest*.sh" in the directory tree will be executed.
EOF

# --- bench install ---------------------------------------------------------
help_for_command 'install' << 'EOF'
Usage:
  bench install [languages...]

Arguments:
  [languages...]    Language extensions (e.g., py cpp rs) to install.
                    If omitted, all available languages will be installed.
EOF

# --- bench register --------------------------------------------------------
help_for_command 'register' << 'EOF'
Usage:
  bench register [--stdout | --system | <profile>]

Arguments:
  <profile>         Profile path to write the registration script to.
                    Defaults to ~/.bashrc or ~/.profile.

Options:
  --stdout          Print the registration script without writing to a file.
  --system          Register system-wide (writes to /etc/profile.d/bench.sh).

For temporary registration in the current session:
  eval "$(/path/to/scripts/bin/bench register --stdout)"
EOF

# --- bench container -------------------------------------------------------
help_for_command 'container' << 'EOF'
Usage:
  bench container [options]

Arguments:
  [options]         Options forwarded to `docker run`.

Environment Variables:
  CONTAINER_USER    Username inside the container (default: 'root').
  DOCKER_IMAGE      Base Docker image
                    (default: 'mcr.microsoft.com/devcontainers/base:jammy').
EOF

# --- bench help ------------------------------------------------------------
help_for_command 'help' << 'EOF'
Usage:
  bench help [command]

Arguments:
  [command]         The command to show help for.
EOF
