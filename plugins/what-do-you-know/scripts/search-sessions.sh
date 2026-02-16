#!/usr/bin/env bash
# Search and filter learning sessions.
#
# Usage:
#   search-sessions.sh [--type explore|quiz] [--topic TOPIC]
#                      [--persona PERSONA] [--since DATE]
#                      [--recent N] [--min-score N]
#
# Examples:
#   search-sessions.sh --recent 10
#   search-sessions.sh --type quiz --topic architecture
#   search-sessions.sh --topic "distributed systems" --since 2025-01-01

set -euo pipefail

CONFIG_FILE="$HOME/.claude/things.local.md"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "No config found" >&2
  exit 1
fi

THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)
THINGS_PATH="${THINGS_PATH/#\~/$HOME}"
SESSIONS_DIR="$THINGS_PATH/learning/sessions"

if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "No sessions directory found at $SESSIONS_DIR" >&2
  exit 1
fi

# Parse arguments
TYPE=""
TOPIC=""
PERSONA=""
SINCE=""
RECENT=""
MIN_SCORE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2 ;;
    --topic) TOPIC="$2"; shift 2 ;;
    --persona) PERSONA="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --recent) RECENT="$2"; shift 2 ;;
    --min-score) MIN_SCORE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Search each session file
RESULTS=""
for session in "$SESSIONS_DIR"/*.md; do
  [[ -f "$session" ]] || continue

  match=true

  if [[ -n "$TYPE" ]]; then
    grep -q "^type: .*${TYPE}" "$session" 2>/dev/null || match=false
  fi

  if [[ -n "$TOPIC" ]]; then
    grep -qi "^topic: .*${TOPIC}" "$session" 2>/dev/null || match=false
  fi

  if [[ -n "$PERSONA" ]]; then
    grep -q "^persona: .*${PERSONA}" "$session" 2>/dev/null || match=false
  fi

  if [[ -n "$SINCE" ]]; then
    file_date=$(sed -n 's/^date: *\(.*\)$/\1/p' "$session" | head -1)
    if [[ -n "$file_date" && "$file_date" < "$SINCE" ]]; then
      match=false
    fi
  fi

  if [[ -n "$MIN_SCORE" ]]; then
    overall=$(sed -n 's/^  overall: *\(.*\)$/\1/p' "$session" | head -1)
    if [[ -n "$overall" ]]; then
      if (( $(echo "$overall < $MIN_SCORE" | bc -l 2>/dev/null || echo "0") )); then
        match=false
      fi
    fi
  fi

  if $match; then
    date=$(sed -n 's/^date: *\(.*\)$/\1/p' "$session" | head -1)
    type=$(sed -n 's/^type: *"\?\(.*\)"\?$/\1/p' "$session" | head -1)
    topic=$(sed -n 's/^topic: *"\?\(.*\)"\?$/\1/p' "$session" | head -1)
    overall=$(sed -n 's/^  overall: *\(.*\)$/\1/p' "$session" | head -1)
    persona=$(sed -n 's/^persona: *"\?\(.*\)"\?$/\1/p' "$session" | head -1)
    RESULTS="${RESULTS}${date} | ${type} | ${topic} | ${overall:-?}/5 | ${persona} | $(basename "$session")\n"
  fi
done

# Sort by date (most recent first) and apply --recent limit
OUTPUT=$(echo -e "$RESULTS" | sort -r)

if [[ -n "$RECENT" && -n "$OUTPUT" ]]; then
  OUTPUT=$(echo "$OUTPUT" | head -n "$RECENT")
fi

if [[ -z "$OUTPUT" ]]; then
  echo "No matching sessions found"
else
  echo "$OUTPUT"
fi
