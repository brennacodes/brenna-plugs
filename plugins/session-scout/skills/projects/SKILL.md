---
name: projects
description: List all Claude Code projects with session counts and last modified dates, or view all sessions for a specific project.
disable-model-invocation: true
allowed-tools: Bash, Read
user-invocable: true
arguments: "[project-name]"
---

<references>
Read and follow the formatting rules in `references/output-format.md`.
</references>

<purpose>
List all Claude Code projects with session counts and last modified dates, or view all sessions for a specific project.

```
/projects            # List all projects with session counts
/projects <project>      # Show all sessions for the <project> project
```
</purpose>

<steps>

  <step id="run-script" number="1">
    <description>Run the Appropriate Command</description>

    <if condition="no-arguments">
      <action>List all projects.</action>
      <command language="bash" tool="Bash">python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" projects</command>
    </if>

    <if condition="project-name-provided">
      <action>List all sessions for that project.</action>
      <command language="bash" tool="Bash">python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sesh.py" search "" --project "<PROJECT_NAME>"</command>
    </if>
  </step>

  <step id="format-output" number="2">
    <description>Format and Display Results</description>
    <action>Format the output according to the rules in `references/output-format.md`.</action>
  </step>

  <step id="interaction" number="3">
    <description>Offer Next Actions</description>
    <completion-message>When showing the project list, tell the user they can drill into any project by running `/projects <name>` to see its sessions.</completion-message>
  </step>

</steps>
