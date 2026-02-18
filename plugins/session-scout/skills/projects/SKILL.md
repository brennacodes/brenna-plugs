---
name: projects
description: List all Claude Code projects with session counts and last modified dates, or view all sessions for a specific project.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "[project-name]"
---

# /sesh:projects — List Sessions by Project

## Usage

```
/sesh:projects            # List all projects with session counts
/sesh:projects bivvy      # Show all sessions for the "bivvy" project
```

## Execution

**Without arguments** — list all projects:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" projects
```

**With a project name** — list all sessions for that project:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" search "" --project "<PROJECT_NAME>"
```

## Output Formatting

Read and follow the formatting rules in `references/output-format.md`.

## Interaction

When showing the project list, tell the user they can drill into any project by running `/sesh:projects <name>` to see its sessions.
