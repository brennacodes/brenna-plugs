---
name: search
description: Search Claude Code sessions by keyword across all projects. Searches summaries and first prompts by default, or full transcripts with --deep.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "<query> [--project <name>] [--since <date>] [--until <date>] [--deep] [--limit <n>]"
---

# /sesh:search — Search Sessions by Keyword

## Usage

```
/sesh:search auth bug               # Search index metadata
/sesh:search plugin --deep           # Also search full transcripts
/sesh:search "" --project bivvy      # List all sessions for a project
/sesh:search refactor --since "3 days ago"
/sesh:search fix --since 2026-02-01 --until 2026-02-15
```

## Execution

Parse the user's arguments into a script invocation:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" search "<QUERY>" [--project <NAME>] [--since <DATE>] [--until <DATE>] [--deep] [--limit <N>]
```

- The query is the first positional argument (everything before flags).
- Supported date formats: ISO dates (`2026-02-01`), `today`, `yesterday`, `last week`, `N days ago`.
- Default limit is 20.

## Output Formatting

Read and follow the formatting rules in `references/output-format.md`.

## When No Results Found

If the search returns 0 results and `--deep` was NOT used, suggest the user retry with `--deep` to search inside full session transcripts. Deep search is slower but finds matches in conversation content.
