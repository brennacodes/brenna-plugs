#!/usr/bin/env bash
# approve-tool.sh — PreToolUse hook for the sesh plugin
# Auto-approves:
#   - Read calls targeting files under ~/.claude/
#   - Bash calls that execute sesh.py from this plugin

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin).get('tool_input',{})))" 2>/dev/null || echo "{}")

if [ "$TOOL_NAME" = "Read" ]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path',''))" 2>/dev/null || echo "")
  CLAUDE_DIR="$HOME/.claude/"
  if [[ "$FILE_PATH" == "$CLAUDE_DIR"* ]]; then
    echo '{"decision": "allow"}'
    exit 0
  fi
fi

if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null || echo "")
  if [[ "$COMMAND" == *"${PLUGIN_ROOT}/scripts/sesh.py"* ]]; then
    echo '{"decision": "allow"}'
    exit 0
  fi
fi
