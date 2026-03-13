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

# Resolve ${PLUGIN_PATH:<plugin>@<marketplace>} tokens in a command string.
# Looks up installPath from installed_plugins.json, falls back to glob.
resolve_plugin_paths() {
  local cmd="$1"
  # Nothing to resolve if no token present
  if [[ "$cmd" != *'${PLUGIN_PATH:'* ]]; then
    echo "$cmd"
    return
  fi

  local resolved="$cmd"
  local plugins_json="$HOME/.claude/plugins/installed_plugins.json"

  # Extract each ${PLUGIN_PATH:<key>} token and resolve it
  while [[ "$resolved" =~ \$\{PLUGIN_PATH:([^}]+)\} ]]; do
    local token="${BASH_REMATCH[0]}"
    local key="${BASH_REMATCH[1]}"
    local plugin_name="${key%%@*}"
    local marketplace="${key#*@}"
    local install_path=""

    # Try installed_plugins.json first
    if [[ -f "$plugins_json" ]]; then
      install_path=$(python3 -c "
import json, sys
with open('$plugins_json') as f:
    plugins = json.load(f)
for p in plugins:
    pkg = p.get('package_name', '') or ''
    name = pkg.split('/')[-1] if '/' in pkg else pkg
    if name == '$plugin_name' or pkg == '$plugin_name':
        print(p.get('installPath', ''))
        break
" 2>/dev/null)
    fi

    # Fallback: glob for the plugin in the cache directory
    if [[ -z "$install_path" ]]; then
      local cache_dir="$HOME/.claude/plugins/cache"
      if [[ -d "$cache_dir" ]]; then
        local glob_match
        glob_match=$(find "$cache_dir" -maxdepth 2 -type d -name "$plugin_name" 2>/dev/null | head -1)
        if [[ -n "$glob_match" ]]; then
          install_path="$glob_match"
        fi
      fi
    fi

    if [[ -n "$install_path" ]]; then
      resolved="${resolved//$token/$install_path}"
    else
      # Can't resolve — leave token in place (command will fail with a clear error)
      break
    fi
  done

  echo "$resolved"
}

if [[ -n "$REBUILD_CMD" ]]; then
  REBUILD_CMD=$(resolve_plugin_paths "$REBUILD_CMD")
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
  TAG_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/scripts/rebuild-tags.sh"
  if [[ -f "$TAG_SCRIPT" ]]; then
    export THINGS_PATH
    bash "$TAG_SCRIPT" || true
  fi
fi
