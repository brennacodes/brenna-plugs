---
name: setup-idat
description: "Configure i-did-a-thing plugin: register collections, create directories, set logging preferences. Requires things to be set up first."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Configure accomplishment logging within the `.things/` directory managed by things. Creates per-plugin directories, registers collections, seeds shared resources, and sets logging preferences.
</purpose>

<steps>

  <step id="check-prerequisites" number="1">
    <description>Check Prerequisites</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first to initialize your .things directory." Then stop.<exit /></if>

      <read path="<home>/.things/registry.json" output="registry" />

      <action>Check if preferences already exist.</action>
      <read path="<home>/.things/i-did-a-thing/preferences.json" output="preferences" />
      <if condition="preferences-exist">Show current settings and ask if they want to reconfigure.</if>
      <if condition="preferences-missing">Fresh setup (continue to Step 2).</if>

      <if condition="reconfiguring">Show current settings as defaults throughout.</if>
    </load-config>
  </step>

  <step id="create-plugin-directories" number="2">
    <description>Create Plugin Directories</description>

    <command language="bash" tool="Bash">mkdir -p <home>/.things/i-did-a-thing/logs
mkdir -p <home>/.things/i-did-a-thing/arsenal
mkdir -p <home>/.things/i-did-a-thing/resumes</command>
  </step>

  <step id="register-collections" number="3">
    <description>Register Collections</description>

    <action>Read `<home>/.things/registry.json` and add these collections (skip any already registered).</action>

    <schema name="logs-collection">
    i-did-a-thing/logs:
    ```json
    {
      "plugin": "i-did-a-thing",
      "description": "Professional experience log entries",
      "item_structure": {
        "directory_per_item": false,
        "file_pattern": "*.md"
      },
      "index_schema": {
        "required_fields": {
          "title": "string",
          "date": "date",
          "evidence_type": "string",
          "impact": "string",
          "category": "string"
        },
        "optional_fields": {
          "tags": "string[]",
          "skills_used": "string[]"
        }
      },
      "master_index": "i-did-a-thing/index.json",
      "rebuild_command": "python3 ${PLUGIN_ROOT}/scripts/rebuild-data.py ${THINGS_PATH}"
    }
    ```
    </schema>

    <constraint>
    `${PLUGIN_ROOT}` in `rebuild_command` must be replaced with the actual absolute path to the i-did-a-thing plugin root at registration time. Detect it via:
    <command language="bash" tool="Bash">echo "${CLAUDE_PLUGIN_ROOT}"</command>
    </constraint>

    <schema name="arsenal-collection">
    i-did-a-thing/arsenal:
    ```json
    {
      "plugin": "i-did-a-thing",
      "description": "Auto-generated skill summary files",
      "item_structure": {
        "directory_per_item": false,
        "file_pattern": "*.md"
      },
      "index_schema": {},
      "master_index": null,
      "rebuild_command": null
    }
    ```
    </schema>

    <schema name="resumes-collection">
    i-did-a-thing/resumes:
    ```json
    {
      "plugin": "i-did-a-thing",
      "description": "Generated resume files",
      "item_structure": {
        "directory_per_item": false,
        "file_pattern": "*.md"
      },
      "index_schema": {},
      "master_index": null,
      "rebuild_command": null
    }
    ```
    </schema>

    <write path="<home>/.things/registry.json" content="updated registry with new collections" />
  </step>

  <step id="create-index-files" number="4">
    <description>Create Initial Index Files</description>

    <if condition="index-missing">
      <write path="<home>/.things/i-did-a-thing/index.json">
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_entries": 0,
        "entries": []
      }
      ```
      </write>
    </if>

    <if condition="tags-missing">
      <write path="<home>/.things/i-did-a-thing/tags.json">
      ```json
      {
        "last_updated": "<current_date>",
        "tags": {}
      }
      ```
      </write>
    </if>
  </step>

  <step id="gather-preferences" number="5">
    <description>Gather Preferences</description>

    <ask-user-question>
      <question>Default tags for your logs? (comma-separated, e.g., `engineering, python, leadership`)</question>
      <option-with-text-input>Enter tags</option-with-text-input>
    </ask-user-question>
  </step>

  <step id="write-preferences" number="6">
    <description>Write Preferences</description>

    <write path="<home>/.things/i-did-a-thing/preferences.json">
    ```json
    {
      "default_tags": ["<tag1>", "<tag2>"]
    }
    ```
    </write>
  </step>

  <step id="seed-shared-resources" number="7">
    <description>Seed Shared Resources</description>

    <action>Seed persona files to `<home>/.things/shared/roles/` if not already present. The bundled personas are at `<plugin_root>/personas/`.</action>
    <command language="bash" tool="Bash">for f in <plugin_root>/personas/*.md; do
  dest="<home>/.things/shared/roles/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done</command>

    <action>Seed company profiles to `<home>/.things/shared/companies/` if not already present.</action>
    <command language="bash" tool="Bash">for f in <plugin_root>/companies/*.yaml; do
  dest="<home>/.things/shared/companies/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done</command>
  </step>

  <step id="update-environment" number="8">
    <description>Update Environment Tracking</description>

    <action>Read `<home>/.things/config.json` and get hostname.</action>
    <command language="bash" output="hostname" tool="Bash">hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown"</command>

    <action>Update the `environments.<hostname>.plugins` array to include `"i-did-a-thing"` if not already present. Update `last_active` to today's date. Write back `config.json`.</action>
  </step>

  <step id="handle-git" number="9">
    <description>Handle Git</description>

    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>

      <if condition="workflow-auto">
        <command language="bash" tool="Bash">git -C <home>/.things add -A && git -C <home>/.things commit -m "setup: i-did-a-thing" && git -C <home>/.things push</command>
      </if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit setup files to .things repo?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only -- commit without pushing</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user what files were created.</if>
    </git-workflow>
  </step>

  <step id="confirm-setup" number="10">
    <description>Confirm Setup</description>

    <completion-message>
    i-did-a-thing is ready!

    - Logs: `<home>/.things/i-did-a-thing/logs/`
    - Arsenal: `<home>/.things/i-did-a-thing/arsenal/`
    - Resumes: `<home>/.things/i-did-a-thing/resumes/`
    - Collections registered in registry.json

    Quick start:
    - `/thing-i-did` -- Log something you did
    - `/construct-resume` -- Build a resume for a job listing
    </completion-message>
  </step>

</steps>
