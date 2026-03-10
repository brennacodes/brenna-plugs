---
name: validate-things
description: "Validate .things/ integrity - git health, registry consistency, collection structure, and orphan detection. Use when user says 'validate things', 'check things health', 'are my things okay'."
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[--collection <name>] [--fix]"
---

<purpose>
Check the structural integrity of `.things/` data against the collection registry. Reports issues without understanding domain semantics -- shape, not meaning.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
    2. Read `<home>/.things/registry.json`
    3. Read `<home>/.things/local.json` (if it exists -- validate it's valid JSON)

    <if condition="config-or-registry-missing">Report it as an error and stop.</if>
    </load-config>
  </step>

  <step id="git-health" number="2">
    <description>Git Health Check</description>

    ```bash
    git -C <home>/.things status --short 2>/dev/null
    git -C <home>/.things remote -v 2>/dev/null
    ```

    <check name="is-git-repo">Is `.things/` a git repository?</check>
    <check name="uncommitted-changes">Any uncommitted changes?</check>
    <check name="remote-reachable">Is the remote reachable? (only if configured)</check>
    <check name="no-merge-conflicts">Any merge conflicts?</check>

    <rule>Report as: `git healthy` or `uncommitted changes` / `merge conflict detected`.</rule>
  </step>

  <step id="registry-integrity" number="3">
    <description>Registry Integrity</description>

    <check name="valid-json">Is `registry.json` valid JSON?</check>
    <check name="has-version">Does it have a `version` field?</check>
    <check name="has-collections">Does it have a `collections` object?</check>
    <check name="valid-definitions">Are all collection definitions structurally valid? (required fields present, valid types)</check>
  </step>

  <step id="config-validation" number="4">
    <description>Config Validation</description>

    <check name="config-valid">Is `config.json` valid JSON with required fields (`version`, `github_username`, `git`)?</check>
    <check name="local-valid">If `local.json` exists, is it valid JSON?</check>
    <check name="profile-exists">Does `shared/professional-profile.json` exist and contain required fields?</check>
    <check name="environments-present">Does `config.json` have an `environments` object?</check>
  </step>

  <step id="collection-validation" number="5">
    <description>Per-Collection Structural Validation</description>

    <if condition="collection-flag-specified">Validate only that collection.</if>
    <if condition="no-collection-flag">Validate all.</if>

    For each registered collection:

    <check name="directory-exists">
    Check that `<home>/.things/<collection-path>/` exists. Report: `directory missing` if not.
    </check>

    <if condition="directory-per-item">
    <phase name="check-required-files" number="1">
    - List all subdirectories in the collection path
    - For each subdirectory, check that all `required_files` exist
    - Report: `<item>: missing <file>` for each missing required file
    </phase>
    </if>

    <if condition="flat-files">
    <phase name="check-file-pattern" number="1">
    - Check that at least one file matches `file_pattern`
    - Report: info only (empty collection is valid)
    </phase>
    </if>

    <if condition="master-index-set">
    Master index validation:

    <validation>
    <check name="master-index-exists">Does the file exist?</check>
    <check name="master-index-valid-json">Is it valid JSON?</check>
    <check name="master-index-fields">For each entry, do `required_fields` from `index_schema` exist and have the correct type?</check>
    <rule>Report: `master index: entry '<id>' missing field '<field>'`</rule>
    </validation>
    </if>

    <if condition="index-file-set">
    Index file validation (per item):

    <validation>
    <check name="item-index-exists">Does each item's index file exist?</check>
    <check name="item-index-valid-json">Is it valid JSON?</check>
    <check name="item-index-fields">Do required fields exist?</check>
    </validation>
    </if>
  </step>

  <step id="orphan-detection" number="6">
    <description>Orphan Detection</description>

    <phase name="list-directories" number="1">
    List all directories in `<home>/.things/` (one level deep).
    </phase>

    <phase name="exclude-known" number="2">
    Exclude known directories: `.git/`, `shared/`.
    </phase>

    <phase name="check-registry" number="3">
    Check each against the registry -- any directory whose name doesn't prefix-match a registered collection path is orphaned.
    </phase>

    <rule>Report: `orphaned directory: <name>/ (not in registry)`</rule>
  </step>

  <step id="frontmatter-checks" number="7">
    <description>Frontmatter Spot-Checks</description>

    For collections with `.md` files:

    <phase name="read-headers" number="1">
    Read the first 5 lines of each `.md` file.
    </phase>

    <phase name="check-markers" number="2">
    Check that frontmatter markers (`---`) are present.
    </phase>

    <guardrail name="no-content-validation">Do NOT validate frontmatter content (that's domain-specific).</guardrail>

    <rule>Report: `<file>: no frontmatter detected`</rule>
  </step>

  <step id="report" number="8">
    <description>Report</description>

    <template name="report-healthy">

    ```
    .things validation:

      Git: healthy (clean, remote connected)

      Registry: valid (6 collections registered)

      Config: valid (config.json, local.json, professional-profile.json)

      Collections:
        shared/people (2 items)
        shared/roles (5 items)
        shared/companies (3 items)
        think-like/profiles (3 items)

      Issues: none found
    ```

    </template>

    <template name="report-with-issues">

    ```
      Issues:
        ERROR think-like/profiles/linus-torvalds: missing required file 'index.json'
        WARN  orphaned directory: old-backup/ (not in registry)
        WARN  shared/people/dhh/profile.md: no frontmatter detected
    ```

    </template>
  </step>

  <step id="auto-fix" number="9">
    <description>Optional Fix (--fix)</description>

    <if condition="fix-flag">
    For each fixable issue:
    <phase name="fixable-items" number="1">
    - Missing collection directory -- create it
    - Missing master index -- create empty one
    - Missing item index.json -- create with required fields set to empty/default values
    </phase>

    <ask-user>
    Always ask before fixing: "Found <n> fixable issues. Fix them now?"
    </ask-user>

    <guardrail name="do-not-fix">
    Do NOT fix:
    - Missing content files (user needs to provide content)
    - Orphaned directories (user needs to decide what to do)
    - Invalid JSON (user needs to fix manually)
    </guardrail>
    </if>
  </step>

</steps>
