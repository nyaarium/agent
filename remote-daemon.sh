#!/bin/bash

set -e


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
DEVCONTAINER_NAME="${PROJECT_NAME}_devcontainer"
TMUX_SESSION="claude"


# Ensure container is running
if [ -z "$(docker compose -p "$DEVCONTAINER_NAME" ps -q 2>/dev/null)" ]; then
	echo "Devcontainer not running. Starting..."
	docker compose -p "$DEVCONTAINER_NAME" down 2>/dev/null || true
	devcontainer build --workspace-folder "$SCRIPT_DIR"
	devcontainer up --workspace-folder "$SCRIPT_DIR"
	devcontainer run-user-commands --workspace-folder "$SCRIPT_DIR"
fi


CONTAINER_ID=$(docker compose -p "$DEVCONTAINER_NAME" ps -q dev 2>/dev/null | head -1)


# Check if tmux session already exists
if docker exec -u vscode "$CONTAINER_ID" tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
	echo "Session '${TMUX_SESSION}' already running in ${PROJECT_NAME}."
	echo "  Attach: docker exec -it -u vscode $CONTAINER_ID tmux attach -t $TMUX_SESSION"
	exit 0
fi


echo "Starting claude remote-control in ${PROJECT_NAME}..."
docker exec -d -u vscode "$CONTAINER_ID" \
	tmux new-session -d -s "$TMUX_SESSION" "source ~/.bashrc; cd /workspace/${PROJECT_NAME}; claude-skip remote-control --name '${PROJECT_NAME}'; exec bash"

# Wait for Claude to start, auto-accept dev channels prompt if it appears
for i in $(seq 1 10); do
	sleep 1
	SCREEN=$(docker exec -u vscode "$CONTAINER_ID" tmux capture-pane -t "$TMUX_SESSION" -p 2>/dev/null || true)
	if echo "$SCREEN" | grep -q "Claude Code"; then
		break
	fi
	if echo "$SCREEN" | grep -q "Loading development channels"; then
		docker exec -u vscode "$CONTAINER_ID" tmux send-keys -t "$TMUX_SESSION" Enter
	fi
done


if docker exec -u vscode "$CONTAINER_ID" tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
	echo "Claude running in background."
	echo "  Attach: docker exec -it -u vscode $CONTAINER_ID tmux attach -t $TMUX_SESSION"
else
	echo "ERROR: tmux session failed to start. Debug with:"
	echo "  docker exec -it -u vscode $CONTAINER_ID bash"
fi
