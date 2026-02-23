#!/usr/bin/env bash
# PostToolUse hook: dispatch rebuild_command for affected collections.
#
# Reads registry.json, matches the written file path against registered
# collections (longest prefix match), and invokes the collection's
# rebuild_command if present.
#
# Exits early and cheaply for files outside .things/.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Convention path - no bootstrap needed
THINGS_PATH="$HOME/.things"

if [[ ! -d "$THINGS_PATH" ]]; then
  exit 0
fi

# Check if the file is inside .things/
case "$FILE_PATH" in
  "$THINGS_PATH"/*) ;;
  *) exit 0 ;;
esac

REGISTRY="$THINGS_PATH/registry.json"
if [[ ! -f "$REGISTRY" ]]; then
  exit 0
fi

# Get relative path within .things/
REL_PATH="${FILE_PATH#$THINGS_PATH/}"

# Find matching collection (longest prefix) and its rebuild_command
REBUILD_CMD=$(python3 -c "
import json, sys
with open('$REGISTRY') as f:
    reg = json.load(f)
rel = '$REL_PATH'
best_match = ''
best_cmd = None
for path, col in reg.get('collections', {}).items():
    if rel.startswith(path + '/') and len(path) > len(best_match):
        best_match = path
        best_cmd = col.get('rebuild_command')
if best_cmd:
    print(best_cmd)
" 2>/dev/null)

if [[ -n "$REBUILD_CMD" ]]; then
  export THINGS_PATH
  eval "$REBUILD_CMD" || true
fi

# Rebuild central tag index if the affected collection declares tags_field
HAS_TAGS=$(python3 -c "
import json
with open('$REGISTRY') as f:
    reg = json.load(f)
rel = '$REL_PATH'
for path, col in reg.get('collections', {}).items():
    if rel.startswith(path + '/') and col.get('tags_field'):
        print('yes')
        break
" 2>/dev/null)

if [[ "$HAS_TAGS" == "yes" ]]; then
  TAG_SCRIPT="$THINGS_PATH/tags/rebuild-tags.sh"
  if [[ -x "$TAG_SCRIPT" ]]; then
    export THINGS_PATH
    bash "$TAG_SCRIPT" || true
  fi
fi
