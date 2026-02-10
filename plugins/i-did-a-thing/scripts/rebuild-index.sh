#!/usr/bin/env bash
# Rebuild the things index from all log files.
# Called by the auto-index-on-log hook after a new log is written.
#
# Reads the config to find the things_path, then scans all logs
# and rebuilds index.md with date, tag, and impact sections.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only rebuild index for writes to */logs/*.md
if [[ -z "$FILE_PATH" || ! "$FILE_PATH" =~ /logs/[^/]*\.md$ ]]; then
  exit 0
fi

CONFIG_FILE=".claude/i-did-a-thing.local.md"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found at $CONFIG_FILE" >&2
  exit 0 # Non-fatal — don't block the user
fi

# Extract things_path from config frontmatter
THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)

if [[ -z "$THINGS_PATH" ]]; then
  echo "things_path not found in config" >&2
  exit 0
fi

# Expand ~ if present
THINGS_PATH="${THINGS_PATH/#\~/$HOME}"

LOGS_DIR="$THINGS_PATH/logs"
INDEX_FILE="$THINGS_PATH/index.md"

if [[ ! -d "$LOGS_DIR" ]]; then
  exit 0
fi

# Count entries
TOTAL=$(find "$LOGS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')

# Build date entries (most recent first)
DATE_ENTRIES=""
TAG_MAP=""
IMPACT_MAP=""

for log in $(ls -r "$LOGS_DIR"/*.md 2>/dev/null); do
  filename=$(basename "$log")

  # Extract frontmatter fields
  title=$(sed -n 's/^title: *"\?\(.*\)"\?$/\1/p' "$log" | head -1)
  date=$(sed -n 's/^date: *\(.*\)$/\1/p' "$log" | head -1)
  impact=$(sed -n 's/^impact: *"\?\(.*\)"\?$/\1/p' "$log" | head -1)
  description=$(sed -n 's/^description: *"\?\(.*\)"\?$/\1/p' "$log" | head -1)

  # Build date entry
  DATE_ENTRIES="${DATE_ENTRIES}\n- **${date}** — [${title}](logs/${filename}) (${impact})"

  # Collect tags
  in_tags=false
  while IFS= read -r line; do
    if [[ "$line" == "tags:" ]]; then
      in_tags=true
      continue
    fi
    if $in_tags; then
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
        tag="${BASH_REMATCH[1]}"
        TAG_MAP="${TAG_MAP}${tag}|${title}|logs/${filename}\n"
      else
        in_tags=false
      fi
    fi
  done < "$log"

  # Collect impact
  if [[ -n "$impact" ]]; then
    IMPACT_MAP="${IMPACT_MAP}${impact}|${title}|logs/${filename}\n"
  fi
done

# Write index
cat > "$INDEX_FILE" << INDEXEOF
---
title: "My Things Index"
description: "Auto-generated index of accomplishments"
last_updated: $(date +%Y-%m-%d)
total_entries: $TOTAL
---

# Things I've Done

This index is automatically maintained by the i-did-a-thing plugin.

## By Date

$(echo -e "$DATE_ENTRIES")

## By Tag

$(echo -e "$TAG_MAP" | sort -t'|' -k1 | awk -F'|' '
  NF>=3 {
    if ($1 != prev_tag && $1 != "") {
      if (prev_tag != "") print ""
      print "### " $1
      prev_tag = $1
    }
    if ($2 != "") print "- [" $2 "](" $3 ")"
  }
')

## By Impact

$(for level in major notable solid learning; do
  entries=$(echo -e "$IMPACT_MAP" | grep "^${level}|" || true)
  if [[ -n "$entries" ]]; then
    echo "### ${level^}"
    echo "$entries" | awk -F'|' 'NF>=3 { print "- [" $2 "](" $3 ")" }'
    echo ""
  fi
done)
INDEXEOF

echo "Index rebuilt: $TOTAL entries"
