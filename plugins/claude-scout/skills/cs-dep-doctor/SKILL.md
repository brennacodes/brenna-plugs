---
name: cs-dep-doctor
description: "Plugin health check — scans all installed plugins for path dependencies, cross-references with recent changes, classifies risk (HIGH/MEDIUM/LOW), and suggests fixes."
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[target-id] [--rescan] [--plugin <name>] [--verbose]"
---

<purpose>
Check the health of installed plugins relative to a tracked target directory. Builds a dependency map by scanning all installed plugins for path references to the target, then cross-references with recent snapshot changes to identify which plugins might be affected by structural changes. Classifies risk and suggests remediation.
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
    - **--rescan**: Force re-scan of plugin dependencies (ignore cached dep-map)
    - **--plugin**: Only check a specific plugin
    - **--verbose**: Show all path references, not just affected ones

    <action>Look up target in targets.json.</action>
  </step>

  <step id="determine-script-path" number="3">
    <description>Determine Script Path</description>

    <action>Read `<home>/.claude/plugins/installed_plugins.json` to find the cached install path for `claude-scout`. Scripts live at `<cached-path>/scripts/`.</action>
    <constraint>Fall back to `${CLAUDE_PLUGIN_ROOT}/scripts/` if cached path unavailable.</constraint>
  </step>

  <step id="build-dep-map" number="4">
    <description>Build or Load Dependency Map</description>

    <read path="<home>/.things/claude-scout/deps/<target-id>/dep-map.json" output="deps" optional="true" />

    <if condition="deps missing OR --rescan">
      <action>Run scan-deps.py to build the dependency map:</action>
      <command language="bash" tool="Bash">python3 <script-path>/scan-deps.py "<target-id>" "<target-path>" "<home>/.things/claude-scout/deps/<target-id>/dep-map.json" "<home>/.claude/plugins/installed_plugins.json"</command>
      <read path="<home>/.things/claude-scout/deps/<target-id>/dep-map.json" output="deps" />
    </if>

    <action>Report scan summary: `<plugins_scanned> plugins scanned, <plugins_with_deps> have dependencies`.</action>
  </step>

  <step id="get-recent-changes" number="5">
    <description>Get Recent Changes</description>

    <action>Get the diff since the last-but-one snapshot to see what changed recently:</action>
    <command language="bash" tool="Bash">git -C "<target-path>" checkout "<git-branch>" -q 2>/dev/null && git -C "<target-path>" diff --name-status HEAD~1..HEAD 2>/dev/null</command>

    <action>Also check for uncommitted changes:</action>
    <command language="bash" tool="Bash">git -C "<target-path>" status --porcelain 2>/dev/null | head -100</command>

    <action>Build a list of all changed paths (both committed and uncommitted).</action>
  </step>

  <step id="cross-reference" number="6">
    <description>Cross-Reference Dependencies with Changes</description>

    <action>For each plugin in the dependency map, check if any of its referenced paths match the changed files.</action>

    <action>Classify risk level for each match:</action>

    | Risk | Condition | Description |
    |------|-----------|-------------|
    | HIGH | Plugin directly references a deleted or renamed file | The exact file the plugin depends on is gone |
    | MEDIUM | A parent directory was restructured (files added/removed) | The directory structure the plugin navigates has changed |
    | LOW | A sibling file in the same directory changed | The plugin's referenced files are intact but neighbors changed |

    <if condition="--plugin provided">
      <action>Only show results for the specified plugin.</action>
    </if>
  </step>

  <step id="present-results" number="7">
    <description>Present Results</description>

    <if condition="no plugins affected">
      <completion-message>
      Doctor check: **All clear**

      - Plugins scanned: <plugins_scanned>
      - Plugins with `<target>` dependencies: <plugins_with_deps>
      - Recent changes: <change_count> files
      - Affected plugins: 0

      No installed plugins are affected by recent changes.
      </completion-message>
    </if>

    <if condition="plugins affected">
      <completion-message>
      Doctor check: **<risk_count> issues found**

      <for each affected plugin, sorted by risk>
      ### <plugin-name> — <RISK_LEVEL>
      - References: `<path>` (line <line> in `<file>`)
      - Change: `<what happened to the referenced path>`
      - Suggestion: <remediation>
      </for>

      <if verbose>
      **Full dependency map:**
      <all dependencies for all plugins>
      </if>

      **Unaffected plugins with dependencies** (<count>):
      <list of plugin names>
      </completion-message>
    </if>
  </step>

</steps>
