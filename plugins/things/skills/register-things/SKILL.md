---
name: register-things
description: "Register, update, or remove collection definitions in the .things/ registry. Used by plugins during setup or for manual registry management."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<add|update|remove> <collection-path> [json-definition]"
---

<purpose>
Manage collection definitions in `.things/registry.json`. Primarily used by other plugins during their setup, but can be invoked directly for manual registry management.

See `references/collection-schema.md` for the full collection definition schema.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/registry.json`

    <if condition="registry-missing">Tell the user to run `/things:setup-things` first.</if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    Parse `$ARGUMENTS` for:
    - Subcommand: `add`, `update`, or `remove`
    - Collection path: e.g., `think-like/profiles`, `i-did-a-thing/logs`
    - JSON definition (optional): If provided inline as a JSON blob (starts with `{`), use it directly instead of asking interactive questions

    <if condition="no-arguments">
    <ask-user>
    Ask via AskUserQuestion:
    <options>
    - What would you like to do? (Add a collection / Update an existing collection / Remove a collection)
    </options>
    </ask-user>
    </if>
  </step>

  <step id="execute-subcommand" number="3">
    <description>Execute Subcommand</description>

    <step name="add-with-json">
    Subcommand: `add <collection-path> [json-definition]`

    <if condition="json-definition-provided">

    <validate>
    Validate the JSON against the collection schema (see `references/collection-schema.md`). Required fields: `plugin`, `description`, `item_structure`, `index_schema`, `master_index`, `rebuild_command`.
    </validate>

    <check name="no-duplicate">Check that the collection path doesn't already exist in the registry.</check>
    <if condition="collection-already-exists">
    <ask-user>Ask the user whether to overwrite.</ask-user>
    </if>

    Write the collection definition to registry.json.
    </if>
    </step>

    <step name="add-interactive">
    <if condition="no-json-definition">

    <ask-user>
    Use AskUserQuestion to gather:

    1. Plugin name -- Which plugin owns this collection?
    2. Description -- What does this collection store?
    3. Item structure -- Directory per item, or flat files?
       <if condition="directory-per-item">Required files, optional file patterns, index file name.</if>
       <if condition="flat-files">File pattern (e.g., `*.md`).</if>
    4. Index schema -- Required fields (name and type), optional fields
    5. Master index path -- Path to the master index file (relative to `.things/`), or none
    6. Rebuild command -- Shell command to run after writes, or none
    </ask-user>

    Write the collection definition to registry.json.
    </if>
    </step>

    <step name="add-post-actions">
    After adding, create the collection directory if it doesn't exist:

    ```bash
    mkdir -p <home>/.things/<collection-path>
    ```

    <if condition="master-index-specified-and-missing">Create an empty one:

    <schema name="empty-master-index">

    ```json
    {
      "version": 1,
      "last_updated": "<current_date>",
      "total_items": 0,
      "items": []
    }
    ```

    </schema>
    </if>
    </step>

    <step name="update-collection">
    Subcommand: `update <collection-path>`

    Read the existing collection definition. Present current values.

    <ask-user>Ask what to change via AskUserQuestion.</ask-user>

    Write updated definition back to registry.json.
    </step>

    <step name="remove-collection">
    Subcommand: `remove <collection-path>`

    <ask-user>
    Confirm with the user: "This will remove the collection definition from the registry. Data on disk will NOT be deleted. Continue?"
    </ask-user>

    Remove the collection from registry.json. Write the updated file.
    </step>
  </step>

  <step id="confirm" number="4">
    <description>Confirm</description>

    <completion-message>
    Show the updated registry state:
    - Collection path
    - Action taken (added/updated/removed)
    - Current total collection count
    </completion-message>
  </step>

</steps>
