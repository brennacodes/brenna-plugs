---
name: cs-changelog
description: "Parse and query changelogs — filter by version, change type, keyword, or show latest entries. Works with target changelogs and individual plugin CHANGELOGs."
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[target-id|plugin-name] [--version <ver>] [--type <type>] [--search <kw>] [--latest <n>]"
---

<purpose>
Parse and query changelog files. Sources include a target's configured changelogs or a specific plugin's CHANGELOG.md from the plugin cache. Uses `parse-changelog.py` with SHA-256 hash caching for fast re-runs. Filter by version, change type, keyword, or get the latest N entries. See `references/changelog-format.md` for supported formats.
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

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **source**: First positional arg — either a target-id (from targets.json) or a plugin name
    - **--version**: Show a specific version's changes
    - **--since**: Show all versions since this version
    - **--type**: Filter by change type (added, fixed, changed, removed, improved, deprecated, security)
    - **--search**: Keyword search across all change descriptions
    - **--latest**: Show only the latest N entries (default: 5 if no other filters)

    <action>Determine source type:</action>
    <if condition="source matches a target-id">Use the target's configured changelogs.</if>
    <if condition="source looks like a plugin name">
      <action>Look up the plugin in `<home>/.claude/plugins/installed_plugins.json`. Find its cached path and check for CHANGELOG.md.</action>
    </if>
    <if condition="no source provided">Use `preferences.default_target`'s changelogs.</if>
  </step>

  <step id="determine-script-path" number="3">
    <description>Determine Script Path</description>

    <action>Read `<home>/.claude/plugins/installed_plugins.json` to find the cached install path for `claude-scout`. Scripts live at `<cached-path>/scripts/`.</action>
    <constraint>Fall back to `${CLAUDE_PLUGIN_ROOT}/scripts/` if cached path unavailable.</constraint>
  </step>

  <step id="parse-changelog" number="4">
    <description>Parse Changelog</description>

    <if condition="target source">
      <action>For each of the target's configured changelogs:</action>
      <command language="bash" tool="Bash">python3 <script-path>/parse-changelog.py "<target-path>/<changelog-relative-path>" "<home>/.things/claude-scout/changelogs/<target-id>/parsed.json"</command>
      <read path="<home>/.things/claude-scout/changelogs/<target-id>/parsed.json" output="parsed" />
    </if>

    <if condition="plugin source">
      <action>Parse the plugin's changelog to a temp location or in-memory:</action>
      <command language="bash" tool="Bash">python3 <script-path>/parse-changelog.py "<plugin-cached-path>/CHANGELOG.md" "/tmp/claude-scout-changelog-$$.json"</command>
      <read path="/tmp/claude-scout-changelog-$$.json" output="parsed" />
    </if>
  </step>

  <step id="filter-entries" number="5">
    <description>Filter Entries</description>

    <action>Apply filters to the parsed entries:</action>

    <if condition="--version">Show only the entry matching that version.</if>
    <if condition="--since">Show all entries from that version onward (inclusive).</if>
    <if condition="--type">Within each entry, show only changes matching the type.</if>
    <if condition="--search">Show only entries/changes where the description contains the keyword (case-insensitive).</if>
    <if condition="--latest">Limit to the first N entries after other filters.</if>
    <if condition="no filters">Show the latest 5 entries.</if>
  </step>

  <step id="present-results" number="6">
    <description>Present Results</description>

    <if condition="no entries match filters">
      <action>Report "No changelog entries match your filters."</action>
    </if>

    <if condition="entries found">
      <completion-message>
      Changelog: `<source-name>` (<total> total entries, showing <shown>)

      <for each filtered entry>
      ## <version> <if date>(<date>)</if>
      <for each change>
      - **<type>**: <description>
      </for>
      </for>
      </completion-message>
    </if>
  </step>

</steps>
