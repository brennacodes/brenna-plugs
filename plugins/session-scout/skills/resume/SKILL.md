---
name: resume
description: Get the resume command for a Claude Code session by full or partial session ID.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "<session-id>"
---

# /sesh:resume — Get Resume Command

## Usage

```
/sesh:resume 448332ee                                    # Partial ID match
/sesh:resume 448332ee-bf11-48c7-ad0b-3d9d1ee2a07d       # Full ID
```

## Execution

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" resume "<SESSION_ID>"
```

The script accepts both full UUIDs and partial ID prefixes/substrings.

## Output Formatting

Read and follow the formatting rules in `references/output-format.md`.

## Multiple Matches

If the partial ID matches more than one session, the script returns all matches. Display them in a numbered list and ask the user to pick one.

## Error Handling

If no session is found, inform the user and suggest they use `/sesh:active` or `/sesh:search` to find the session they're looking for.
