---
name: import-pb
description: "Import Claude plan documents from ~/.claude/plans/ into playbook in bulk. Lists available plans with descriptions, lets you pick and choose, and imports selected plans with proper frontmatter and status tracking."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<purpose>
Import Claude plan documents into playbook in bulk. Discovers plans from `~/.claude/plans/`, displays them with meaningful descriptions so the user can pick and choose, and imports selected plans with proper frontmatter using the same flow as `/capture-plan-pb`.
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

  <step id="discover-plans" number="2">
    <description>Discover Available Plans</description>

    <action>List all `.md` files in `<home>/.claude/plans/`.</action>

    <if condition="directory-missing-or-empty">
      <action>Tell the user: "No plan files found in `~/.claude/plans/`. Plans are created when you use Claude Code's plan mode (the `/plan` command or when Claude enters plan mode during a task)." Then stop.</action>
    </if>

    <action>For each plan file, read the content and extract a meaningful description:</action>
    1. Look for the first `#` heading -- use it as the display title
    2. If no heading, derive a title from the filename (replace hyphens with spaces, drop the `.md`)
    3. Read the first paragraph or summary section for a 1-2 sentence description
    4. Note the file modification date (`stat -f %Sm -t %Y-%m-%d <file>` on macOS)
    5. Estimate scope: count top-level sections or checklist items to give a sense of plan size

    <action>Also check which plans have already been imported into `<home>/.things/playbook/plans/` by comparing `source_plan` fields in existing plan frontmatter.</action>
  </step>

  <step id="display-plans" number="3">
    <description>Display Plans for Selection</description>

    <output>
    Plans in ~/.claude/plans/:

      1. <display title>                              <mod date>
         <1-2 sentence description>
         <N sections/items> | <already imported or new>

      2. <display title>                              <mod date>
         <1-2 sentence description>
         <N sections/items> | new

      ...
    </output>

    <constraint>Mark already-imported plans clearly so the user can make an informed choice. Don't hide them -- they may want to re-import an updated version.</constraint>

    <ask-user-question>
      <question>Which plans would you like to import? Enter numbers (e.g., "1,3"), a range (e.g., "1-5"), or "all". Plans already imported will be updated with the latest version.</question>
    </ask-user-question>
  </step>

  <step id="dry-run-check" number="4">
    <description>Handle Dry Run</description>

    <if condition="--dry-run">
      <action>For each selected plan, show what WOULD happen:</action>
      <output>
      Dry run -- no files will be written:

        1. <filename> → playbook/plans/<generated-slug>.md
           Title: "<inferred title>"
           Tags: [<inferred tags>]
           Status: active
           <new import or update of existing>
      </output>
      <action>Stop here.</action>
    </if>
  </step>

  <step id="import-plans" number="5">
    <description>Import Selected Plans</description>

    <action>For each selected plan, use the same import flow as `/capture-plan-pb`:</action>
    1. Read full content
    2. Generate frontmatter:
       - `title`: from first H1 heading or derived from content
       - `date`: today's date
       - `description`: 1-2 sentence summary of the plan's scope
       - `doc_type`: `"plan"`
       - `status`: `"active"`
       - `source_plan`: original filename
       - `tags`: auto-generated from technologies, scope keywords
       - `references`: `[]` (empty -- can be added later via `/update-pb`)
       - `slug`: slugified title
       - `version`: determined from existing versions
    3. Generate slug from title
    4. Check for existing plan directory `<home>/.things/playbook/plans/<slug>/` -- if found, determine next version number (max existing + 1). If not, create the directory and use v1.
    5. Write to `<home>/.things/playbook/plans/<slug>/v<N>.md`
    6. Handle source: copy or move based on `preferences.plan_import_behavior`
  </step>

  <step id="git-workflow" number="6">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "import: <N> plans into playbook"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the imported plans?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the plans have been saved.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="7">
    <description>Confirm</description>

    <completion-message>
    Imported <N> plans into playbook:

    <for each imported plan:>
    - **<title>** → `playbook/plans/<slug>/v<N>.md` (tags: <tags>)

    Next steps:
    - `/review-against-pb <plan>` -- Review branch work against a plan
    - `/progress-pb` -- See progress dashboard for all plans
    </completion-message>
  </step>

</steps>
