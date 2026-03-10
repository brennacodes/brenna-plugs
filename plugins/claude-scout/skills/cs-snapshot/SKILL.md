---
name: cs-snapshot
description: "Capture a git snapshot of a tracked directory — detects changes, commits current state, updates snapshot log. Use to checkpoint before/after updates."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
argument-hint: "[target-id] [--message <msg>] [--tag <tag>] [--force]"
---

<purpose>
Capture the current state of a tracked target directory as a git snapshot. Detects changes since the last snapshot, commits them on the tracking branch, and updates the snapshot log. Skips if nothing changed (unless `--force`). If the target's changelog was modified, re-parses it.
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

      <read path="<home>/.things/claude-scout/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-cs` first." Then stop.<exit /></if>

      <read path="<home>/.things/claude-scout/targets.json" output="targets" />
    </load-config>
  </step>

  <step id="resolve-target" number="2">
    <description>Resolve Target</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **target-id**: First positional arg, or fall back to `preferences.default_target`
    - **--message**: Snapshot message (default: current date/time)
    - **--tag**: Tag to attach to this snapshot entry
    - **--force**: Take snapshot even if no changes detected

    <action>Look up target in targets.json. If not found, list available targets and stop.</action>
  </step>

  <step id="determine-script-path" number="3">
    <description>Determine Script Path</description>

    <action>Read `<home>/.claude/plugins/installed_plugins.json` to find the cached install path for `claude-scout`. Scripts live at `<cached-path>/scripts/`.</action>
    <constraint>Fall back to `${CLAUDE_PLUGIN_ROOT}/scripts/` if cached path unavailable.</constraint>
  </step>

  <step id="check-status" number="4">
    <description>Check for Changes</description>

    <command language="bash" tool="Bash">bash <script-path>/snapshot.sh status "<target-path>" "<git-branch>"</command>

    <action>Parse the JSON output.</action>
    <if condition="has_changes == false AND not --force">
      <action>Report "No changes since last snapshot (<last_date>)." and stop.</action>
      <exit />
    </if>

    <if condition="has_changes == false AND --force">
      <action>Note that snapshot is being forced despite no changes.</action>
    </if>

    <action>Show a brief status: `<added> added, <modified> modified, <deleted> deleted`.</action>
  </step>

  <step id="take-snapshot" number="5">
    <description>Take Snapshot</description>

    <command language="bash" tool="Bash">bash <script-path>/snapshot.sh snapshot "<target-path>" "<git-branch>" "<message>"</command>

    <action>Parse the JSON output. Extract sha, timestamp, files_changed, insertions, deletions.</action>
    <if condition="error">Report the error and stop.<exit /></if>
  </step>

  <step id="update-log" number="6">
    <description>Update Snapshot Log</description>

    <read path="<home>/.things/claude-scout/snapshots/<target-id>/snapshot-log.json" output="log" />

    <action>Append a new entry to the log's `entries` array:</action>

    ```json
    {
      "sha": "<sha>",
      "timestamp": "<timestamp>",
      "message": "<message>",
      "files_changed": <files_changed>,
      "insertions": <insertions>,
      "deletions": <deletions>,
      "tags": ["<tag>"]
    }
    ```

    <constraint>If `--tag` was not provided, use an empty tags array.</constraint>

    <action>Update `last_updated` in the log. Write the file.</action>

    <action>Also update `targets.json`: set `last_snapshot` to the timestamp, increment `snapshot_count`.</action>
  </step>

  <step id="check-changelog" number="7">
    <description>Re-parse Changelog if Modified</description>

    <action>Check if any of the target's configured changelog files were in the changed files.</action>

    <if condition="changelog-modified">
      <action>Run parse-changelog.py to update the cached parse:</action>
      <command language="bash" tool="Bash">python3 <script-path>/parse-changelog.py "<target-path>/<changelog-path>" "<home>/.things/claude-scout/changelogs/<target-id>/parsed.json"</command>
      <action>Report: "Changelog updated — <N> entries parsed."</action>
    </if>
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
    Snapshot captured: `<sha>` (<message>)
    - Files changed: <files_changed>
    - Insertions: <insertions>, Deletions: <deletions>
    <if tag>- Tagged: `<tag>`</if>

    View changes: `/diff-cs` or `/whats-new-cs`
    </completion-message>
  </step>

</steps>
