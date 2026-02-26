---
name: create-type
description: "Create custom deliverable types with templates, tool requirements, and instructions for the deliverable agent. Use when user says 'create deliverable type', 'add a type', 'custom deliverable'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<type-name>"
---

<purpose>
Create custom deliverable types that extend heres-the-thing beyond the builtin types. Each type defines a template, output format, required tools/MCP servers/external binaries, and instructions for the deliverable agent.

Custom types are registered in `~/.things/heres-the-thing/deliverable-types/index.json` and can be included in any campaign goal's `deliverables` list.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>

    2. Read `<home>/.things/heres-the-thing/deliverable-types/index.json`
       <if condition="types-missing">Tell the user: "Run `/heres-the-thing:setup-htt` first." Then stop.</if>
    </load-config>
  </step>

  <step id="gather-type-info" number="2">
    <description>Gather Type Information</description>

    Use AskUserQuestion to gather:

    1. **Name**: What should this deliverable type be called? (e.g., "Executive One-Pager", "Stakeholder Update Email", "Decision Matrix")

    2. **Description**: What does this deliverable produce? What's it for?

    3. **Output format**: What format should the output be in?
       <options>
       - md (Markdown)
       - pdf (PDF -- requires external tool)
       - html (HTML)
       </options>

    4. **Template**: Do you have a template for this type?
       <options>
       - Yes -- I'll provide template content
       - No -- the instructions are enough
       </options>

       <if condition="has-template">
       Ask the user to provide the template content. This can be a markdown structure, HTML template, etc.
       </if>

    5. **Instructions**: How should the deliverable agent use the strategy brief and campaign context to produce this deliverable? Be specific about structure, tone, length, and any special considerations.

    6. **Required tools**: Which Claude Code tools does this type need?
       - Write (always included)
       - Bash (specify commands, e.g., `Bash(wkhtmltopdf)`)
       - Any others

    7. **Required MCP servers**: Does this type need any MCP servers? (e.g., for Google Docs integration)

    8. **Required external binaries**: Does this type need any external programs installed? (e.g., `wkhtmltopdf`, `pandoc`)
  </step>

  <step id="validate-requirements" number="3">
    <description>Validate Requirements</description>

    <if condition="has-external-requirements">
    For each declared external binary:

    ```bash
    which <binary> 2>/dev/null && echo "found" || echo "missing"
    ```

    <if condition="binary-missing">
    Warn the user: "<binary> is not installed. This deliverable type will fail if used without it. Install it first, or continue anyway?"
    </if>
    </if>

    <if condition="has-mcp-requirements">
    Note: MCP server availability cannot be validated at registration time. The deliverable agent will check at runtime.
    </if>
  </step>

  <step id="generate-id" number="4">
    <description>Generate Type ID</description>

    Generate a type ID from the name: lowercase, underscores, no special characters. (e.g., "Executive One-Pager" → `exec_one_pager`)

    <check name="no-duplicate">Check that this ID doesn't already exist in the type registry.</check>
    <if condition="duplicate">Ask the user to choose a different name or confirm overwrite.</if>
  </step>

  <step id="write-template" number="5">
    <description>Write Template File</description>

    <if condition="has-template">
    <output-path>`<home>/.things/heres-the-thing/deliverable-types/<type-id>.md`</output-path>

    Write the template content provided by the user.
    </if>
  </step>

  <step id="register-type" number="6">
    <description>Register Type</description>

    Read `<home>/.things/heres-the-thing/deliverable-types/index.json`.

    Add the new type:

    ```json
    {
      "<type-id>": {
        "id": "<type-id>",
        "name": "<name>",
        "description": "<description>",
        "builtin": false,
        "template": "<type-id>.md or null",
        "output_format": "<format>",
        "requires": {
          "tools": ["Write", "<additional tools>"],
          "mcp_servers": ["<servers or empty>"],
          "external": ["<binaries or empty>"]
        },
        "instructions": "<instructions>"
      }
    }
    ```

    Write the updated index.json.
  </step>

  <step id="confirm" number="7">
    <description>Confirm</description>

    <completion-message>
    Custom deliverable type registered:

    - ID: `<type-id>`
    - Name: <name>
    - Output: <format>
    - Template: <yes/no>
    - Requirements: <tools>, <mcp_servers>, <externals>

    Use it in campaigns by adding `"<type-id>"` to a goal's `deliverables` list.
    </completion-message>
  </step>

</steps>
