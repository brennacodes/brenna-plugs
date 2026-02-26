---
name: search-sessions
description: Search Claude Code sessions by keyword across all projects. Searches summaries and first prompts by default, or full transcripts with --deep.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "<query> [--project <name>] [--since <date>] [--until <date>] [--deep] [--limit <n>]"
---

<references>
Read and follow the formatting rules in `references/output-format.md`.
</references>

<purpose>
Search Claude Code sessions by keyword across all projects. Searches summaries and first prompts by default, or full transcripts with --deep.

```
/search-sessions auth bug               # Search index metadata
/search-sessions plugin --deep           # Also search full transcripts
/search-sessions "" --project <name>      # List all sessions for a project
/search-sessions refactor --since "3 days ago"
/search-sessions fix --since 2026-02-01 --until 2026-02-15
```
</purpose>

<steps>

  <step id="parse-and-run" number="1">
    <description>Parse Arguments and Run Search</description>
    <action>Parse the user's arguments into a script invocation. The query is the first positional argument (everything before flags).</action>
    <command language="bash" tool="Bash">python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" search "<QUERY>" [--project <NAME>] [--since <DATE>] [--until <DATE>] [--deep] [--limit <N>]</command>
    <constraint>Supported date formats: ISO dates (`2026-02-01`), `today`, `yesterday`, `last week`, `N days ago`.</constraint>
    <constraint>Default limit is 20.</constraint>
  </step>

  <step id="format-output" number="2">
    <description>Format and Display Results</description>
    <action>Format the output according to the rules in `references/output-format.md`.</action>
  </step>

  <step id="handle-no-results" number="3">
    <description>Handle No Results</description>
    <if condition="no-results-and-no-deep-flag">
      <action>Suggest the user retry with `--deep` to search inside full session transcripts. Deep search is slower but finds matches in conversation content.</action>
    </if>
  </step>

</steps>
