#!/bin/bash

# Post-create script for devcontainer

set -e

chown vscode:vscode /workspace

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
rsync -a --exclude='/.bashrc' /var/home-seed/ /home/vscode/
rm -rf /var/home-seed

# Fix ownership on anything not already owned by vscode (skip scripts mount from host)
find /home/vscode -name scripts -prune -o \( ! -user vscode -o ! -group vscode \) -exec chown vscode:vscode {} +
