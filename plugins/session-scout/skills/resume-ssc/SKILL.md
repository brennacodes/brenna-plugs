---
name: resume-ssc
description: Get the resume command for a Claude Code session by full or partial session ID.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "<session-id>"
---

<references>
Read and follow the formatting rules in `references/output-format.md`.
</references>

<purpose>
Get the resume command for a Claude Code session by full or partial session ID. Accepts both full UUIDs and partial ID prefixes/substrings.

```
/resume-ssc 448332ee                                    # Partial ID match
/resume-ssc 448332ee-bf11-48c7-ad0b-3d9d1ee2a07d       # Full ID
```
</purpose>

<steps>

  <step id="run-script" number="1">
    <description>Run the Resume Lookup</description>
    <command language="bash" tool="Bash">python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" resume "<SESSION_ID>"</command>
  </step>

  <step id="format-output" number="2">
    <description>Format and Display Results</description>
    <action>Format the output according to the rules in `references/output-format.md`.</action>
  </step>

  <step id="handle-multiple-matches" number="3">
    <description>Handle Multiple Matches</description>
    <if condition="multiple-matches">
      <action>The script returns all matches when a partial ID matches more than one session. Display them in a numbered list and ask the user to pick one.</action>
    </if>
  </step>

  <step id="handle-errors" number="4">
    <description>Handle No Results</description>
    <if condition="no-session-found">
      <action>Inform the user and suggest they use `/active-ssc` or `/search-sessions` to find the session they are looking for.</action>
    </if>
  </step>

</steps>
