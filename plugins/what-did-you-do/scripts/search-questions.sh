#!/usr/bin/env bash
# Search the question bank by various criteria.
#
# Usage:
#   search-questions.sh [--category CAT] [--skill SKILL]
#                       [--level LEVEL] [--stage STAGE]
#                       [--difficulty N] [--query TEXT]
#                       [--id ID]
#
# Examples:
#   search-questions.sh --category behavioral --skill leadership
#   search-questions.sh --level staff --stage onsite
#   search-questions.sh --query "technical debt"
#   search-questions.sh --id beh-001

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUESTIONS_DIR="$(cd "$SCRIPT_DIR/../questions" && pwd)"

# Also check for custom questions
CONFIG_FILE=".claude/what-did-you-do.local.md"
CUSTOM_DIR=""
if [[ -f "$CONFIG_FILE" ]]; then
  THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)
  THINGS_PATH="${THINGS_PATH/#\~/$HOME}"
  if [[ -d "$THINGS_PATH/interview-prep/question-overrides" ]]; then
    CUSTOM_DIR="$THINGS_PATH/interview-prep/question-overrides"
  fi
fi

# Parse arguments
CATEGORY=""
SKILL=""
LEVEL=""
STAGE=""
DIFFICULTY=""
QUERY=""
ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category) CATEGORY="$2"; shift 2 ;;
    --skill) SKILL="$2"; shift 2 ;;
    --level) LEVEL="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --difficulty) DIFFICULTY="$2"; shift 2 ;;
    --query) QUERY="$2"; shift 2 ;;
    --id) ID="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Build list of question files to search
SEARCH_FILES=()
if [[ -n "$CATEGORY" ]]; then
  qfile="$QUESTIONS_DIR/${CATEGORY}.yaml"
  [[ -f "$qfile" ]] && SEARCH_FILES+=("$qfile")
else
  for qfile in "$QUESTIONS_DIR"/*.yaml; do
    [[ "$(basename "$qfile")" == "_index.yaml" ]] && continue
    SEARCH_FILES+=("$qfile")
  done
fi

# Add custom questions
if [[ -n "$CUSTOM_DIR" ]]; then
  for qfile in "$CUSTOM_DIR"/*.yaml; do
    [[ -f "$qfile" ]] && SEARCH_FILES+=("$qfile")
  done
fi

# Search through question files
for qfile in "${SEARCH_FILES[@]}"; do
  # Use awk to extract question blocks and filter
  awk -v skill="$SKILL" -v level="$LEVEL" -v stage="$STAGE" \
      -v difficulty="$DIFFICULTY" -v query="$QUERY" -v qid="$ID" '
    /^  - id:/ {
      if (id != "" && match_all) {
        print id " | " category " | " diff " | " text " | " FILENAME
      }
      id = $NF
      text = ""
      category = ""
      diff = ""
      match_all = 1
      next
    }
    /^    text:/ {
      sub(/^    text: *"?/, "")
      sub(/"$/, "")
      text = $0
    }
    /^    category:/ { category = $NF }
    /^    difficulty:/ { diff = $NF }

    # Filter by ID
    qid != "" && id != "" && id != qid { match_all = 0 }

    # Filter by skill
    skill != "" && /skills_tested:/ {
      if (index($0, skill) == 0) match_all = 0
    }

    # Filter by level
    level != "" && /^    level:/ {
      if (index($0, level) == 0) match_all = 0
    }

    # Filter by stage
    stage != "" && /^    stages:/ {
      if (index($0, stage) == 0) match_all = 0
    }

    # Filter by difficulty
    difficulty != "" && /^    difficulty:/ {
      if ($NF != difficulty) match_all = 0
    }

    # Filter by text query
    query != "" && /^    text:/ {
      line = tolower($0)
      q = tolower(query)
      if (index(line, q) == 0) match_all = 0
    }

    END {
      if (id != "" && match_all) {
        print id " | " category " | " diff " | " text " | " FILENAME
      }
    }
  ' "$qfile"
done | sort
