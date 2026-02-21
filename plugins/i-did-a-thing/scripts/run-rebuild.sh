#!/usr/bin/env bash
# Thin wrapper called by HTT's PostToolUse hook via registry rebuild_command.
# Triggers rebuild-data.py to regenerate index, tags, and arsenal.
#
# Can also be invoked directly: run-rebuild.sh
# Or via registry: rebuild_command in registry.json

set -euo pipefail

# Convention path - no bootstrap needed
THINGS_PATH="${THINGS_PATH:-$HOME/.things}"

if [[ ! -d "$THINGS_PATH" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/rebuild-data.py" "$THINGS_PATH"
