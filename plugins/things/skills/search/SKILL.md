---
name: search
description: "Registry-aware search across .things/ - search by collection, tag, field, full-text, or find orphaned data. Use when user says 'search things', 'find in things', 'which profiles have [tag]'."
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "<query> [--collection <name>] [--tag <tag>] [--field <field> --value <value>] [--text <query>] [--orphaned]"
---

<purpose>
Registry-aware search across all `.things/` data. Knows where to look and what shape indexes have from the collection registry.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
    2. Read `<home>/.things/registry.json`

    <if condition="config-missing">Tell the user to run `/things:setup`.</if>
    </load-config>
  </step>

  <step id="determine-search-mode" number="2">
    <description>Determine Search Mode</description>

    <step name="parse-arguments">
    Parse `$ARGUMENTS` for flags and query text.
    </step>

    <step name="scope-collection">
    Flag: `--collection <name>` -- Scope to a single collection

    <validate>Verify the collection exists in the registry.</validate>
    Scope all subsequent searching to `<home>/.things/<collection-path>/`.
    </step>

    <step name="search-by-tag">
    Flag: `--tag <tag>` -- Filter by tag

    <phase name="central-tag-index" number="1">
    Read `<home>/.things/tags/index.json` (the central tag index). Look up the tag to find which collections contain it and their counts.
    </phase>

    <phase name="index-search" number="2">
    For each collection that has matching tags (from central index or master_index):
    1. Read the master index file (if it exists)
    2. Filter entries where the `tags` array contains the specified tag
    3. Return matching entries with their collection context
    </phase>

    <phase name="fallback-scan" number="3">
    For collections without a master index, scan individual `index.json` files if the collection uses `directory_per_item`, or scan files directly if the collection declares `tags_field`.
    </phase>
    </step>

    <step name="search-by-field">
    Flag: `--field <field> --value <value>` -- Query on index fields

    Same approach as `--tag` but for arbitrary fields declared in `index_schema`:

    1. Read master indexes
    2. Filter entries where the specified field matches the value
    3. Support basic matching: exact for strings, contains for arrays
    </step>

    <step name="search-full-text">
    Flag: `--text <query>` -- Full-text search

    Use Grep to search across all `.md` files in the target scope:

    <if condition="collection-flag-specified">Scope to that collection's directory.</if>
    <if condition="no-collection-flag">Search all of `<home>/.things/` (excluding `.git/`).</if>

    Return matching file paths with surrounding context lines.
    </step>

    <step name="search-orphaned">
    Flag: `--orphaned` -- Find structural anomalies

    <phase name="find-orphan-dirs" number="1">
    List all directories in `<home>/.things/` (one level deep, excluding `.git/`, `shared/`).
    </phase>

    <phase name="check-against-registry" number="2">
    Check each against the registry -- any directory not accounted for is orphaned.
    </phase>

    <phase name="check-item-structure" number="3">
    For `directory_per_item` collections, check each item subdirectory against `required_files`.
    </phase>

    <phase name="check-index-coverage" number="4">
    Check for items present on disk but missing from master indexes.
    </phase>

    <phase name="report-findings" number="5">
    Report findings.
    </phase>
    </step>

    <step name="search-default">
    Default (no flags, just query text)

    <phase name="index-search" number="1">
    Search across all master indexes for entries where `display_name`, `id`, or `description` matches the query.
    </phase>

    <phase name="text-fallback" number="2">
    <if condition="no-index-results">Fall back to full-text grep across all `.md` files.</if>
    </phase>

    <phase name="return-results" number="3">
    Return results with collection context.
    </phase>
    </step>
  </step>

  <step id="present-results" number="3">
    <description>Present Results</description>

    <template name="index-results">
    For index-based searches, show:
    - Collection path
    - Item id / display_name
    - Matching field and value
    - File path for direct access
    </template>

    <template name="text-results">
    For text searches, show:
    - File path
    - Matching lines with context
    - Which collection the file belongs to (from registry)
    </template>

    <template name="orphan-results">
    For orphan searches, show:
    - Orphaned directories/files
    - Missing required files per item
    - Items missing from indexes
    </template>
  </step>

</steps>
