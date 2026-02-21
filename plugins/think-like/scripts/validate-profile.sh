#!/usr/bin/env bash
# PreToolUse hook for think-like: validates profile index.json files on Write.
#
# Reads the tool input from stdin, checks if the file being written is a
# think-like profile index.json, and validates required fields.
#
# Exit 0 = allow, Exit 2 = block with message

set -euo pipefail

INPUT=$(cat)

# Extract file path from the tool input JSON
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
# PreToolUse provides tool_input with file_path
tool_input = data.get('tool_input', {})
print(tool_input.get('file_path', ''))
" 2>/dev/null || echo "")

# Only validate think-like profile index.json files
if [[ ! "$FILE_PATH" =~ think-like/profiles/[^/]+/index\.json$ ]]; then
  exit 0
fi

# Extract the content being written
CONTENT=$(echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
print(tool_input.get('content', ''))
" 2>/dev/null || echo "")

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Validate required fields in the JSON
python3 -c "
import json, sys

content = '''$CONTENT'''

try:
    data = json.loads(content)
except json.JSONDecodeError as e:
    print(f'BLOCK: Profile index.json is not valid JSON: {e}', file=sys.stderr)
    sys.exit(2)

required = ['id', 'display_name', 'person_ref', 'actions', 'created']
missing = [f for f in required if f not in data]

if missing:
    print(f'BLOCK: Profile index.json missing required fields: {", ".join(missing)}', file=sys.stderr)
    sys.exit(2)

if not isinstance(data.get('actions'), list):
    print('BLOCK: Profile index.json \"contexts\" must be an array', file=sys.stderr)
    sys.exit(2)

if not data.get('person_ref', '').startswith('shared/people/'):
    print('BLOCK: Profile index.json \"person_ref\" must start with \"shared/people/\"', file=sys.stderr)
    sys.exit(2)

sys.exit(0)
" 2>&1

exit $?
