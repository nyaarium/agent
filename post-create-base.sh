#!/bin/bash

# Post-create script for devcontainer

set -e


# Restore bashrc from image stash with version check
BASHRC_SRC="/var/home-seed/.bashrc"
BASHRC_DST="/home/vscode/.bashrc"
if [ -f "$BASHRC_SRC" ]; then
	VERSION_STRING=$(grep -o "Devcontainer: v.*" "$BASHRC_SRC" | head -n1)
	if [ ! -f "$BASHRC_DST" ]; then
		cp "$BASHRC_SRC" "$BASHRC_DST"
		chmod 644 "$BASHRC_DST"
	elif [ -n "$VERSION_STRING" ] && ! grep -q "$VERSION_STRING" "$BASHRC_DST" 2>/dev/null; then
		cp "$BASHRC_SRC" "$BASHRC_DST"
		chmod 644 "$BASHRC_DST"
	fi
fi


# Merge home-seed into mounted home (seed versions win over stale volume copies)
chown -R vscode:vscode /var/home-seed/
rsync -a --ignore-existing --exclude='/.bashrc' /var/home-seed/ /home/vscode/
rm -rf /var/home-seed


# Ensure base gitconfig settings
su -c 'git config --global safe.directory /workspace' vscode
su -c 'git config --global commit.gpgSign 2>/dev/null'  || su -c 'git config --global commit.gpgSign false' vscode
su -c 'git config --global init.defaultBranch 2>/dev/null' || su -c 'git config --global init.defaultBranch main' vscode


# Detect and set editor
if su -c 'which cursor' vscode >/dev/null 2>&1; then
	DETECTED_EDITOR="cursor --wait"
	su -c "git config --global core.editor '$DETECTED_EDITOR'" vscode
elif su -c 'which code' vscode >/dev/null 2>&1; then
	DETECTED_EDITOR="code --wait"
	su -c "git config --global core.editor '$DETECTED_EDITOR'" vscode
fi


# Trust workspace for Claude Code, Cursor, and Copilot
if [ -n "$PROJECT_NAME" ] && command -v jq >/dev/null 2>&1; then
	WORKSPACE_PATH="/workspace/$PROJECT_NAME"

	# Claude Code: ~/.claude.json
	CLAUDE_JSON="/home/vscode/.claude.json"
	[ ! -f "$CLAUDE_JSON" ] && echo '{}' > "$CLAUDE_JSON"
	UPDATED=$(jq --arg path "$WORKSPACE_PATH" '
		.projects[$path] //= {} |
		.projects[$path].hasTrustDialogAccepted = true
	' "$CLAUDE_JSON")
	echo "$UPDATED" > "$CLAUDE_JSON"

	# Cursor: ~/.cursor/projects/<folder-name>/.workspace-trusted
	FOLDER_NAME=$(echo "$WORKSPACE_PATH" | sed 's|^/||; s|/|-|g')
	CURSOR_DIR="/home/vscode/.cursor/projects/$FOLDER_NAME"
	CURSOR_TRUST="$CURSOR_DIR/.workspace-trusted"
	if [ ! -f "$CURSOR_TRUST" ]; then
		mkdir -p "$CURSOR_DIR"
		jq -n --arg path "$WORKSPACE_PATH" '{trustedAt: (now | todate), workspacePath: $path}' > "$CURSOR_TRUST"
	fi

	# Copilot: ~/.copilot/config.json
	COPILOT_JSON="/home/vscode/.copilot/config.json"
	if [ ! -f "$COPILOT_JSON" ]; then
		mkdir -p /home/vscode/.copilot
		echo '{}' > "$COPILOT_JSON"
	fi
	UPDATED=$(jq --arg path "$WORKSPACE_PATH" '
		.trusted_folders //= [] |
		if (.trusted_folders | index($path)) then . else .trusted_folders += [$path] end
	' "$COPILOT_JSON")
	echo "$UPDATED" > "$COPILOT_JSON"

	chown -R vscode:vscode /home/vscode/.claude.json /home/vscode/.cursor /home/vscode/.copilot
fi


# Fix ownership on anything not already owned by vscode (skip scripts mount from host)
chown vscode:vscode /workspace
find /home/vscode -name scripts -prune -o \( ! -user vscode -o ! -group vscode \) -exec chown vscode:vscode {} +
