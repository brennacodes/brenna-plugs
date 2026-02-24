#!/usr/bin/env bash
# PreToolUse hook for playbook: validates workflow files on Write.
#
# Reads the tool input from stdin, checks if the file being written is a
# workflow file (playbook/workflows/*.md or .claude/workflows/*.md),
# and validates required XML structure.
#
# Exit 0 = allow, Exit 2 = block with message

set -euo pipefail

INPUT=$(cat)

# Extract file path from the tool input JSON
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
print(tool_input.get('file_path', ''))
" 2>/dev/null || echo "")

# Only validate workflow files
if [[ ! "$FILE_PATH" =~ playbook/workflows/[^/]+\.md$ ]] && [[ ! "$FILE_PATH" =~ \.claude/workflows/[^/]+\.md$ ]]; then
  exit 0
fi

# Extract the content being written via env var (safe for all content)
export WORKFLOW_CONTENT
WORKFLOW_CONTENT=$(echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
print(tool_input.get('content', ''))
" 2>/dev/null || echo "")

if [[ -z "$WORKFLOW_CONTENT" ]]; then
  exit 0
fi

# Validate workflow structure
python3 << 'PYEOF'
import os, sys, re

content = os.environ.get("WORKFLOW_CONTENT", "")
errors = []

# Strip YAML frontmatter if present (archive copies have it)
if content.startswith("---"):
    end = content.find("---", 3)
    if end != -1:
        content = content[end + 3:].lstrip("\n")

# 1. <steps> element exists
if not re.search(r"<steps\b", content):
    errors.append("Missing required <steps> element")

# Extract the <steps>...</steps> zone for further checks
steps_match = re.search(r"<steps\b[^>]*>(.*?)</steps>", content, re.DOTALL)
if steps_match:
    steps_zone = steps_match.group(1)

    # 2. Every <step> has number and id attributes
    steps = re.findall(r"<step\b([^>]*)>", steps_zone)
    for i, attrs in enumerate(steps):
        if not re.search(r'\bnumber\s*=\s*"', attrs):
            errors.append(f"<step> #{i+1} missing required 'number' attribute")
        if not re.search(r'\bid\s*=\s*"', attrs):
            errors.append(f"<step> #{i+1} missing required 'id' attribute")

    # 3. Every <step> contains <title> and <goal>
    step_blocks = re.findall(r"<step\b[^>]*>(.*?)</step>", steps_zone, re.DOTALL)
    for i, block in enumerate(step_blocks):
        if not re.search(r"<title\b", block):
            errors.append(f"<step> #{i+1} missing required <title>")
        if not re.search(r"<goal\b", block):
            errors.append(f"<step> #{i+1} missing required <goal>")

    # 4. Every <gate> contains <condition>
    gate_blocks = re.findall(r"<gate\b[^>]*>(.*?)</gate>", steps_zone, re.DOTALL)
    for i, gate in enumerate(gate_blocks):
        if not re.search(r"<condition\b", gate):
            errors.append(f"<gate> #{i+1} missing required <condition>")

    # 5. No markdown inside the XML zone
    for line in steps_zone.split("\n"):
        stripped = line.strip()
        # Skip empty lines and XML tags
        if not stripped or stripped.startswith("<") or stripped.startswith("</"):
            continue
        if re.match(r"^- ", stripped):
            errors.append(f"Markdown list item found inside <steps>: '{stripped[:60]}'")
            break
        if re.search(r"\*\*[^*]+\*\*", stripped):
            errors.append(f"Markdown bold found inside <steps>: '{stripped[:60]}'")
            break
        if stripped.startswith("```"):
            errors.append(f"Markdown code fence found inside <steps>")
            break
        if re.match(r"^#{2,}\s", stripped):
            errors.append(f"Markdown heading found inside <steps>: '{stripped[:60]}'")
            break

# 6. All <use ref=""> values match a declared <ref id="">
declared_refs = set(re.findall(r'<ref\s+id="([^"]+)"', content))
used_refs = set(re.findall(r'<use\s+ref="([^"]+)"', content))
if used_refs:
    unresolved = used_refs - declared_refs
    if unresolved:
        errors.append(f"Unresolved <use ref=\"\"> references: {', '.join(sorted(unresolved))}")

if errors:
    print("BLOCK: Workflow validation failed:", file=sys.stderr)
    for err in errors:
        print(f"  - {err}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
PYEOF

exit $?
