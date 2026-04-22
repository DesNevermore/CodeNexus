#!/bin/bash
# ===========================================================================
# container.sh — Create a Docker container with all language runtimes.
#
# Usage:
#   container.sh [docker-run-options...]
#
# Environment variables:
#   CONTAINER_USER  — username inside the container  (default: root)
#   DOCKER_IMAGE    — base Docker image              (default: devcontainers/base:jammy)
# ===========================================================================

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/utils/print.sh"

PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

: "${CONTAINER_USER:=root}"
: "${DOCKER_IMAGE:=mcr.microsoft.com/devcontainers/base:jammy}"

if [[ "$CONTAINER_USER" == "root" ]]; then
	CONTAINER_WORKING_DIR="/root/$PROJECT_NAME"
else
	CONTAINER_WORKING_DIR="/home/$CONTAINER_USER/$PROJECT_NAME"
fi

# Reuse the project folder name as the container name if available.
CONTAINER_NAME_OPTIONS=()
if [[ -z "$(docker ps -aqf name="$PROJECT_NAME")" ]]; then
	CONTAINER_NAME_OPTIONS=(--name "$PROJECT_NAME")
fi

CONTAINER_ID="$(docker run -dt -u "$CONTAINER_USER" \
	-v "$PROJECT_DIR:$CONTAINER_WORKING_DIR" -w "$CONTAINER_WORKING_DIR" \
	"${CONTAINER_NAME_OPTIONS[@]}" "$@" "$DOCKER_IMAGE")"

if [[ $? -ne 0 ]]; then
	exit $?
fi

BENCH_BIN="$CONTAINER_WORKING_DIR/scripts/bin/bench"

docker exec -t "$CONTAINER_ID" sh -c "yes | unminimize" \
	&& docker exec -t "$CONTAINER_ID" "$BENCH_BIN" register \
	&& docker exec -t "$CONTAINER_ID" "$BENCH_BIN" install

if [[ $? -ne 0 ]]; then
	exit $?
fi

CONTAINER_NAME="$(docker ps -af id="$CONTAINER_ID" --format '{{.Names}}')"

echo ''
print_success 'Docker container is initialized. Use the following command to access it:'
echo ''
echo "  docker exec -it \"$CONTAINER_NAME\" bash --login"
echo ''
