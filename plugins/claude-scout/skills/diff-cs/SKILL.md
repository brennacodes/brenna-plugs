---
name: diff-cs
description: "Show filesystem changes between snapshots — filter by time range, path pattern, or change type. Presents diffs at your preferred detail level."
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[target-id] [--from <ref>] [--to <ref>] [--since <time>] [--path <pattern>] [--type <added|modified|deleted|renamed>]"
---

<purpose>
Show changes between snapshots for a tracked target. Runs git diff commands on the tracking branch inside the target directory. Filters by path pattern and change type. Presents results according to `preferences.default_diff_output` (summary/detailed/full) unless overridden.
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
    - **--from**: Starting ref (sha, HEAD~N, or tag). Default: HEAD~1
    - **--to**: Ending ref. Default: HEAD
    - **--since**: Time-based range (e.g., "1 week ago", "2026-02-28"). Converts to git log range.
    - **--path**: Glob pattern to filter files (e.g., "plugins/*", "*.json")
    - **--type**: Filter by change type: added, modified, deleted, renamed
    - **--output**: Override diff output level: summary, detailed, full

    <action>Look up target in targets.json. If not found, list available targets and stop.</action>
  </step>

  <step id="resolve-refs" number="3">
    <description>Resolve Refs</description>

    <if condition="--since provided">
      <action>Find the appropriate from-ref using git log on the tracking branch:</action>
      <command language="bash" tool="Bash">git -C "<target-path>" log "<git-branch>" --format="%H" --since="<since>" --reverse 2>/dev/null | head -1</command>
      <action>Use the first commit after the since date as --from. Use HEAD as --to.</action>
    </if>

    <action>Ensure the target repo is on the correct branch:</action>
    <command language="bash" tool="Bash">git -C "<target-path>" checkout "<git-branch>" -q 2>/dev/null</command>
  </step>

  <step id="get-diff" number="4">
    <description>Get Diff</description>

    <action>Determine the output level from `--output` flag or `preferences.default_diff_output`.</action>

    <if condition="output == summary">
      <command language="bash" tool="Bash">git -C "<target-path>" diff --stat "<from>".."<to>" 2>/dev/null</command>
      <action>Also run `git -C "<target-path>" diff --name-status "<from>".."<to>"` to get change types.</action>
    </if>

    <if condition="output == detailed">
      <command language="bash" tool="Bash">git -C "<target-path>" diff --name-status "<from>".."<to>" 2>/dev/null</command>
      <action>Group changes by type (added/modified/deleted/renamed) and show file paths.</action>
    </if>

    <if condition="output == full">
      <action>Run full diff, but limit output to avoid overwhelming the display:</action>
      <command language="bash" tool="Bash">git -C "<target-path>" diff "<from>".."<to>" 2>/dev/null | head -500</command>
    </if>
  </step>

  <step id="filter-results" number="5">
    <description>Filter Results</description>

    <if condition="--path provided">
      <action>Filter the results to only show files matching the path pattern.</action>
    </if>

    <if condition="--type provided">
      <action>Filter to only show changes of the specified type (A=added, M=modified, D=deleted, R=renamed).</action>
    </if>
  </step>

  <step id="present-results" number="6">
    <description>Present Results</description>

    <action>Present the filtered diff results with clear formatting:</action>

    <if condition="no changes">
      <action>Report "No changes between <from> and <to>."</action>
    </if>

    <if condition="changes found">
      <completion-message>
      Changes in `<display-name>` (<from-short>..<to-short>):

      <formatted diff output based on output level>

      Summary: <N> files changed (<added> added, <modified> modified, <deleted> deleted)
      </completion-message>
    </if>
  </step>

</steps>
