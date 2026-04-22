#!/bin/bash
# ===========================================================================
# bash_completion.sh — Tab-completion for the `bench` command.
# ===========================================================================

_bench_completion() {
	if [[ -z "$BENCH_SCRIPT_DIR" ]]; then
		return 1
	fi

	local BENCH_COMMANDS BENCH_LANGUAGES

	_find_script_names() {
		find "$@" -maxdepth 1 -name '*.sh' -type f -printf '%f\n' | sed -n 's/.sh$//p'
	}

	BENCH_COMMANDS="$(_find_script_names "$BENCH_SCRIPT_DIR")"
	BENCH_LANGUAGES="$(_find_script_names "$BENCH_SCRIPT_DIR/languages")"

	# First argument: complete command names.
	if [[ "$COMP_CWORD" -eq 1 ]]; then
		COMPREPLY=($(compgen -W "$BENCH_COMMANDS" -- "${COMP_WORDS[COMP_CWORD]}"))
		return 0
	fi

	# Subsequent arguments: context-dependent.
	COMPREPLY=()
	case "${COMP_WORDS[1]}" in
		run)      return $((COMP_CWORD <= 4 ? 1 : 0));;
		exec)     return $((COMP_CWORD <= 2 ? 1 : 0));;
		gen)      return $((COMP_CWORD <= 2 ? 1 : 0));;
		install)
			COMPREPLY=($(compgen -W "$BENCH_LANGUAGES" -- "${COMP_WORDS[COMP_CWORD]}"))
			return 0
			;;
		register) return $((COMP_CWORD <= 2 ? 1 : 0));;
		help)
			if [[ "$COMP_CWORD" -le 2 ]]; then
				COMPREPLY=($(compgen -W "$BENCH_COMMANDS" -- "${COMP_WORDS[COMP_CWORD]}"))
			fi
			return 0
			;;
		*) return 1;;
	esac
}

complete -F _bench_completion -o bashdefault -o default bench
