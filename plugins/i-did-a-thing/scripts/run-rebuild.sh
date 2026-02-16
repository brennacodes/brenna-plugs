#!/usr/bin/env bash
# Thin wrapper called by PostToolUse hook after a Write.
# Reads things_path from the centralized trio config and triggers
# rebuild-data.py only when the written file is a log.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only rebuild for writes to */logs/*.md
if [[ -z "$FILE_PATH" || ! "$FILE_PATH" =~ /logs/[^/]*\.md$ ]]; then
  exit 0
fi

CONFIG_FILE=".claude/trio.local.md"

if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

# Extract things_path from trio bootstrap config
THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)

if [[ -z "$THINGS_PATH" ]]; then
  exit 0
fi

THINGS_PATH="${THINGS_PATH/#\~/$HOME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/rebuild-data.py" "$THINGS_PATH"
