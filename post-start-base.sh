#!/bin/bash

# Post-start script for devcontainer

set -e


# Remind user if git identity is not configured
GIT_NAME=$(git config --global user.name 2>/dev/null || true)
GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
	echo ""
	echo "Set your git identity with:"
	echo "   git config --global user.name \"Your Name\""
	echo "   git config --global user.email \"your@email.com\""
	echo ""
fi


# Agent Team Bridge - clone or update, rebuild if changed
ATB_URL="https://github.com/atelier-nyaarium/agent-team-bridge.git"
ATB_REPO="$HOME/agent-team-bridge"
ATB_BIN="$ATB_REPO/build/agent-team-bridge"
if [ ! -d "$ATB_REPO/.git" ]; then
	git clone --depth 1 "$ATB_URL" "$ATB_REPO"
	NEEDS_BUILD=1
else
	OLD_HEAD=$(git -C "$ATB_REPO" rev-parse HEAD)
	git -C "$ATB_REPO" fetch --prune
	git -C "$ATB_REPO" reset --hard origin/main
	NEW_HEAD=$(git -C "$ATB_REPO" rev-parse HEAD)
	[ "$OLD_HEAD" != "$NEW_HEAD" ] && NEEDS_BUILD=1 || NEEDS_BUILD=0
fi
if [ "$NEEDS_BUILD" = "1" ] || [ ! -f "$ATB_BIN" ]; then
	cd "$ATB_REPO"
	"$HOME/.bun/bin/bun" install
	"$HOME/.bun/bin/bun" build --compile src/main.ts --outfile="$ATB_BIN"
fi
