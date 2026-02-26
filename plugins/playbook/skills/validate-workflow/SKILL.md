---
name: validate-workflow
description: "Validate XML workflow files for structural correctness, cross-reference integrity, and format compliance. Reports issues by severity (ERROR, WARNING, INFO)."
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
argument-hint: "[filename|--all]"
---

<purpose>
Validate XML workflow files for structural correctness and format compliance. Deeper checks than the PreToolUse hook, with severity-categorized reporting. See `../create-workflow/references/workflow-format.md` for the complete format specification.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.<exit /></if>

      <read path="<home>/.things/playbook/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-pb` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **filename**: A specific workflow filename (with or without `.md` extension)
    - **--all**: Validate all workflow files

    <if condition="no arguments">
      <action>List workflow files in `<home>/.things/playbook/workflows/` and let user select via AskUserQuestion.</action>
    </if>
  </step>

  <step id="read-workflows" number="3">
    <description>Read Workflow Files</description>

    <if condition="--all">
      <action>Glob `<home>/.things/playbook/workflows/*.md` and read all files.</action>
    </if>

    <if condition="filename">
      <action>Read `<home>/.things/playbook/workflows/<filename>.md`. If not found, also check the current project's `.claude/workflows/` directory.</action>
    </if>

    <if condition="no files found">
      <action>Tell the user no workflow files were found. Stop.</action>
      <exit />
    </if>
  </step>

  <step id="validate" number="4">
    <description>Validate Workflow Files</description>

    <action>For each workflow file, strip YAML frontmatter if present, then run all checks. Categorize findings by severity.</action>

    <constraint>
    **ERROR** (blocks pass):
    - Missing `<steps>` element
    - `<step>` missing `number` or `id` attribute
    - `<step>` missing `<title>` or `<goal>`
    - `<gate>` without `<condition>`
    - Broken `<prerequisite ref="">` — ref value doesn't match any step id
    - Broken `<on_fail goto="">` — goto value doesn't match any step id
    - `<use ref="">` without matching `<ref id="">`
    - Duplicate step ids
    </constraint>

    <constraint>
    **WARNING** (should fix):
    - Markdown inside `<steps>` zone (list items, bold, code fences, headings)
    - Non-sequential step numbers (gaps or out of order)
    </constraint>

    <constraint>
    **INFO** (suggestions):
    - More than 2 `<critical>` elements in a single step (most should be boundaries)
    - Steps with no children besides `<title>` and `<goal>` (possibly incomplete)
    - Missing `<verification-commands>` (optional but recommended)
    - Unexpected top-level elements (not steps, references, verification-commands, or principles)
    </constraint>
  </step>

  <step id="report" number="5">
    <description>Report Results</description>

    <action>Format and display the validation report.</action>

    <constraint>
    Report format per file:
    ```
    ## <filename>

    <ERROR/WARNING/INFO count summary>

    ### ERRORS
    - [line] Description of the issue

    ### WARNINGS
    - [line] Description of the issue

    ### INFO
    - [line] Description of the issue

    **Verdict: PASS** or **Verdict: FAIL (N errors)**
    ```

    Omit empty severity sections. If validating multiple files, show a summary line at the end:
    ```
    ---
    N files validated: X passed, Y failed
    ```
    </constraint>

    <constraint>A file PASSES only if it has zero ERRORs. Warnings and info items do not cause failure.</constraint>
  </step>

</steps>
