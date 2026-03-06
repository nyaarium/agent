#!/bin/bash

# Post-create script for devcontainer

set -e

DEBUG_LOG="/tmp/home-seed-debug.log"
echo "=== HOME SEED $(date) ===" > "$DEBUG_LOG"

chown vscode:vscode /workspace

# Include finalize debug log if available
if [ -f /var/finalize-debug.log ]; then
	cat /var/finalize-debug.log >> "$DEBUG_LOG"
	echo "" >> "$DEBUG_LOG"
fi

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
echo "--- /home/vscode/.bun/bin/ BEFORE merge ---" >> "$DEBUG_LOG"
ls -la /home/vscode/.bun/bin/ >> "$DEBUG_LOG" 2>&1 || echo "  (not found)" >> "$DEBUG_LOG"
echo "" >> "$DEBUG_LOG"

chown -R vscode:vscode /var/home-seed/
rsync -a --exclude='/.bashrc' /var/home-seed/ /home/vscode/
rm -rf /var/home-seed

echo "--- /home/vscode/.bun/bin/ AFTER merge ---" >> "$DEBUG_LOG"
ls -la /home/vscode/.bun/bin/ >> "$DEBUG_LOG" 2>&1 || echo "  (not found)" >> "$DEBUG_LOG"
echo "=== END ===" >> "$DEBUG_LOG"

# Fix ownership on anything not already owned by vscode
find /home/vscode \( ! -user vscode -o ! -group vscode \) -exec chown vscode:vscode {} +
