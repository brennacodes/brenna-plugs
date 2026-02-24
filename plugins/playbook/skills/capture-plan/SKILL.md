---
name: capture-plan
description: "Import a plan from ~/.claude/plans/ into playbook with versioning, references, and status tracking. Plans are stored as versioned directories and can be reviewed, resumed, and tracked through implementation."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<thing> [--status active] [--project <name>] [--references path1,path2]"
---

<purpose>
Import a plan from `~/.claude/plans/` into `.things/playbook/plans/` with proper frontmatter and versioning. Plans are stored as `plans/<slug>/v<N>.md` -- new imports of the same plan increment the version number. Plans can link to other `.things/` data via the `references` field. See `references/plan-format.md` for the frontmatter schema and status lifecycle.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.<exit /></if>

      <read path="<home>/.things/playbook/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-pb` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **thing**: The plan to import (search term)
    - **--status**: Override initial status (default: `active`)
    - **--project**: Project name or path to associate
    - **--references**: Comma-separated paths relative to `~/.things/` (e.g., `i-did-a-thing/logs/2026-02-20-api-redesign.md,shared/people/alice.json`)
  </step>

  <step id="find-plan" number="3">
    <description>Find Plan in ~/.claude/plans/</description>

    <action>List all `.md` files in `<home>/.claude/plans/`. For each, read the first ~30 lines to extract a summary (first heading, first paragraph, or plan overview).</action>

    <if condition="thing-provided">
      <action>Match `<thing>` against filenames and content. Rank by relevance.</action>
      <if condition="single-match">Use it.</if>
      <if condition="multiple-matches">
        <action>Show numbered list of matches via AskUserQuestion.</action>
      </if>
      <if condition="no-matches">
        <action>Show all available plans as a numbered list.</action>
      </if>
    </if>

    <if condition="thing-not-provided">
      <action>Show all available plans as a numbered list via AskUserQuestion.</action>
    </if>
  </step>

  <step id="read-plan" number="4">
    <description>Read Full Plan Content</description>

    <action>Read the full content of the selected plan file.</action>
  </step>

  <step id="generate-frontmatter" number="5">
    <description>Generate Frontmatter</description>

    <action>Derive frontmatter fields:</action>
    - `title`: From first H1 heading, or from content summary, or from filename (de-slugified)
    - `date`: Today's date
    - `description`: 1-2 sentence summary of the plan's scope
    - `doc_type`: `"plan"`
    - `status`: From `--status` flag or default `"active"`
    - `source_plan`: Original filename (e.g., `"ethereal-mixing-spark.md"`)
    - `project`: From `--project` flag, or infer from plan content (repo names, project paths), or omit
    - `tags`: Auto-generated from technologies, scope keywords, project name
    - `references`: From `--references` flag or ask the user (see step 6)
    - `slug`: Slugified title
    - `version`: Determined in step 6

    <action>Generate slug from title: `<slugified-title>`</action>
  </step>

  <step id="check-existing" number="6">
    <description>Check for Existing Plan and Determine Version</description>

    <action>Check if `<home>/.things/playbook/plans/<slug>/` directory exists.</action>

    <if condition="directory-exists">
      <action>Find the highest version number: list `v*.md` files, extract numbers, take max. Set version to max + 1.</action>
    </if>

    <if condition="directory-missing">
      <action>Create the directory. Set version to 1.</action>
      <command language="bash" tool="Bash">mkdir -p <home>/.things/playbook/plans/<slug></command>
    </if>

    <if condition="--references not provided">
      <ask-user-question>
        <question>Does this plan reference other .things/ data? (e.g., logs, people, campaigns)</question>
        <option label="No references">No links to other data</option>
        <option-with-text-input>Yes -- enter paths (comma-separated, relative to ~/.things/)</option-with-text-input>
      </ask-user-question>
    </if>

    <action>Add `version` and `slug` to frontmatter.</action>
  </step>

  <step id="write-plan" number="7">
    <description>Write Plan to Playbook</description>

    <write path="<home>/.things/playbook/plans/<slug>/v<version>.md">

    <template name="plan">
    ```markdown
    ---
    title: "<title>"
    date: <YYYY-MM-DD>
    description: "<description>"
    doc_type: "plan"
    status: "<status>"
    slug: "<slug>"
    version: <version>
    source_plan: "<original-filename>"
    project: "<project>"
    references:
      - "<ref1>"
      - "<ref2>"
    tags: [<tags>]
    ---

    <original plan content, preserved verbatim>
    ```
    </template>

    <constraint>If references is empty, write `references: []` as an inline list.</constraint>

    </write>
  </step>

  <step id="handle-source" number="8">
    <description>Handle Source File</description>

    <if condition="preferences.plan_import_behavior == 'move'">
      <action>Delete the original file from `~/.claude/plans/`.</action>
    </if>
    <if condition="preferences.plan_import_behavior == 'copy'">
      <action>Leave the original in place.</action>
    </if>
  </step>

  <step id="git-workflow" number="9">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "plan: <title> (v<version>)"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push this plan?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the plan has been saved.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="10">
    <description>Confirm</description>

    <completion-message>
    Imported: **<title>** (v<version>, status: `<status>`)
    Location: `<home>/.things/playbook/plans/<slug>/v<version>.md`
    Source: `<source_plan>` (<copied|moved>)
    References: <references or "none">
    Tags: `<tags>`

    Next steps:
    - `/review-against <slug>` -- Review branch work against this plan
    - `/resume-plan <slug>` -- Start implementing from the plan
    - `/progress <slug>` -- Check implementation progress
    </completion-message>
  </step>

</steps>
