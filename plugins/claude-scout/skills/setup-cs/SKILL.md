---
name: setup-cs
description: "Initialize claude-scout in .things/ - configure a tracking target, set up git snapshots, auto-detect changelogs, register collections. Required before other claude-scout skills."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Initialize the `claude-scout` plugin within `~/.things/`. Configures a target directory to track, initializes git snapshotting via `snapshot.sh`, auto-detects changelogs and plugin scan paths, registers collections in the registry, and takes an initial baseline snapshot.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first to initialize .things/." Then stop.<exit /></if>

      <if condition="reconfigure-argument">
        <read path="<home>/.things/claude-scout/preferences.json" output="existing-prefs" />
        <read path="<home>/.things/claude-scout/targets.json" output="existing-targets" />
        <action>Show current settings as defaults throughout.</action>
      </if>
    </load-config>
  </step>

  <step id="determine-script-path" number="2">
    <description>Determine Script Path</description>

    <action>Read `<home>/.claude/plugins/installed_plugins.json` to find the cached install path for `claude-scout`. The `snapshot.sh` script lives at `<cached-path>/scripts/snapshot.sh`.</action>

    <constraint>If the cached path cannot be determined, fall back to using `${CLAUDE_PLUGIN_ROOT}/scripts/snapshot.sh` and note that this path may need updating.</constraint>
  </step>

  <step id="configure-target" number="3">
    <description>Configure Tracking Target</description>

    <ask-user-question>
      <question>Which directory should claude-scout track?</question>
      <option label="~/.claude/ (Recommended)">Track the Claude Code home directory for plugin and config changes</option>
      <option label="Custom path">Track a different directory</option>
    </ask-user-question>

    <if condition="custom-path">
      <ask-user-question>
        <question>Enter the absolute path to track:</question>
      </ask-user-question>
    </if>

    <action>Validate that the target path exists.</action>
    <if condition="path-not-found">Tell the user the path doesn't exist and stop.<exit /></if>

    <ask-user-question>
      <question>What should this target be called?</question>
      <option label="claude-home (Recommended)">For ~/.claude/ tracking</option>
      <option label="Custom ID">Enter a custom identifier (kebab-case)</option>
    </ask-user-question>

    <action>Set display_name based on target ID (e.g., "Claude Code Home" for claude-home).</action>

    <action>Check if target path is already tracked in existing targets.json.</action>
    <if condition="already-tracked">Tell the user this path is already tracked as target `<id>`. Offer to reconfigure or stop.<exit /></if>
  </step>

  <step id="create-directories" number="4">
    <description>Create Plugin Directories</description>

    ```bash
    mkdir -p <home>/.things/claude-scout/snapshots/<target-id>
    mkdir -p <home>/.things/claude-scout/changelogs/<target-id>
    mkdir -p <home>/.things/claude-scout/deps/<target-id>
    ```
  </step>

  <step id="init-git" number="5">
    <description>Initialize Git Tracking</description>

    <action>Run snapshot.sh init to set up git tracking on an orphan branch.</action>

    <command language="bash" tool="Bash">bash <script-path>/snapshot.sh init "<target-path>" claude-scout</command>

    <action>Parse the JSON output. If status is "exists", the branch already exists — this is fine for reconfigure.</action>
    <if condition="error">Report the error and stop.<exit /></if>
  </step>

  <step id="auto-detect" number="6">
    <description>Auto-Detect Changelogs and Plugin Paths</description>

    <action>Scan the target directory for changelog files:</action>
    - Check `cache/changelog.md` (Claude Code's changelog location)
    - Check `CHANGELOG.md` in root
    - Check `changelog.md` in root

    <action>For each found changelog, determine type:</action>
    - If contains `## [version]` pattern → `keep-a-changelog`
    - Otherwise → `claude-variant`

    <action>Scan for plugin-related paths:</action>
    - Check if `plugins/installed_plugins.json` exists
    - Check if `plugins/cache/` directory exists

    <action>Report findings to the user. Don't ask for confirmation — just show what was found.</action>
  </step>

  <step id="gather-preferences" number="7">
    <description>Gather Preferences</description>

    <ask-user-question>
      <question>How should snapshots be triggered?</question>
      <option label="Manual (Recommended)">Take snapshots explicitly with /cs-snapshot</option>
      <option label="Daily">Remind to snapshot if none taken today (via /whats-new-cs)</option>
    </ask-user-question>

    <ask-user-question>
      <question>Default diff output level?</question>
      <option label="Summary (Recommended)">File counts and categories — compact overview</option>
      <option label="Detailed">Individual file changes with context</option>
      <option label="Full">Complete diff output including content changes</option>
    </ask-user-question>
  </step>

  <step id="write-data-files" number="8">
    <description>Write Data Files</description>

    <write path="<home>/.things/claude-scout/preferences.json">

    ```json
    {
      "auto_snapshot": "<manual|daily>",
      "default_diff_output": "<summary|detailed|full>",
      "default_target": "<target-id>"
    }
    ```

    </write>

    <write path="<home>/.things/claude-scout/targets.json">

    ```json
    {
      "version": 1,
      "targets": {
        "<target-id>": {
          "id": "<target-id>",
          "path": "<target-path>",
          "display_name": "<display-name>",
          "created": "<YYYY-MM-DD>",
          "last_snapshot": null,
          "snapshot_count": 0,
          "git_branch": "claude-scout",
          "changelogs": [<detected changelogs>],
          "plugin_scan_paths": [<detected paths>]
        }
      }
    }
    ```

    <constraint>If reconfiguring, merge new target into existing targets — don't overwrite other targets.</constraint>

    </write>

    <if condition="index.json missing">
    <write path="<home>/.things/claude-scout/index.json">

    ```json
    {
      "version": 1,
      "last_updated": "<current_date>",
      "total_targets": 1,
      "by_type": {"snapshot": 0, "changelog": 0, "dep_scan": 0},
      "items": []
    }
    ```

    </write>
    </if>

    <if condition="tags.json missing">
    <write path="<home>/.things/claude-scout/tags.json">

    ```json
    {
      "last_updated": "<current_date>",
      "tags": {}
    }
    ```

    </write>
    </if>

    <write path="<home>/.things/claude-scout/snapshots/<target-id>/snapshot-log.json">

    ```json
    {
      "version": 1,
      "target_id": "<target-id>",
      "last_updated": null,
      "entries": []
    }
    ```

    </write>
  </step>

  <step id="register-collections" number="9">
    <description>Register Collections in Registry</description>

    <read path="<home>/.things/registry.json" output="registry" />

    <action>Determine the absolute path to the rebuild script. Read the plugin's cached install path from `~/.claude/plugins/installed_plugins.json` for the `claude-scout` plugin. The rebuild_command must use this absolute cached path.</action>

    <constraint>If the cached path cannot be determined, use a placeholder: `"python3 <UPDATE-WITH-CACHED-PATH>/scripts/rebuild-index.py ${THINGS_PATH}"`</constraint>

    <action>Add three collection entries to `registry.json`:</action>

    <schema name="snapshots-collection">

    ```json
    {
      "claude-scout/snapshots": {
        "plugin": "claude-scout",
        "description": "Git snapshot metadata per tracked target",
        "tags_field": null,
        "item_structure": {
          "directory_per_item": true,
          "file_pattern": "snapshot-log.json"
        },
        "index_schema": {
          "required_fields": {
            "target_id": "string",
            "count": "number"
          }
        },
        "master_index": "claude-scout/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```

    </schema>

    <schema name="changelogs-collection">

    ```json
    {
      "claude-scout/changelogs": {
        "plugin": "claude-scout",
        "description": "Parsed changelog caches per tracked target",
        "tags_field": null,
        "item_structure": {
          "directory_per_item": true,
          "file_pattern": "parsed.json"
        },
        "index_schema": {
          "required_fields": {
            "target_id": "string",
            "total_entries": "number"
          }
        },
        "master_index": "claude-scout/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```

    </schema>

    <schema name="deps-collection">

    ```json
    {
      "claude-scout/deps": {
        "plugin": "claude-scout",
        "description": "Plugin dependency maps per tracked target",
        "tags_field": null,
        "item_structure": {
          "directory_per_item": true,
          "file_pattern": "dep-map.json"
        },
        "index_schema": {
          "required_fields": {
            "target_id": "string",
            "plugins_scanned": "number"
          }
        },
        "master_index": "claude-scout/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```

    </schema>

    <action>Merge all three into `registry.json`'s `collections` object and write the file.</action>
  </step>

  <step id="update-environment" number="10">
    <description>Update Environment Tracking</description>

    <action>Read `config.json`, find the current hostname's environment entry, and add `"claude-scout"` to its `plugins` array if not already present. Write back.</action>
  </step>

  <step id="initial-snapshot" number="11">
    <description>Take Initial Baseline Snapshot</description>

    <command language="bash" tool="Bash">bash <script-path>/snapshot.sh snapshot "<target-path>" claude-scout "initial baseline"</command>

    <action>Parse the JSON output. Update snapshot-log.json and targets.json with the snapshot entry.</action>
  </step>

  <step id="parse-changelogs" number="12">
    <description>Parse Detected Changelogs</description>

    <if condition="changelogs-detected">
      <action>For each detected changelog, run parse-changelog.py:</action>
      <command language="bash" tool="Bash">python3 <script-path>/parse-changelog.py "<target-path>/<changelog-relative-path>" "<home>/.things/claude-scout/changelogs/<target-id>/parsed.json"</command>
      <action>Report how many entries were parsed.</action>
    </if>
  </step>

  <step id="git-workflow" number="13">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "setup: claude-scout"`, and `git push` in `<home>/.things/`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the claude-scout setup?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the setup is complete and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="14">
    <description>Confirm Setup</description>

    <completion-message>
    claude-scout is ready!

    - Target: `<display-name>` (`<target-path>`)
    - Snapshots: `<home>/.things/claude-scout/snapshots/<target-id>/`
    - Changelogs detected: `<count>`
    - Snapshot mode: `<auto_snapshot>`
    - Diff output: `<default_diff_output>`
    - Initial baseline captured: `<sha>`

    Commands:
    - `/cs-snapshot` -- Capture current state
    - `/diff-cs` -- Show changes between snapshots
    - `/whats-new-cs` -- Human-friendly change summary
    - `/cs-changelog` -- Parse and query changelogs
    - `/cs-dep-doctor` -- Plugin health check
    </completion-message>
  </step>

</steps>
