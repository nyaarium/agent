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

# Restore home-seed contents into mounted home when missing
chown -R vscode:vscode /var/home-seed/
for item in /var/home-seed/.* /var/home-seed/*; do
	name=$(basename "$item")
	case "$name" in .|..|.bashrc) continue ;; esac
	[ -e "$item" ] && [ ! -e "/home/vscode/$name" ] && mv "$item" "/home/vscode/$name"
done
rm -rf /var/home-seed

# Fix ownership on anything not already owned by vscode
find /home/vscode \( ! -user vscode -o ! -group vscode \) -exec chown vscode:vscode {} +
