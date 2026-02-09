#!/usr/bin/env bash
# Search and filter things logs by various criteria.
#
# Usage:
#   search-things.sh [--tag TAG] [--skill SKILL] [--impact LEVEL]
#                    [--category CAT] [--since DATE] [--query TEXT]
#
# Examples:
#   search-things.sh --tag leadership --impact major
#   search-things.sh --skill python --since 2025-01-01
#   search-things.sh --query "authentication"

set -euo pipefail

CONFIG_FILE=".claude/i-did-a-thing.local.md"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found" >&2
  exit 1
fi

THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)
THINGS_PATH="${THINGS_PATH/#\~/$HOME}"
LOGS_DIR="$THINGS_PATH/logs"

if [[ ! -d "$LOGS_DIR" ]]; then
  echo "No logs directory found at $LOGS_DIR" >&2
  exit 1
fi

# Parse arguments
TAG=""
SKILL=""
IMPACT=""
CATEGORY=""
SINCE=""
QUERY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --skill) SKILL="$2"; shift 2 ;;
    --impact) IMPACT="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --query) QUERY="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Search each log file
for log in "$LOGS_DIR"/*.md; do
  [[ -f "$log" ]] || continue

  match=true

  if [[ -n "$TAG" ]]; then
    grep -q "^  - ${TAG}$" "$log" 2>/dev/null || match=false
  fi

  if [[ -n "$SKILL" ]]; then
    grep -q "$SKILL" "$log" 2>/dev/null || match=false
  fi

  if [[ -n "$IMPACT" ]]; then
    grep -q "^impact: .*${IMPACT}" "$log" 2>/dev/null || match=false
  fi

  if [[ -n "$CATEGORY" ]]; then
    grep -q "^category: .*${CATEGORY}" "$log" 2>/dev/null || match=false
  fi

  if [[ -n "$SINCE" ]]; then
    file_date=$(sed -n 's/^date: *\(.*\)$/\1/p' "$log" | head -1)
    if [[ -n "$file_date" && "$file_date" < "$SINCE" ]]; then
      match=false
    fi
  fi

  if [[ -n "$QUERY" ]]; then
    grep -qi "$QUERY" "$log" 2>/dev/null || match=false
  fi

  if $match; then
    title=$(sed -n 's/^title: *"\?\(.*\)"\?$/\1/p' "$log" | head -1)
    date=$(sed -n 's/^date: *\(.*\)$/\1/p' "$log" | head -1)
    impact=$(sed -n 's/^impact: *"\?\(.*\)"\?$/\1/p' "$log" | head -1)
    echo "$date | $impact | $title | $(basename "$log")"
  fi
done | sort -r
