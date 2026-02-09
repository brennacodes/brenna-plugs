#!/usr/bin/env bash
# Update arsenal skill files when a new log references skills.
# Called by the auto-arsenal-update hook.
#
# Usage: update-arsenal.sh <log-file-path>
#
# Extracts skills_used from the log's frontmatter and ensures
# each skill has an arsenal summary file with this log as evidence.

set -euo pipefail

LOG_FILE="${1:-}"

if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
  exit 0
fi

CONFIG_FILE=".claude/i-did-a-thing.local.md"

if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

THINGS_PATH=$(sed -n 's/^things_path: *"\?\([^"]*\)"\?$/\1/p' "$CONFIG_FILE" | head -1)
THINGS_PATH="${THINGS_PATH/#\~/$HOME}"
ARSENAL_DIR="$THINGS_PATH/arsenal"

mkdir -p "$ARSENAL_DIR"

# Extract metadata from log
title=$(sed -n 's/^title: *"\?\(.*\)"\?$/\1/p' "$LOG_FILE" | head -1)
date=$(sed -n 's/^date: *\(.*\)$/\1/p' "$LOG_FILE" | head -1)
impact=$(sed -n 's/^impact: *"\?\(.*\)"\?$/\1/p' "$LOG_FILE" | head -1)
description=$(sed -n 's/^description: *"\?\(.*\)"\?$/\1/p' "$LOG_FILE" | head -1)
filename=$(basename "$LOG_FILE")

# Extract skills_used list
skills=()
in_skills=false
while IFS= read -r line; do
  if [[ "$line" == "skills_used:" ]]; then
    in_skills=true
    continue
  fi
  if $in_skills; then
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      skills+=("${BASH_REMATCH[1]}")
    else
      break
    fi
  fi
done < "$LOG_FILE"

# Update arsenal for each skill
for skill in "${skills[@]}"; do
  # Slugify skill name
  slug=$(echo "$skill" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  arsenal_file="$ARSENAL_DIR/${slug}.md"

  if [[ -f "$arsenal_file" ]]; then
    # Update existing: increment count, update last_demonstrated, append evidence
    current_count=$(sed -n 's/^evidence_count: *\([0-9]*\)$/\1/p' "$arsenal_file" | head -1)
    new_count=$((current_count + 1))

    # Update frontmatter
    sed -i '' "s/^evidence_count: .*/evidence_count: $new_count/" "$arsenal_file"
    sed -i '' "s/^last_demonstrated: .*/last_demonstrated: $date/" "$arsenal_file"

    # Update proficiency trend
    if [[ $new_count -ge 8 ]]; then
      sed -i '' 's/^proficiency_trend: .*/proficiency_trend: "expert"/' "$arsenal_file"
    elif [[ $new_count -ge 4 ]]; then
      sed -i '' 's/^proficiency_trend: .*/proficiency_trend: "established"/' "$arsenal_file"
    fi

    # Append evidence entry
    cat >> "$arsenal_file" << EVIDENCE

### $date — $title
- $description
- Impact: $impact
- [Full log](../logs/$filename)
EVIDENCE

  else
    # Create new arsenal file
    cat > "$arsenal_file" << NEWFILE
---
skill: "$skill"
evidence_count: 1
last_demonstrated: $date
proficiency_trend: "building"
---

# $skill

## Evidence

### $date — $title
- $description
- Impact: $impact
- [Full log](../logs/$filename)
NEWFILE
  fi
done

echo "Arsenal updated for ${#skills[@]} skills"
