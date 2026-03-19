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
