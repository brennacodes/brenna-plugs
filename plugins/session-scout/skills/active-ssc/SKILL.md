---
name: active-ssc
description: View recent Claude Code sessions sorted by last modified date. Shows a numbered list of sessions across all projects with summary, project, and message count.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "[limit]"
---

<references>
Read and follow the formatting rules in `references/output-format.md`.
</references>

<purpose>
View recent Claude Code sessions sorted by last modified date. Shows a numbered list of sessions across all projects with summary, project, and message count.

```
/active-ssc          # Show 10 most recent sessions (default)
/active-ssc 20       # Show 20 most recent sessions
```
</purpose>

<steps>

  <step id="run-script" number="1">
    <description>Run the Session Finder Script</description>
    <action>Parse the argument as an integer for the `--limit` flag.</action>
    <constraint>Default limit is 10 if no argument is provided.</constraint>
    <command language="bash" tool="Bash">python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" active --limit <LIMIT></command>
  </step>

  <step id="format-output" number="2">
    <description>Format and Display Results</description>
    <action>Format the output according to the rules in `references/output-format.md`.</action>
  </step>

  <step id="interaction" number="3">
    <description>Offer Next Actions</description>
    <completion-message>Tell the user they can ask for the resume command for any session by its number (e.g., "Show me #3") or use `/resume-ssc <id>` with the session ID.</completion-message>
  </step>

</steps>
