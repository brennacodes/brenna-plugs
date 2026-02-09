#!/usr/bin/env bash
# Search and filter interview practice/mock sessions.
#
# Usage:
#   search-sessions.sh [--type practice|mock] [--category CAT]
#                      [--persona PERSONA] [--since DATE]
#                      [--company COMPANY] [--recent N]
#                      [--question-id ID] [--min-score N]
#
# Examples:
#   search-sessions.sh --recent 10
#   search-sessions.sh --type mock --company amazon
#   search-sessions.sh --category behavioral --since 2025-01-01
#   search-sessions.sh --question-id beh-001

set -euo pipefail

CONFIG_FILE=".claude/what-did-you-do.local.md"

if [[ ! -f "$CONFIG_FILE" ]]; then
  # Fall back to i-did-a-thing config for things_path
  CONFIG_FILE=".claude/i-did-a-thing.local.md"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "No config found" >&2
    exit 1
  fi
fi

THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)
THINGS_PATH="${THINGS_PATH/#\~/$HOME}"
SESSIONS_DIR="$THINGS_PATH/interview-prep/sessions"

if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "No sessions directory found at $SESSIONS_DIR" >&2
  exit 1
fi

# Parse arguments
TYPE=""
CATEGORY=""
PERSONA=""
SINCE=""
COMPANY=""
RECENT=""
QUESTION_ID=""
MIN_SCORE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --persona) PERSONA="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --company) COMPANY="$2"; shift 2 ;;
    --recent) RECENT="$2"; shift 2 ;;
    --question-id) QUESTION_ID="$2"; shift 2 ;;
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

  if [[ -n "$CATEGORY" ]]; then
    grep -q "^question_category: .*${CATEGORY}" "$session" 2>/dev/null || match=false
  fi

  if [[ -n "$PERSONA" ]]; then
    grep -q "^persona: .*${PERSONA}" "$session" 2>/dev/null || match=false
  fi

  if [[ -n "$COMPANY" ]]; then
    grep -qi "$COMPANY" "$session" 2>/dev/null || match=false
  fi

  if [[ -n "$QUESTION_ID" ]]; then
    grep -q "^question_id: .*${QUESTION_ID}" "$session" 2>/dev/null || match=false
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
    category=$(sed -n 's/^question_category: *"\?\(.*\)"\?$/\1/p' "$session" | head -1)
    overall=$(sed -n 's/^  overall: *\(.*\)$/\1/p' "$session" | head -1)
    persona=$(sed -n 's/^persona: *"\?\(.*\)"\?$/\1/p' "$session" | head -1)
    qid=$(sed -n 's/^question_id: *"\?\(.*\)"\?$/\1/p' "$session" | head -1)
    RESULTS="${RESULTS}${date} | ${type} | ${category} | ${overall:-?}/5 | ${persona} | ${qid} | $(basename "$session")\n"
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
