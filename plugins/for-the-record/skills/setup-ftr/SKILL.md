---
name: setup-ftr
description: "Initialize for-the-record in .things/ - creates docs directory, registers collection, writes preferences. Required before /add-doc-ftr can store documents."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Initialize the `for-the-record` plugin within `~/.things/`. Creates the docs directory, registers the collection in the registry, writes preferences, and sets up empty index files.
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
        <read path="<home>/.things/for-the-record/preferences.json" output="existing-prefs" />
        <action>Show current settings as defaults throughout.</action>
      </if>
    </load-config>
  </step>

  <step id="create-directories" number="2">
    <description>Create Plugin Directories</description>

    ```bash
    mkdir -p <home>/.things/for-the-record/docs
    mkdir -p <home>/.things/for-the-record/discussions
    ```
  </step>

  <step id="gather-preferences" number="3">
    <description>Gather Preferences</description>

    <ask-user-question>
      <question>What level of detail should documents capture by default?</question>
      <option label="Concise (Recommended)">Key points, decisions, and outcomes — compact and scannable</option>
      <option label="Detailed">Full reasoning chains, code blocks, all alternatives discussed — maximum context preservation</option>
    </ask-user-question>

    <ask-user-question>
      <question>Should documents auto-generate tags from content?</question>
      <option label="Yes (Recommended)">Automatically suggest tags from technologies, keywords, and existing tag vocabulary</option>
      <option label="No">I'll add tags manually each time</option>
    </ask-user-question>

    <ask-user-question>
      <question>Should verbatim discussions be automatically pruned after a number of days?</question>
      <option label="No retention limit (Recommended)">Keep all discussions indefinitely</option>
      <option label="30 days">Auto-prune discussions older than 30 days</option>
      <option label="90 days">Auto-prune discussions older than 90 days</option>
      <option-with-text-input>Custom number of days</option-with-text-input>
    </ask-user-question>
  </step>

  <step id="write-preferences" number="4">
    <description>Write Preferences</description>

    <write path="<home>/.things/for-the-record/preferences.json">

    ```json
    {
      "default_detail_level": "<concise|detailed>",
      "auto_tag": <true|false>,
      "discussion_retention_days": <number or null>
    }
    ```

    </write>
  </step>

  <step id="write-index-files" number="5">
    <description>Write Empty Index Files</description>

    <if condition="index.json missing">
    <write path="<home>/.things/for-the-record/index.json">

    ```json
    {
      "version": 1,
      "last_updated": "<current_date>",
      "total_items": 0,
      "items": []
    }
    ```

    </write>
    </if>

    <if condition="tags.json missing">
    <write path="<home>/.things/for-the-record/tags.json">

    ```json
    {
      "last_updated": "<current_date>",
      "tags": {}
    }
    ```

    </write>
    </if>
  </step>

  <step id="register-collection" number="6">
    <description>Register Collection in Registry</description>

    <read path="<home>/.things/registry.json" output="registry" />

    <action>Add (or update) the `for-the-record/docs` and `for-the-record/discussions` collection entries.</action>

    <action>Determine the absolute path to the rebuild script. Read the plugin's cached install path from `~/.claude/plugins/installed_plugins.json` for the `for-the-record` plugin. The rebuild_command must use this absolute cached path.</action>

    <constraint>If the cached path cannot be determined, use a placeholder comment instructing the user to update after install: `"python3 <UPDATE-WITH-CACHED-PATH>/scripts/rebuild-index.py ${THINGS_PATH}"`</constraint>

    <schema name="collection-entry">

    ```json
    {
      "for-the-record/docs": {
        "plugin": "for-the-record",
        "description": "Structured documentation captured from conversations and context",
        "tags_field": "frontmatter.tags",
        "item_structure": {
          "directory_per_item": false,
          "file_pattern": "*.md"
        },
        "index_schema": {
          "required_fields": {
            "filename": "string",
            "title": "string",
            "date": "date",
            "tags": "string[]"
          },
          "optional_fields": {
            "description": "string",
            "detail_level": "string",
            "source_type": "string"
          }
        },
        "master_index": "for-the-record/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```

    </schema>

    <schema name="discussions-collection">

    ```json
    {
      "for-the-record/discussions": {
        "plugin": "for-the-record",
        "description": "Verbatim conversation captures preserved without summarization",
        "tags_field": "frontmatter.tags",
        "item_structure": {
          "directory_per_item": false,
          "file_pattern": "*.md"
        },
        "index_schema": {
          "required_fields": {
            "filename": "string",
            "title": "string",
            "date": "date",
            "tags": "string[]"
          },
          "optional_fields": {
            "description": "string",
            "source_type": "string"
          }
        },
        "master_index": "for-the-record/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```

    </schema>

    <action>Merge both into `registry.json`'s `collections` object and write the file.</action>
  </step>

  <step id="update-environment" number="7">
    <description>Update Environment Tracking</description>

    <action>Read `config.json`, find the current hostname's environment entry, and add `"for-the-record"` to its `plugins` array if not already present. Write back.</action>
  </step>

  <step id="git-workflow" number="8">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "setup: for-the-record"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the for-the-record setup?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the setup is complete and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="9">
    <description>Confirm Setup</description>

    <completion-message>
    for-the-record is ready!

    - Docs directory: `<home>/.things/for-the-record/docs/`
    - Discussions directory: `<home>/.things/for-the-record/discussions/`
    - Detail level: `<default_detail_level>`
    - Auto-tagging: `<auto_tag>`
    - Discussion retention: `<discussion_retention_days or "unlimited">`
    - Collections registered: `for-the-record/docs`, `for-the-record/discussions`

    Start capturing:
    - `/add-doc-ftr <topic>` -- Capture a document from conversation context
    - `/add-doc-ftr <topic> --detailed` -- Capture with maximum detail
    - `/capture-discussion` -- Capture a verbatim discussion (no summarization)
    - `/import-ftr <path>` -- Import existing documentation files from any directory
    </completion-message>
  </step>

</steps>
