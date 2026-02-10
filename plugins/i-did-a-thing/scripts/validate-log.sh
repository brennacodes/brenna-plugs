#!/usr/bin/env bash
# Validate log entry frontmatter before writing.
# Called by the validate-log-format hook as a PreToolUse check.
#
# Checks that required fields are present in the YAML frontmatter.
# Exits 0 (pass) or 1 (fail with message).

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only validate files matching */logs/*.md
if [[ ! "$FILE_PATH" =~ /logs/[^/]*\.md$ ]]; then
  exit 0
fi

# Read from stdin if the file doesn't exist yet (pre-write validation)
# The hook passes file content through the tool input
CONTENT=""
if [[ -f "$FILE_PATH" ]]; then
  CONTENT=$(cat "$FILE_PATH")
else
  # For pre-write, we can't validate yet — let it through
  exit 0
fi

REQUIRED_FIELDS=("title" "date" "description" "impact" "category" "tags" "skills_used" "draft" "author")
MISSING=()

for field in "${REQUIRED_FIELDS[@]}"; do
  if ! echo "$CONTENT" | grep -q "^${field}:"; then
    MISSING+=("$field")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "VALIDATION ERROR: Log entry missing required fields: ${MISSING[*]}" >&2
  echo "See references/log-format.md for the required format." >&2
  exit 1
fi

# Validate impact value
IMPACT=$(echo "$CONTENT" | sed -n 's/^impact: *"\?\(.*\)"\?$/\1/p' | head -1)
if [[ -n "$IMPACT" ]] && ! echo "$IMPACT" | grep -qE "^(major|notable|solid|learning)$"; then
  echo "VALIDATION ERROR: impact must be one of: major, notable, solid, learning (got: $IMPACT)" >&2
  exit 1
fi

# Validate category value
CATEGORY=$(echo "$CONTENT" | sed -n 's/^category: *"\?\(.*\)"\?$/\1/p' | head -1)
if [[ -n "$CATEGORY" ]] && ! echo "$CATEGORY" | grep -qE "^(technical|leadership|communication|problem-solving|process|growth)$"; then
  echo "VALIDATION ERROR: category must be one of: technical, leadership, communication, problem-solving, process, growth (got: $CATEGORY)" >&2
  exit 1
fi

echo "Log format valid"
exit 0
