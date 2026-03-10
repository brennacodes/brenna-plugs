---
name: create-workflow-pb
description: "Create or update an XML workflow file with structured steps, gates, prerequisites, verification commands, and more. Writes archive copy to .things/ and working copy to project."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<scope> [--target <path>] [--update <existing>] [--embed-in <file>]"
---

<purpose>
Create or update an XML workflow document. Workflows define structured multi-step processes with gates, prerequisites, verification commands, and principles. See `references/workflow-format.md` for all XML tags and the complete format specification.
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
    - **scope**: What the workflow covers (development, release, review, testing, or a custom description)
    - **--target**: Path for the working copy (overrides preference default)
    - **--update**: Filename of an existing workflow to update
    - **--embed-in**: Path to a SKILL.md file to embed the workflow into

    <if condition="--update">
      <action>Read the existing workflow from `<home>/.things/playbook/workflows/<existing>.md` or from the target path.</action>
    </if>
  </step>

  <step id="gather-context" number="3">
    <description>Gather Workflow Context</description>

    <action>Search conversation history for workflow-relevant content: process descriptions, step sequences, verification criteria, gate conditions.</action>

    <if condition="context-sparse">
      <action>Conduct a brief interview:</action>

      <ask-user-question>
        <question>What triggers this workflow? (e.g., "Starting a new feature", "Preparing a release")</question>
      </ask-user-question>

      <ask-user-question>
        <question>Walk me through the steps at a high level. What's the general sequence?</question>
      </ask-user-question>

      <ask-user-question>
        <question>Are there gates or checkpoints where you need to verify something before proceeding?</question>
        <option>Yes -- some steps have quality gates</option>
        <option>No -- it's a linear sequence</option>
      </ask-user-question>

      <ask-user-question>
        <question>Are there commands that verify success? (e.g., test suites, linters, build commands)</question>
        <option>Yes -- I have specific verification commands</option>
        <option>No -- verification is manual</option>
      </ask-user-question>
    </if>
  </step>

  <step id="design-workflow" number="4">
    <description>Design the Workflow</description>

    <action>Design the workflow using the XML pattern from `references/workflow-format.md`. The only markdown permitted is `# Title` and `> Description` at the top. Everything after is pure XML.</action>

    <critical>No markdown inside `<steps>`: no `- ` list items, `**bold**`, triple backticks, or `## ` headings. Use `<instruction>` + `<action>` elements instead.</critical>

    <constraint>
    Every `<step>` MUST have:
    - `number` and `id` attributes
    - `<title>` child element
    - `<goal>` child element
    </constraint>

    <constraint>
    Execution tag selection (inside `<instruction>`) — see Section 4 of workflow-format.md:
    - `<command>`: shell command to run
    - `<expected>`: what output should look like (pairs with command)
    - `<rationale>`: why this instruction matters
    - `<fix>`: how to recover if command fails (pairs with command)
    - `<action>`: non-command work the executor must do
    - `<format>` + `<line>`: expected output format
    - `<rules>` + `<rule>`: rules for this instruction
    - `<conditional>`: runtime branching with `<condition>` + `<action>`
    </constraint>

    <constraint>
    Constraint tag selection (at step level) — see Section 4 of workflow-format.md:
    - `<gate>` + `<condition>`: binary pass/fail checkpoint blocking progress
    - `<prerequisite ref="">`: step ordering dependency
    - `<boundaries>` + `<rule>`: positive guardrails on HOW work is done
    - `<anti-patterns>` + `<anti-pattern>`: non-obvious mistakes to avoid
    - `<critical>`: data loss / security level only, use sparingly
    </constraint>

    <constraint>
    Optional top-level elements:
    - `<references>`: declare reusable values with `<ref id="">`, use with `<use ref="" />`. Use when a value (command, path) appears 2+ times.
    - `<inputs>` / `<outputs>` per step: declare data flow between steps. Use when a workflow has data dependencies, not needed for simple linear workflows.
    - `<verification-commands>`: quick-reference command list at bottom.
    - `<principles>`: workflow-wide philosophy.
    </constraint>

    <constraint>Keep workflows focused. 4-8 steps is typical. If you need more than 10, consider splitting into sub-workflows.</constraint>

    <phase name="self-validate" number="1">
      <description>Structural Checks Before Writing</description>
      <action>Before writing the workflow, verify:</action>
      <constraint>
      - Every `<step>` has `number` and `id` attributes
      - Every `<step>` has `<title>` and `<goal>` children
      - Every `<gate>` has a `<condition>` child
      - Every `<prerequisite ref="">` references a valid step id
      - Every `<on_fail goto="">` references a valid step id
      - Every `<use ref="">` matches a declared `<ref id="">`
      - No markdown (lists, bold, code fences, headings) inside `<steps>`
      </constraint>
    </phase>
  </step>

  <step id="write-copies" number="5">
    <description>Write Workflow Copies</description>

    <phase name="archive-copy" number="1">
      <description>Write Archive Copy</description>

      <action>Generate slug from workflow title.</action>
      <write path="<home>/.things/playbook/workflows/<slug>.md">

      <template name="archive-workflow">
      ```markdown
      ---
      title: "<title>"
      date: <YYYY-MM-DD>
      description: "<description>"
      doc_type: "workflow"
      scope: "<scope>"
      target_path: "<working copy path or null>"
      step_count: <N>
      tags: [<tags>]
      ---

      <workflow XML content>
      ```
      </template>

      </write>
    </phase>

    <phase name="working-copy" number="2">
      <description>Write Working Copy (if applicable)</description>

      <action>Determine if a working copy should be written:</action>
      - Check if the current project has a `.claude/` directory
      - Use `--target` path if provided, otherwise `preferences.default_workflow_target`

      <if condition="should-write-working-copy">
        <write path="<target>/<slug>.md">
        <constraint>Working copies do NOT include YAML frontmatter -- they are pure workflow content ready for Claude Code execution.</constraint>
        </write>
      </if>
    </phase>
  </step>

  <step id="incorporate" number="6">
    <description>Incorporate into Target Files</description>

    <action>Determine if the workflow should be referenced from other files.</action>

    <phase name="claude-md" number="1">
      <description>CLAUDE.md Integration</description>

      <action>Check if CLAUDE.md exists in the project root.</action>
      <if condition="claude-md-exists-and-working-copy-written">
        <ask-user-question>
          <question>Would you like to add a reference to this workflow in CLAUDE.md?</question>
          <option label="Yes (Recommended)">Add a workflow block with step index to CLAUDE.md</option>
          <option label="No">I'll reference it manually</option>
        </ask-user-question>

        <if condition="yes">
          <action>Add a `<workflow>` block with `<summary>` and `<step-index>` to CLAUDE.md (see Section 7 of workflow-format.md). This gives Claude a table-of-contents view without reading the full file. Example:</action>
          <constraint>
          Format:
          ```xml
          <workflow path=".claude/workflows/<slug>.md">
            <summary>One-line description</summary>
            <step-index>
              <step ref="step-id">One-line step description</step>
              ...
            </step-index>
          </workflow>
          ```
          The `ref` attributes must match step `id` values in the workflow file. Create a `<references>` section in CLAUDE.md if one doesn't exist.
          </constraint>
        </if>
      </if>
    </phase>

    <phase name="skill-md" number="2">
      <description>SKILL.md Integration (--embed-in)</description>

      <if condition="--embed-in provided">
        <ask-user-question>
          <question>How should the workflow be incorporated into the SKILL.md?</question>
          <option label="Reference mode">Add a reference tag and copy the workflow to the skill's references/ directory</option>
          <option label="Embed mode">Convert the XML workflow into SKILL.md step definitions directly</option>
        </ask-user-question>

        <if condition="reference-mode">
          <action>Copy workflow to `<skill-dir>/references/<slug>.md` and add `<reference name="workflow" path="references/<slug>.md" />` to the SKILL.md.</action>
        </if>

        <if condition="embed-mode">
          <action>Convert `<step>` elements into the SKILL.md `<steps>` format (see Section 8 of workflow-format.md). Tag translations:</action>
          <constraint>
          - `<gate>` + `<condition>` → `<if condition="gate-condition">`
          - `<command>` → `<command language="bash" tool="Bash">`
          - `<action>` → `<action>` (same)
          - `<prerequisite ref="">` → dependency note in step description
          - `<references>` → inline the referenced values (SKILL files don't use `<references>`)
          - `<boundaries>` + `<rule>` → `<constraint>`
          - `<anti-patterns>` → `<constraint>` (reframe as positive rule)
          - `<critical>` → `<constraint>` with strong language
          </constraint>
        </if>
      </if>
    </phase>

    <constraint>Ask via AskUserQuestion before modifying any existing file.</constraint>
  </step>

  <step id="git-workflow" number="7">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <constraint>Only auto-commit .things/ changes. Don't auto-commit project files (CLAUDE.md, .claude/workflows/) -- those are the user's project.</constraint>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "workflow: <title>"`, and `git push` for .things/ changes.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the workflow archive?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the files have been saved.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
    Created workflow: **<title>** (<step_count> steps, scope: `<scope>`)
    Archive: `<home>/.things/playbook/workflows/<slug>.md`
    Working copy: `<target path>` (or "none -- archive only")
    References updated: `<list of files modified, or "none">`
    Tags: `<tags>`
    </completion-message>
  </step>

</steps>
