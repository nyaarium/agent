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

# Restore Cursor/Claude/Copilot agent installs from image into mounted home when missing
if [ -d /var/home-seed/.local ]; then
	if [ ! -d /home/vscode/.local ]; then
		cp -a /var/home-seed/.local /home/vscode/.local
	elif [ ! -d /home/vscode/.local/share/cursor-agent ] || [ ! -d /home/vscode/.local/share/claude ]; then
		mkdir -p /home/vscode/.local/share /home/vscode/.local/bin
		[ -d /var/home-seed/.local/share/cursor-agent ] && cp -a /var/home-seed/.local/share/cursor-agent /home/vscode/.local/share/
		[ -d /var/home-seed/.local/share/claude ] && cp -a /var/home-seed/.local/share/claude /home/vscode/.local/share/
		[ -L /var/home-seed/.local/bin/agent ] && cp -a /var/home-seed/.local/bin/agent /var/home-seed/.local/bin/cursor-agent /var/home-seed/.local/bin/claude /home/vscode/.local/bin/ 2>/dev/null || true
	fi
fi
if [ -d /var/home-seed/.claude ] && [ ! -d /home/vscode/.claude ]; then
	cp -a /var/home-seed/.claude /home/vscode/.claude
fi
if [ -d /var/home-seed/.bun ] && [ ! -d /home/vscode/.bun ]; then
	cp -a /var/home-seed/.bun /home/vscode/.bun
fi
[ -d /home/vscode/.bun ] && chown -R vscode:vscode /home/vscode/.bun || true
[ -d /home/vscode/.local ] && chown -R vscode:vscode /home/vscode/.local || true
[ -d /home/vscode/.claude ] && chown -R vscode:vscode /home/vscode/.claude || true
[ -d /home/vscode/.cursor ] && chown -R vscode:vscode /home/vscode/.cursor || true
[ -d /home/vscode/.vscode ] && chown -R vscode:vscode /home/vscode/.vscode || true

sudo chown vscode:vscode /workspace
