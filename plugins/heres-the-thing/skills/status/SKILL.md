---
name: status
description: "Show .things/ status - registered collections, item counts, git state, and optional tag aggregation. Use when user says 'things status', 'what do I have', 'show me my things'."
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[--tags]"
---

<purpose>
Show an overview of everything stored in `.things/`.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
    2. Read `<home>/.things/registry.json`

    <if condition="config-missing">Tell the user to run `/setup-htt`.</if>
    </load-config>
  </step>

  <step id="gather-stats" number="2">
    <description>Gather Collection Stats</description>

    For each registered collection in `registry.json`:

    <if condition="directory-per-item">
    - Count subdirectories in `<home>/.things/<collection-path>/` (exclude files, only count directories)
    - Get the most recent modification time across all files
    </if>

    <if condition="flat-files">
    - Count files matching `file_pattern` in `<home>/.things/<collection-path>/`
    - Get the most recent modification time
    </if>

    <if condition="master-index-exists">
    - Read the master index file and use its `total_items` count as a cross-check
    </if>
  </step>

  <step id="gather-git-status" number="3">
    <description>Gather Git Status</description>

    ```bash
    git -C <home>/.things status --short 2>/dev/null
    ```

    ```bash
    git -C <home>/.things log --oneline -1 2>/dev/null
    ```

    <extract>Determine: clean/dirty, last commit date, ahead/behind remote (if configured).</extract>
  </step>

  <step id="quick-validation" number="4">
    <description>Check for Validation Issues</description>

    Do a quick structural check for each collection:

    <check name="directory-exists">Does the collection directory exist?</check>
    <check name="master-index-valid">If `master_index` is specified, does the file exist and parse as valid JSON?</check>
    <check name="no-orphans">Any obvious orphaned directories (directories in `.things/` that aren't in the registry and aren't `shared/` or `.git/`)?</check>
  </step>

  <step id="tag-aggregation" number="5">
    <description>Optional Tag Aggregation (--tags)</description>

    <if condition="tags-flag">
    Scan all `*/tags.json` files across plugin directories in `.things/`:

    ```bash
    find <home>/.things -name "tags.json" -not -path "*/.git/*"
    ```

    <phase name="read-and-aggregate" number="1">
    For each tags.json found, read it and aggregate tag counts across all plugins. Sort by total count descending.
    </phase>

    <phase name="present-table" number="2">
    Present as a table: tag name, total count, plugins that use it.
    </phase>
    </if>
  </step>

  <step id="present-output" number="6">
    <description>Present Output</description>

    <template name="status-healthy">

    ```
    .things status:
      Location: <home>/.things
      Git: <clean|dirty>, <last commit info>, <remote status>

      Collections:
        shared/people          <n> items   last modified: <relative time>
        shared/roles           <n> items   last modified: <relative time>
        shared/companies       <n> items   last modified: <relative time>
        think-like/profiles    <n> items   last modified: <relative time>
        ...

      Health: all collections valid
    ```

    </template>

    <template name="status-with-issues">

    ```
      Health:
        ! think-like/profiles/linus-torvalds: missing index.json
        ! orphaned directory: old-data/ (not in registry)
    ```

    </template>
  </step>

</steps>
