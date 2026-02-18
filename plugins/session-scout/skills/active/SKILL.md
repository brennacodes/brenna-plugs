---
name: active
description: View recent Claude Code sessions sorted by last modified date. Shows a numbered list of sessions across all projects with summary, project, and message count.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "[limit]"
---

# /sesh:active — View Recent Sessions

## Usage

```
/sesh:active          # Show 10 most recent sessions (default)
/sesh:active 20       # Show 20 most recent sessions
```

## Execution

Run the session finder script:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" active --limit <LIMIT>
```

- Default limit is **10** if no argument is provided.
- Parse the argument as an integer for the `--limit` flag.

## Output Formatting

Read and follow the formatting rules in `references/output-format.md`.

## Interaction

After displaying the table, tell the user they can ask for the resume command for any session by its number (e.g., "Show me #3") or use `/sesh:resume <id>` with the session ID.
