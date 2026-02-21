---
name: setup-tl
description: "Initialize think-like - verify heres-the-thing, register collections, create directory structure, and optionally install starter profiles. Use when user first uses think-like or says 'set up think-like'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Configure think-like and register its collections with heres-the-thing. Creates the `.things/think-like/` directory structure, installs shared context templates, and optionally installs starter profiles.
</purpose>

<steps>

  <step id="check-prerequisites" number="1">
    <description>Check Prerequisites</description>
    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/setup-htt` first to initialize your .things directory." Then stop.</if>
      <read path="<home>/.things/registry.json" output="registry" />
      <if condition="registry-missing">Tell the user: "Run `/setup-htt` first." Then stop.</if>
    </load-config>
  </step>

  <step id="check-existing-setup" number="2">
    <description>Check for Existing Setup</description>
    <if condition="think-like-registered-and-directory-exists">
      <action>Show current setup (profile count, preferences). Ask if they want to reconfigure or reinstall starters.</action>
    </if>
  </step>

  <step id="register-collection" number="3">
    <description>Register Collection</description>
    <action>Read current `registry.json`. Add the `think-like/profiles` collection (skip if already registered).</action>

    <schema name="think-like-collection">
    ```json
    "think-like/profiles": {
      "plugin": "think-like",
      "description": "Expert thinking profiles for code-focused activities",
      "item_structure": {
        "directory_per_item": true,
        "required_files": ["index.json"],
        "optional_file_patterns": ["*.md"],
        "index_file": "index.json"
      },
      "index_schema": {
        "required_fields": {
          "id": "string",
          "display_name": "string",
          "person_ref": "string",
          "tags": "string[]",
          "created": "date"
        },
        "optional_fields": {
          "actions": "object[]",
          "last_used": "date"
        }
      },
      "master_index": "think-like/profiles/master-index.json",
      "rebuild_command": null
    }
    ```
    </schema>

    <write path="<home>/.things/registry.json" content="updated-registry" />
  </step>

  <step id="create-directory-structure" number="4">
    <description>Create Directory Structure</description>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/think-like/profiles</command>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/think-like/sessions</command>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/shared/contexts</command>

    <action>Write the master index file.</action>
    <write path="<home>/.things/think-like/profiles/master-index.json">
      <schema name="master-index">
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_profiles": 0,
        "profiles": []
      }
      ```
      </schema>
    </write>

    <action>Write the preferences file.</action>
    <write path="<home>/.things/think-like/preferences.json">
      <schema name="preferences">
      ```json
      {
        "default_profile": null,
        "session_logging": true
      }
      ```
      </schema>
    </write>
  </step>

  <step id="install-shared-context-templates" number="5">
    <description>Install Shared Context Templates</description>
    <action>Copy templates from the plugin to the shared directory (skip if already present).</action>
    <command language="bash" tool="Bash">
for f in <plugin_root>/templates/*.md; do
  dest="<home>/.things/shared/contexts/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
    </command>
    <action>Tell the user how many templates were installed.</action>
  </step>

  <step id="offer-starter-profiles" number="6">
    <description>Offer Starter Profiles</description>
    <ask-user-question>
      <question>Would you like to install starter profiles? These include expert thinking models for well-known technical voices.

Available starters:
- DHH -- Rails creator. Convention over configuration, majestic monolith, simplicity over abstraction. Actions: code-review, architecture
- Sandi Metz -- OOP expert. Message-passing, small objects, cost of change. Actions: code-review, code-smell
- Strict Security Lead -- Paranoid-but-practical security engineering. OWASP, threat modeling, defense in depth. Actions: security-audit, code-review</question>
      <option>Install all starters (Recommended)</option>
      <option>Let me pick which ones</option>
      <option>Skip -- I'll create my own</option>
    </ask-user-question>

    <if condition="installing-starters">
      <for-each item="starter" source="selected-starters">

        <substep name="copy-person-files">
          <description>Copy person files to shared/people.</description>
          <action>Copy `starters/<id>/person/profile.md` to `<home>/.things/shared/people/<id>/profile.md`.</action>
          <action>Copy `starters/<id>/person/index.json` to `<home>/.things/shared/people/<id>/index.json`.</action>
        </substep>

        <substep name="copy-action-files">
          <description>Copy action files to profiles directory.</description>
          <action>Copy all `.md` files from `starters/<id>/contexts/` to `<home>/.things/think-like/profiles/<id>/`. These are self-contained action files (voice + structure + instructions).</action>
        </substep>

        <substep name="generate-profile-index">
          <description>Generate profile index.json.</description>
          <action>Read the person's `index.json` for metadata. List the action files that were installed.</action>
          <write path="<home>/.things/think-like/profiles/<id>/index.json" content="profile-index with person_ref pointing to shared/people/<id>" />
        </substep>

        <substep name="update-master-index">
          <description>Update master index.</description>
          <action>Read `master-index.json`, add entries for each installed profile, update counts and `last_updated`.</action>
          <write path="<home>/.things/think-like/profiles/master-index.json" content="updated-master-index" />
        </substep>

        <substep name="update-people-index">
          <description>Update shared/people master index.</description>
          <read path="<home>/.things/shared/people/master-index.json" output="people-index" />
          <action>Add entries for each installed person, update counts.</action>
          <write path="<home>/.things/shared/people/master-index.json" content="updated-people-index" />
        </substep>

      </for-each>
    </if>
  </step>

  <step id="update-environment" number="7">
    <description>Update Environment Tracking</description>
    <read path="<home>/.things/config.json" output="config" />
    <command language="bash" output="hostname" tool="Bash">hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown"</command>
    <action>Update the `environments.<hostname>.plugins` array to include `"think-like"` if not already present. Update `last_active`.</action>
    <write path="<home>/.things/config.json" content="updated-config" />
  </step>

  <step id="git-workflow" number="8">
    <description>Handle Git Workflow</description>
    <git-workflow>
      <read path="<home>/.things/config.json" output="config" />
      <action>Check `config.git.workflow` setting.</action>
      <if condition="workflow == 'auto'">
        <action>Commit and push.</action>
      </if>
      <if condition="workflow == 'ask'">
        <ask-user-question>
          <question>Would you like to commit and push these changes?</question>
          <option>Yes</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow == 'manual'">
        <action>Tell the user what was created.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm" number="9">
    <description>Confirm</description>
    <completion-message>
      <output>
      think-like is ready!

      - Profiles: <n> installed
      - Templates: <n> shared context templates
      - Location: `<home>/.things/think-like/`
      - Session logging: enabled

      Quick start:
      - `/profile <name> <action>` -- Apply a profile (e.g., `/profile dhh code-review`)
      - `/create-profile` -- Build a new expert profile
      - `/browse-profiles` -- See available starter profiles
      - `/manage-profiles list` -- List installed profiles
      </output>
    </completion-message>
  </step>

</steps>
