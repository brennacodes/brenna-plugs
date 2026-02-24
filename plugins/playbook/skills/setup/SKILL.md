---
name: setup-pb
description: "Initialize playbook in .things/ - creates plans, workflows, and reviews directories, registers 3 collections, writes preferences. Required before any playbook skill can store data."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Initialize the `playbook` plugin within `~/.things/`. Creates directories for plans, workflows, and reviews, registers all three collections in the registry, writes preferences, and sets up empty index files.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first to initialize .things/." Then stop.<exit /></if>

      <if condition="reconfigure-argument">
        <read path="<home>/.things/playbook/preferences.json" output="existing-prefs" />
        <action>Show current settings as defaults throughout.</action>
      </if>
    </load-config>
  </step>

  <step id="create-directories" number="2">
    <description>Create Plugin Directories</description>

    ```bash
    mkdir -p <home>/.things/playbook/plans
    mkdir -p <home>/.things/playbook/workflows
    mkdir -p <home>/.things/playbook/reviews
    ```
  </step>

  <step id="gather-preferences" number="3">
    <description>Gather Preferences</description>

    <ask-user-question>
      <question>Where should working copies of workflows be written?</question>
      <option label=".claude/workflows/ (Recommended)">Standard Claude Code workflows directory in the current project</option>
      <option-with-text-input>Custom path</option-with-text-input>
    </ask-user-question>

    <ask-user-question>
      <question>When importing plans from ~/.claude/plans/, should the originals be kept or moved?</question>
      <option label="Copy (Recommended)">Keep the original in ~/.claude/plans/ and copy to playbook</option>
      <option label="Move">Move the file to playbook (deletes from ~/.claude/plans/)</option>
    </ask-user-question>

    <ask-user-question>
      <question>Do you have a default think-like profile for code reviews? (Used by /review-against as:<profile>)</question>
      <option label="None">No default -- I'll specify per review</option>
      <option-with-text-input>Set a default profile ID</option-with-text-input>
    </ask-user-question>

    <ask-user-question>
      <question>Should old plan versions be automatically prunable after a number of days?</question>
      <option label="No retention limit (Recommended)">Keep all plan versions indefinitely</option>
      <option label="30 days">Auto-prune versions older than 30 days (keeps latest per plan)</option>
      <option label="90 days">Auto-prune versions older than 90 days (keeps latest per plan)</option>
      <option-with-text-input>Custom number of days</option-with-text-input>
    </ask-user-question>
  </step>

  <step id="write-preferences" number="4">
    <description>Write Preferences</description>

    <write path="<home>/.things/playbook/preferences.json">

    ```json
    {
      "default_workflow_target": "<.claude/workflows/ or custom>",
      "plan_import_behavior": "<copy|move>",
      "default_review_profile": <null or "profile-id">,
      "plan_retention_days": <number or null>
    }
    ```

    </write>
  </step>

  <step id="write-index-files" number="5">
    <description>Write Empty Index Files</description>

    <if condition="index.json missing">
    <write path="<home>/.things/playbook/index.json">

    ```json
    {
      "version": 1,
      "last_updated": "<current_date>",
      "total_items": 0,
      "by_type": { "plan": 0, "workflow": 0, "review": 0 },
      "items": []
    }
    ```

    </write>
    </if>

    <if condition="tags.json missing">
    <write path="<home>/.things/playbook/tags.json">

    ```json
    {
      "last_updated": "<current_date>",
      "tags": {}
    }
    ```

    </write>
    </if>
  </step>

  <step id="register-collections" number="6">
    <description>Register Collections in Registry</description>

    <read path="<home>/.things/registry.json" output="registry" />

    <action>Determine the absolute path to the rebuild script. Read the plugin's cached install path from `~/.claude/plugins/installed_plugins.json` for the `playbook` plugin. The rebuild_command must use this absolute cached path.</action>

    <constraint>If the cached path cannot be determined, use a placeholder: `"python3 <UPDATE-WITH-CACHED-PATH>/scripts/rebuild-index.py ${THINGS_PATH}"`</constraint>

    <action>Add (or update) all three collection entries in `registry.json`.</action>

    <schema name="plans-collection">
    ```json
    {
      "playbook/plans": {
        "plugin": "playbook",
        "description": "Versioned plans imported from Claude sessions, tracked through implementation",
        "tags_field": "frontmatter.tags",
        "item_structure": { "directory_per_item": true, "file_pattern": "v*.md" },
        "index_schema": {
          "required_fields": { "filename": "string", "title": "string", "date": "date", "tags": "string[]", "slug": "string", "version": "number" },
          "optional_fields": { "status": "string", "source_plan": "string", "project": "string", "references": "string[]" }
        },
        "master_index": "playbook/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```
    </schema>

    <schema name="workflows-collection">
    ```json
    {
      "playbook/workflows": {
        "plugin": "playbook",
        "description": "XML-enhanced workflow documents following the bivvy pattern",
        "tags_field": "frontmatter.tags",
        "item_structure": { "directory_per_item": false, "file_pattern": "*.md" },
        "index_schema": {
          "required_fields": { "filename": "string", "title": "string", "date": "date", "tags": "string[]" },
          "optional_fields": { "scope": "string", "target_path": "string", "step_count": "number" }
        },
        "master_index": "playbook/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```
    </schema>

    <schema name="reviews-collection">
    ```json
    {
      "playbook/reviews": {
        "plugin": "playbook",
        "description": "Implementation reviews with actionable items and interview results",
        "tags_field": "frontmatter.tags",
        "item_structure": { "directory_per_item": false, "file_pattern": "*.md" },
        "index_schema": {
          "required_fields": { "filename": "string", "title": "string", "date": "date", "tags": "string[]" },
          "optional_fields": { "plan_ref": "string", "branch": "string", "status": "string", "actionable_count": "number" }
        },
        "master_index": "playbook/index.json",
        "rebuild_command": "python3 <absolute-cached-path>/scripts/rebuild-index.py ${THINGS_PATH}"
      }
    }
    ```
    </schema>

    <action>Merge all three into `registry.json`'s `collections` object and write the file.</action>
  </step>

  <step id="update-environment" number="7">
    <description>Update Environment Tracking</description>

    <action>Read `config.json`, find the current hostname's environment entry, and add `"playbook"` to its `plugins` array if not already present. Write back.</action>
  </step>

  <step id="git-workflow" number="8">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "setup: playbook"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the playbook setup?</question>
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
    playbook is ready!

    - Plans: `<home>/.things/playbook/plans/`
    - Workflows: `<home>/.things/playbook/workflows/`
    - Reviews: `<home>/.things/playbook/reviews/`
    - Plan retention: `<plan_retention_days or "unlimited">`
    - Collections registered: `playbook/plans`, `playbook/workflows`, `playbook/reviews`

    Get started:
    - `/capture-plan <thing>` -- Import a plan from ~/.claude/plans/
    - `/create-workflow <scope>` -- Create an XML-enhanced workflow
    - `/review-against <plan>` -- Review branch work against a plan
    - `/progress` -- See progress dashboard for active plans
    </completion-message>
  </step>

</steps>
