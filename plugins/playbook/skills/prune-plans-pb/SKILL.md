---
name: prune-plans-pb
description: "Delete old plan versions or entire plans based on retention preferences, explicit age, or interactive selection. Keeps the latest version of each plan by default."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--older-than <days>] [--interactive]"
---

<purpose>
Prune old plan versions from `~/.things/playbook/plans/`. Three modes: use the configured `plan_retention_days` preference (default), specify `--older-than <days>` explicitly, or use `--interactive` to pick specific plans or versions. Default and `--older-than` modes delete old VERSIONS but always keep the latest version per slug. Interactive mode allows deleting entire plans or specific versions.
</purpose>

<critical-constraint>
Never delete the only remaining version of a plan. If a plan directory has only one `v*.md` file, it cannot be pruned in age-based modes. In interactive mode, warn the user and require explicit confirmation.
</critical-constraint>

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

  <step id="determine-mode" number="2">
    <description>Determine Pruning Mode</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **--older-than <days>**: Delete plan versions older than N days (keeps latest per slug)
    - **--interactive**: Show all plans with version counts for manual selection

    <if condition="--interactive">
      <action>Use interactive mode (step 4).</action>
    </if>

    <if condition="--older-than provided">
      <action>Use the explicit days value.</action>
    </if>

    <if condition="no flags">
      <action>Use `preferences.plan_retention_days`.</action>
      <if condition="plan_retention_days is null or missing">
        <action>Tell the user: "No retention policy configured and no `--older-than` flag provided. Either run `/setup-pb reconfigure` to set `plan_retention_days`, or use `--older-than <days>` or `--interactive`." Then stop.</action>
        <exit />
      </if>
    </if>
  </step>

  <step id="find-candidates" number="3">
    <description>Find Deletion Candidates (age-based)</description>

    <if condition="age-based mode">
      <action>For each plan directory in `<home>/.things/playbook/plans/`, list all `v*.md` files. For each file, parse the date from frontmatter. Calculate age in days from today.</action>

      <action>Filter to versions older than the threshold, but NEVER include the latest (highest-numbered) version of any plan.</action>

      <if condition="no candidates">
        <action>Tell the user: "No plan versions older than <N> days found (latest versions are always kept)." Then stop.</action>
        <exit />
      </if>

      <output>
      Plan versions older than <N> days (latest versions excluded):

        <slug>/v<N>.md (<date>, <age> days old)
        <slug>/v<N>.md (<date>, <age> days old)
        ...

      Total: <count> versions to delete
      </output>

      <ask-user-question>
        <question>Delete these <count> old plan versions?</question>
        <option label="Yes">Delete all listed versions</option>
        <option label="No">Cancel -- keep everything</option>
      </ask-user-question>
    </if>
  </step>

  <step id="interactive-selection" number="4">
    <description>Interactive Selection</description>

    <if condition="interactive mode">
      <action>List all plan directories with their version counts and latest version info.</action>

      <if condition="no plans">
        <action>Tell the user: "No plans found." Then stop.</action>
        <exit />
      </if>

      <output>
      Plans:

        1. <slug>/ -- <version-count> versions (latest: v<N>, "<title>", <status>)
        2. <slug>/ -- <version-count> versions (latest: v<N>, "<title>", <status>)
        ...
      </output>

      <ask-user-question>
        <question>Which plans would you like to manage? Enter numbers (e.g., "1,3") or "all".</question>
      </ask-user-question>

      <action>For each selected plan, show individual versions:</action>

      <output>
      <slug>/
        v1.md -- <date>, "<title>" <status>
        v2.md -- <date>, "<title>" <status>  (latest)
      </output>

      <ask-user-question>
        <question>What would you like to delete? Enter version numbers (e.g., "v1"), "old" (all except latest), or "all" (entire plan).</question>
      </ask-user-question>

      <if condition="user-chose-all AND plan-has-only-one-version">
        <ask-user-question>
          <question>This is the only version of "<slug>". Deleting it removes the entire plan. Are you sure?</question>
          <option label="Yes">Delete the plan entirely</option>
          <option label="No">Cancel</option>
        </ask-user-question>
      </if>

      <ask-user-question>
        <question>Confirm: delete <count> selected items?</question>
        <option label="Yes">Delete selected</option>
        <option label="No">Cancel</option>
      </ask-user-question>
    </if>
  </step>

  <step id="delete-files" number="5">
    <description>Delete Files</description>

    <action>Delete each confirmed file.</action>
    <command language="bash" tool="Bash">rm "<home>/.things/playbook/plans/<slug>/v<N>.md"</command>

    <action>If all versions of a plan were deleted, remove the empty directory.</action>
    <command language="bash" tool="Bash">rmdir "<home>/.things/playbook/plans/<slug>" 2>/dev/null || true</command>
  </step>

  <step id="rebuild" number="6">
    <description>Trigger Rebuild</description>

    <action>Read `<home>/.things/registry.json` to find the rebuild command for `playbook/plans`. Execute it.</action>
    <constraint>If the rebuild command is not found, fall back to: `python3 <cached-path>/scripts/rebuild-index.py <home>/.things`</constraint>
  </step>

  <step id="git-workflow" number="7">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "prune: <count> plan versions"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the pruned plans?</question>
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
    Pruned <count> plan versions.
    Remaining: <remaining-plans> plans with <remaining-versions> total versions
    </completion-message>
  </step>

</steps>
