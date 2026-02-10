#!/usr/bin/env bash
# Validate session log frontmatter before writing.
# Called by the validate-session-format hook as a PreToolUse check.
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

# Only validate files matching */interview-prep/sessions/*.md
if [[ ! "$FILE_PATH" =~ /interview-prep/sessions/[^/]*\.md$ ]]; then
  exit 0
fi

# For pre-write, we can't validate yet if the file doesn't exist
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

CONTENT=$(cat "$FILE_PATH")

REQUIRED_FIELDS=("type" "date" "question_id" "question_category" "persona" "scores")
MISSING=()

for field in "${REQUIRED_FIELDS[@]}"; do
  if ! echo "$CONTENT" | grep -q "^${field}:"; then
    MISSING+=("$field")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "VALIDATION ERROR: Session log missing required fields: ${MISSING[*]}" >&2
  echo "Required fields: type, date, question_id, question_category, persona, scores" >&2
  exit 1
fi

# Validate type value
TYPE=$(echo "$CONTENT" | sed -n 's/^type: *"\?\(.*\)"\?$/\1/p' | head -1)
if [[ -n "$TYPE" ]] && ! echo "$TYPE" | grep -qE "^(practice|mock)$"; then
  echo "VALIDATION ERROR: type must be one of: practice, mock (got: $TYPE)" >&2
  exit 1
fi

# Validate score dimensions exist
for dim in specificity structure impact relevance self_advocacy; do
  if ! echo "$CONTENT" | grep -q "  ${dim}:"; then
    echo "VALIDATION WARNING: Missing score dimension: $dim" >&2
    # Warning only — don't block the write
  fi
done

echo "Session format valid"
exit 0
