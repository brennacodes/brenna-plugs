---
name: repair-things
description: "Scan installed plugins, detect missing or stale registry entries, and repair them. Use when indexes aren't rebuilding, after plugin upgrades, or when 'validate-things' reports stale paths."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run] [--rebuild-all]"
---

<purpose>
Scan installed brenna-plugs plugins, compare expected collection registrations against `registry.json`, and fix missing, stale, or legacy entries. Optionally trigger a full rebuild of all indexes.
</purpose>

<steps>

  <step id="load-state" number="1">
    <description>Load State</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/registry.json" output="registry" />
      <if condition="registry-missing">Tell the user: "No registry.json found. Run `/things:setup-things` first." Then stop.<exit /></if>

      <read path="<home>/.claude/plugins/installed_plugins.json" output="installed-plugins" />
      <if condition="installed-plugins-missing">Tell the user: "Cannot read installed_plugins.json — no plugin install data available." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="check-collections" number="2">
    <description>Check Expected Collections Against Registry</description>

    <action>Use the manifest below to check each expected collection. For each collection, determine its status.</action>

    <manifest name="expected-collections">
    The following brenna-plugs plugins should have these collections registered:

    **for-the-record** (2 collections):
    - `for-the-record/docs`: plugin=for-the-record, tags_field=frontmatter.tags, rebuild_command=`python3 ${PLUGIN_PATH:for-the-record@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`
    - `for-the-record/discussions`: plugin=for-the-record, tags_field=frontmatter.tags, rebuild_command=`python3 ${PLUGIN_PATH:for-the-record@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`

    **i-did-a-thing** (3 collections):
    - `i-did-a-thing/logs`: plugin=i-did-a-thing, tags_field=frontmatter.tags, rebuild_command=`python3 ${PLUGIN_PATH:i-did-a-thing@brenna-plugs}/scripts/rebuild-data.py ${THINGS_PATH}`
    - `i-did-a-thing/arsenal`: plugin=i-did-a-thing, rebuild_command=null
    - `i-did-a-thing/resumes`: plugin=i-did-a-thing, rebuild_command=null

    **playbook** (3 collections):
    - `playbook/plans`: plugin=playbook, tags_field=frontmatter.tags, rebuild_command=`python3 ${PLUGIN_PATH:playbook@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`
    - `playbook/workflows`: plugin=playbook, tags_field=frontmatter.tags, rebuild_command=`python3 ${PLUGIN_PATH:playbook@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`
    - `playbook/reviews`: plugin=playbook, tags_field=frontmatter.tags, rebuild_command=`python3 ${PLUGIN_PATH:playbook@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`

    **claude-scout** (3 collections):
    - `claude-scout/snapshots`: plugin=claude-scout, tags_field=null, rebuild_command=`python3 ${PLUGIN_PATH:claude-scout@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`
    - `claude-scout/changelogs`: plugin=claude-scout, tags_field=null, rebuild_command=`python3 ${PLUGIN_PATH:claude-scout@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`
    - `claude-scout/deps`: plugin=claude-scout, tags_field=null, rebuild_command=`python3 ${PLUGIN_PATH:claude-scout@brenna-plugs}/scripts/rebuild-index.py ${THINGS_PATH}`

    **heres-the-thing** (3 collections):
    - `heres-the-thing/campaigns`: plugin=heres-the-thing, tags_field=json.tags, rebuild_command=null
    - `heres-the-thing/audiences`: plugin=heres-the-thing, tags_field=null, rebuild_command=null
    - `heres-the-thing/outcomes`: plugin=heres-the-thing, tags_field=null, rebuild_command=null
    </manifest>

    <action>For each expected collection, check `installed_plugins.json` to see if the owning plugin is installed. Then check `registry.json` for the collection entry.</action>

    <statuses>
    Assign one of these statuses to each expected collection:

    - **OK**: Collection is registered and rebuild_command uses the portable `${PLUGIN_PATH:}` format (or is null as expected)
    - **MISSING**: Plugin is installed but collection is not in the registry
    - **STALE_PATH**: Collection is registered but rebuild_command contains an absolute path that doesn't exist on disk
    - **LEGACY_FORMAT**: Collection is registered but rebuild_command uses an absolute path instead of the portable `${PLUGIN_PATH:}` format
    - **NOT_INSTALLED**: The owning plugin is not in `installed_plugins.json` (skip — nothing to fix)
    </statuses>
  </step>

  <step id="report" number="3">
    <description>Report Findings</description>

    <action>Display a table summarizing the status of every expected collection.</action>

    <template name="report">
    ```
    Collection Registration Health:

    | Collection                   | Plugin          | Status         |
    |------------------------------|-----------------|----------------|
    | for-the-record/docs          | for-the-record  | OK             |
    | for-the-record/discussions   | for-the-record  | MISSING        |
    | i-did-a-thing/logs           | i-did-a-thing   | LEGACY_FORMAT  |
    | ...                          | ...             | ...            |

    Summary: 8 OK, 3 MISSING, 1 LEGACY_FORMAT, 2 NOT_INSTALLED
    ```
    </template>

    <if condition="all-ok">Tell the user everything looks good. Stop unless `--rebuild-all` was passed.<exit /></if>
  </step>

  <step id="dry-run-check" number="4">
    <description>Handle --dry-run</description>

    <if condition="dry-run-flag">
      <action>Show what changes would be made (additions, updates) and stop.</action>
      <template name="dry-run">
      ```
      Dry run — changes that would be applied:

      ADD    for-the-record/discussions  (full collection definition)
      UPDATE i-did-a-thing/logs          rebuild_command → portable format
      ADD    playbook/plans              (full collection definition)
      ...
      ```
      </template>
      <exit />
    </if>
  </step>

  <step id="apply-fixes" number="5">
    <description>Apply Fixes</description>

    <ask-user>
    "Found <n> collections to fix (<x> missing, <y> stale/legacy). Apply fixes to registry.json?"
    </ask-user>

    <if condition="user-confirms">
      <action>Read `registry.json` fresh.</action>

      <action>For each MISSING collection: add the full collection definition from the manifest to `registry.json`.</action>

      <action>For each STALE_PATH or LEGACY_FORMAT collection: update only the `rebuild_command` to the portable `${PLUGIN_PATH:}` format from the manifest. Leave all other fields unchanged.</action>

      <action>Write updated `registry.json`.</action>

      <action>Report what was changed.</action>
    </if>
  </step>

  <step id="rebuild-all" number="6">
    <description>Optional: Rebuild All Indexes (--rebuild-all)</description>

    <if condition="rebuild-all-flag">
      <action>For each collection in the updated registry that has a non-null `rebuild_command`:</action>

      <phase name="resolve-and-run" number="1">
      1. Resolve `${PLUGIN_PATH:}` tokens in the rebuild_command by reading `installed_plugins.json`
      2. Execute the resolved command with `THINGS_PATH` exported
      3. Report success or failure for each
      </phase>

      <phase name="rebuild-tags" number="2">
      Run `rebuild-tags.sh` to rebuild the central tag index:
      <command language="bash" tool="Bash">THINGS_PATH="<home>/.things" bash "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/scripts/rebuild-tags.sh"</command>
      </phase>

      <action>Report rebuild results.</action>
    </if>
  </step>

  <step id="git-workflow" number="7">
    <description>Handle Git Workflow</description>

    <if condition="changes-were-made">
      <git-workflow>
        <action>Read git workflow from `<home>/.things/config.json`.</action>

        <if condition="workflow-auto">Automatically `git add registry.json`, `git commit -m "fix: repair collection registrations"`, and `git push` in `<home>/.things/`.</if>
        <if condition="workflow-ask">
          <ask-user-question>
            <question>Commit the registry fixes?</question>
            <option>Yes -- commit and push</option>
            <option>Commit only</option>
            <option>No -- I'll handle git myself</option>
          </ask-user-question>
        </if>
        <if condition="workflow-manual">Tell the user the fixes are applied and they can commit when ready.</if>
      </git-workflow>
    </if>
  </step>

</steps>
