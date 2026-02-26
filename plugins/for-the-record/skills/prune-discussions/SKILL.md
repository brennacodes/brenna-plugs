---
name: prune-discussions
description: "Delete old discussion files based on retention preferences, explicit age, or interactive selection. Respects configured retention and always confirms before deleting."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--older-than <days>] [--interactive]"
---

<purpose>
Prune old discussions from `~/.things/for-the-record/discussions/`. Three modes: use the configured `discussion_retention_days` preference (default), specify `--older-than <days>` explicitly, or use `--interactive` to pick specific files. Always confirms before deleting.
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

      <read path="<home>/.things/for-the-record/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-ftr` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="determine-mode" number="2">
    <description>Determine Pruning Mode</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **--older-than <days>**: Delete discussions older than N days
    - **--interactive**: Show all discussions for manual selection

    <if condition="--interactive">
      <action>Use interactive mode (step 4).</action>
    </if>

    <if condition="--older-than provided">
      <action>Use the explicit days value.</action>
    </if>

    <if condition="no flags">
      <action>Use `preferences.discussion_retention_days`.</action>
      <if condition="discussion_retention_days is null or missing">
        <action>Tell the user: "No retention policy configured and no `--older-than` flag provided. Either run `/setup-ftr reconfigure` to set `discussion_retention_days`, or use `--older-than <days>` or `--interactive`." Then stop.</action>
        <exit />
      </if>
    </if>
  </step>

  <step id="find-candidates" number="3">
    <description>Find Deletion Candidates (age-based)</description>

    <if condition="age-based mode">
      <action>List all `.md` files in `<home>/.things/for-the-record/discussions/`. Parse the date from each filename (YYYY-MM-DD prefix) or from frontmatter. Calculate age in days from today.</action>

      <action>Filter to files older than the threshold.</action>

      <if condition="no candidates">
        <action>Tell the user: "No discussions older than <N> days found." Then stop.</action>
        <exit />
      </if>

      <output>
      Discussions older than <N> days:

        1. <filename> (<date>, <age> days old)
        2. <filename> (<date>, <age> days old)
        ...

      Total: <count> files to delete
      </output>

      <ask-user-question>
        <question>Delete these <count> discussions?</question>
        <option label="Yes">Delete all listed discussions</option>
        <option label="No">Cancel -- keep everything</option>
      </ask-user-question>
    </if>
  </step>

  <step id="interactive-selection" number="4">
    <description>Interactive Selection</description>

    <if condition="interactive mode">
      <action>List all `.md` files in `<home>/.things/for-the-record/discussions/` with date and title from frontmatter.</action>

      <if condition="no discussions">
        <action>Tell the user: "No discussions found." Then stop.</action>
        <exit />
      </if>

      <output>
      Discussions:

        1. <filename> -- "<title>" (<date>)
        2. <filename> -- "<title>" (<date>)
        ...
      </output>

      <ask-user-question>
        <question>Which discussions would you like to delete? Enter numbers (e.g., "1,3"), a range (e.g., "1-5"), or "all".</question>
      </ask-user-question>

      <ask-user-question>
        <question>Confirm: delete <count> selected discussions?</question>
        <option label="Yes">Delete selected discussions</option>
        <option label="No">Cancel</option>
      </ask-user-question>
    </if>
  </step>

  <step id="delete-files" number="5">
    <description>Delete Files</description>

    <action>Delete each confirmed file from `<home>/.things/for-the-record/discussions/`.</action>
    <command language="bash" tool="Bash">rm "<home>/.things/for-the-record/discussions/<filename>"</command>
  </step>

  <step id="rebuild" number="6">
    <description>Trigger Rebuild</description>

    <action>Read `<home>/.things/registry.json` to find the rebuild command for `for-the-record/discussions`. Execute it.</action>
    <constraint>If the rebuild command is not found, fall back to: `python3 <cached-path>/scripts/rebuild-index.py <home>/.things`</constraint>
  </step>

  <step id="git-workflow" number="7">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "prune: <count> discussions"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the pruned discussions?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the pruning is complete.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
    Pruned <count> discussions.
    Remaining: <remaining-count> discussions in `for-the-record/discussions/`
    </completion-message>
  </step>

</steps>
