---
name: manage-profiles
description: "List, edit, delete, export, or compare installed thinking profiles. Use when user says 'list profiles', 'delete profile', 'manage profiles', 'compare profiles'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<list|edit|delete|export|compare> [profile-id] [--tag <tag>]"
---

<purpose>
List, edit, delete, export, or compare installed thinking profiles.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>
    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <read path="<home>/.things/think-like/profiles/master-index.json" output="master-index" />
      <if condition="master-index-missing">Tell the user to run `/setup-tl`.</if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>
    <action>Parse `$ARGUMENTS` for subcommand: `list`, `edit`, `delete`, `export`, or `compare`.</action>
    <if condition="arguments-contain --tag">
      <action>Extract the tag value after `--tag`. Store as `filter-tag` for use in the `list` subcommand.</action>
    </if>
    <if condition="no-argument">
      <ask-user-question>
        <question>What would you like to do?</question>
        <option>List -- see all installed profiles</option>
        <option>Edit -- modify a profile's contexts or metadata</option>
        <option>Delete -- remove a profile</option>
        <option>Export -- export a profile for sharing</option>
      </ask-user-question>
    </if>
  </step>

  <step id="execute-subcommand" number="3">
    <description>Execute Subcommand</description>

    <if condition="subcommand == 'list'">
      <action>Read `master-index.json`. For each profile, show:</action>
      <if condition="filter-tag-set">
        <action>Only show profiles whose tags array includes `filter-tag`. If no profiles match, tell the user: "No profiles match tag '<filter-tag>'."</action>
      </if>
      <output-format>
        <for-each item="profile" source="master-index.profiles (filtered by tag if set)">
          <output>
            <name>Profile display name (<id>)</name>
            <actions>action1, action2</actions>
            <tags>tag1, tag2</tags>
            <last-used>Date or "never"</last-used>
            <speculative>yes/no</speculative>
          </output>
        </for-each>
      </output-format>
      <if condition="no-profiles-installed">
        <action>Tell the user: "No profiles installed. Run `/create-profile` to build one or `/browse-profiles` to install starters."</action>
      </if>
      <hint>You can also search across all plugins with `/things:search --tag <tag>`.</hint>
    </if>

    <if condition="subcommand == 'edit'">
      <action>Parse profile ID from arguments. If not provided, list profiles and ask which to edit.</action>
      <ask-user-question>
        <question>What would you like to edit?</question>
        <option>Add an action -- add a new action file (code-review, architecture, etc.)</option>
        <option>Edit metadata -- change tags, display name</option>
        <option>Regenerate -- re-research and rebuild the profile</option>
      </ask-user-question>

      <if condition="add-action">
        <phase name="add-action" number="1">
          <action>Ask which action type.</action>
          <read path="<home>/.things/shared/contexts/<action-type>.md" output="context-template" />
          <read path="<home>/.things/shared/people/<id>/profile.md" output="person-profile" />
          <action>Launch the appropriate builder agent (Task tool) from `<plugin_root>/agents/builders/<action-type>.md`.</action>
          <action>Builder produces action file at `<home>/.things/think-like/profiles/<id>/<action>.md`.</action>
          <action>Update profile `index.json` and `master-index.json`.</action>
        </phase>
      </if>

      <if condition="edit-metadata">
        <phase name="edit-metadata" number="2">
          <action>Read the profile's `index.json`, let the user modify fields, write back.</action>
          <action>Update `master-index.json`.</action>
        </phase>
      </if>

      <if condition="regenerate">
        <phase name="regenerate" number="3">
          <action>Essentially re-runs `/create-profile` for the existing ID with fresh research. Confirm with user first -- this overwrites existing files.</action>
        </phase>
      </if>
    </if>

    <if condition="subcommand == 'delete'">
      <action>Parse profile ID from arguments. If not provided, list profiles and ask which to delete.</action>
      <ask-user-question>
        <question>Delete profile <name>? This removes the think-like action files but keeps the shared person profile (other plugins may reference it).</question>
        <option>Delete think-like profile only (Recommended)</option>
        <option>Delete profile AND shared person files</option>
        <option>Cancel</option>
      </ask-user-question>

      <if condition="deleting">
        <action>Remove `<home>/.things/think-like/profiles/<id>/` directory.</action>
        <action>Remove entry from `master-index.json`, update counts.</action>
        <if condition="also-deleting-person">
          <action>Remove `<home>/.things/shared/people/<id>/` and update `shared/people/master-index.json`.</action>
        </if>
      </if>
    </if>

    <if condition="subcommand == 'export'">
      <action>Parse profile ID from arguments. If not provided, list and ask.</action>
      <action>Create a self-contained export at `<home>/.things/think-like/exports/<id>/`:</action>
      <action>Copy person files from `shared/people/<id>/`.</action>
      <action>Copy action files from `think-like/profiles/<id>/`.</action>
      <write path="<home>/.things/think-like/exports/<id>/manifest.json" content="listing of all included files" />
      <completion-message>
        <output>Profile exported to `<home>/.things/think-like/exports/<id>/`. Share this directory to let others install the profile.</output>
      </completion-message>
    </if>

    <if condition="subcommand == 'compare'">
      <action>Ask for two profile IDs (or parse from arguments).</action>
      <for-each item="profile" source="two-selected-profiles">
        <read path="<home>/.things/shared/people/<id>/profile.md" output="person-profile" />
      </for-each>
      <action>Display a side-by-side comparison:</action>
      <output-format>
      | Aspect | <Name A> | <Name B> |
      |--------|----------|----------|
      | Domain | ... | ... |
      | Core philosophy | ... | ... |
      | Communication style | ... | ... |
      | Available actions | ... | ... |
      </output-format>
      <action>Highlight where they'd disagree -- overlapping actions with different priorities or opposing red flags.</action>
    </if>
  </step>

  <step id="git-workflow" number="4">
    <description>Git Workflow</description>
    <git-workflow>
      <action>For `edit` and `delete` operations, read `<home>/.things/config.json` for `git.workflow` setting.</action>
      <if condition="workflow == 'auto'">
        <action>Commit changes, push.</action>
      </if>
      <if condition="workflow == 'ask'">
        <ask-user-question>
          <question>Would you like to commit and push these changes?</question>
          <option>Yes</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow == 'manual'">
        <action>Skip.</action>
      </if>
    </git-workflow>
  </step>

</steps>
