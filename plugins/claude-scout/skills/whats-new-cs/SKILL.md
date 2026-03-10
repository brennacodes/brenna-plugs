---
name: whats-new-cs
description: "Human-friendly change summary — categorizes filesystem changes, correlates with changelog entries, and flags potential plugin impact. The quick status check."
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[target-id] [--since <time|snapshot>] [--changelog-only]"
---

<purpose>
Generate a human-friendly summary of what changed in a tracked target since the last snapshot (or a given time). Categorizes changes into structural, configuration, plugin, and data changes. Correlates with parsed changelog entries when available. Flags structural changes that might affect installed plugins and suggests running `/cs-dep-doctor`.
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

  <step id="resolve-target-and-args" number="2">
    <description>Resolve Target and Arguments</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **target-id**: First positional arg, or fall back to `preferences.default_target`
    - **--since**: Time or snapshot ref. Default: last snapshot
    - **--changelog-only**: Only show changelog entries, skip filesystem diff

    <action>Look up target in targets.json.</action>
  </step>

  <step id="check-daily-reminder" number="3">
    <description>Check Daily Snapshot Reminder</description>

    <if condition="preferences.auto_snapshot == 'daily'">
      <read path="<home>/.things/claude-scout/snapshots/<target-id>/snapshot-log.json" output="log" />
      <action>Check if the last snapshot was taken today.</action>
      <if condition="no-snapshot-today">
        <action>Suggest: "No snapshot taken today. Run `/cs-snapshot` first for the most current view."</action>
      </if>
    </if>
  </step>

  <step id="get-changes" number="4">
    <description>Get Changes</description>

    <if condition="not --changelog-only">
      <action>Ensure the target repo is on the correct branch:</action>
      <command language="bash" tool="Bash">git -C "<target-path>" checkout "<git-branch>" -q 2>/dev/null</command>

      <action>Stage all to see what would change (without committing):</action>
      <command language="bash" tool="Bash">git -C "<target-path>" add -A --dry-run 2>/dev/null | head -200</command>
      <command language="bash" tool="Bash">git -C "<target-path>" status --porcelain 2>/dev/null | head -200</command>

      <action>If `--since` provided, also get committed changes since that ref:</action>
      <command language="bash" tool="Bash">git -C "<target-path>" diff --name-status "<from-ref>"..HEAD 2>/dev/null</command>
    </if>
  </step>

  <step id="categorize-changes" number="5">
    <description>Categorize Changes</description>

    <action>Sort changes into categories based on file paths and types:</action>

    | Category | Pattern | Example |
    |----------|---------|---------|
    | Structural | New/removed directories, moved files | New `plugins/cache/brenna-plugs/` dir |
    | Configuration | `*.json` in root or config dirs | `settings.json` modified |
    | Plugin changes | Files under `plugins/` | `plugins/cache/` updated |
    | Data growth | New files in data dirs | New session files |
    | Changelog | Changelog files modified | `cache/changelog.md` updated |

    <action>Count files per category and note notable changes.</action>
  </step>

  <step id="correlate-changelog" number="6">
    <description>Correlate with Changelog</description>

    <read path="<home>/.things/claude-scout/changelogs/<target-id>/parsed.json" output="parsed" optional="true" />

    <if condition="parsed exists">
      <action>Find changelog entries that are new since the last check. Compare version numbers or dates.</action>
      <action>For each new changelog entry, show version, date, and a summary of changes.</action>
    </if>

    <if condition="changelog file was modified but parsed is stale">
      <action>Note: "Changelog has been updated but not yet parsed. Run `/cs-snapshot` to refresh."</action>
    </if>
  </step>

  <step id="assess-impact" number="7">
    <description>Assess Plugin Impact</description>

    <if condition="structural changes detected">
      <read path="<home>/.things/claude-scout/deps/<target-id>/dep-map.json" output="deps" optional="true" />

      <if condition="deps exists">
        <action>Cross-reference changed paths with plugin dependencies. Flag any plugins that reference changed files.</action>
      </if>

      <action>If structural changes detected (new/removed dirs, renamed files), suggest running `/cs-dep-doctor` for a full health check.</action>
    </if>
  </step>

  <step id="present-summary" number="8">
    <description>Present Summary</description>

    <completion-message>
    What's new in `<display-name>`:

    **Filesystem Changes** (since <since-description>):
    <categorized change summary>

    **Changelog** (<if new entries>latest: v<version></if><else>no new entries</else>):
    <changelog summary or "no changelog configured">

    <if plugin-impact>
    **Plugin Impact**: <N> plugins may be affected by structural changes.
    Run `/cs-dep-doctor` for details.
    </if>

    <if no-changes>
    No changes detected since last snapshot.
    </if>
    </completion-message>
  </step>

</steps>
