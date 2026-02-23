---
name: browse-profiles
description: "Browse all thinking profiles on the system. Use when user says 'browse profiles', 'show profiles', 'what profiles are available'."
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
argument-hint: "[install <id>] [--tag <tag>]"
---

<references>
  <reference name="starter-catalog" path="references/starter-catalog.md" />
  <reference name="person-profile" path="references/person-profile.md" />
  <reference name="master-index" path="$HOME/.things/think-like/profiles/master-index.json" />
</references>

<purpose>
Browse all thinking profiles on the user's system - including user-created profiles and installed starters. Optionally install bundled starters that haven't been installed yet.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>
    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <action>Use this <home> path for all file operations below.</action>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <action>Read the master index file.</action>
      <read path="<home>/.things/think-like/profiles/master-index.json" output="master-index" />
      <if condition="master-index-missing">
        <ask-user-question>
          <question>It looks like you haven't set up `think-like` yet. Would you like to run `/setup-tl` now?</question>
          <option>Yes</option>
          <option>No</option>
        </ask-user-question>
        <if condition="yes">
          <invoke-skill plugin="think-like" skill="setup-tl" />
        </if>
        <if condition="no"><exit /></if>
      </if>
    </load-config>
  </step>

  <step id="load-profiles" number="2">
    <description>Load All Profile Metadata</description>
    <for-each item="profile" source="master-index.profiles">
      <read path="<home>/.things/think-like/profiles/<id>/index.json" output="profile-metadata" />
    </for-each>
  </step>

  <step id="load-starter-catalog" number="3">
    <description>Load Starter Catalog</description>
    <action>Read the starter catalog to identify any bundled starters not yet installed.</action>
    <read path="<plugin_root>/skills/browse-profiles/references/starter-catalog.md" output="starter-catalog" />
    <action>Determine which starters are not present in master-index.</action>
  </step>

  <step id="parse-arguments" number="4">
    <description>Parse Arguments</description>
    <if condition="arguments-contain-install-id">
      <action>Skip to step 7 (install-starter).</action>
    </if>
    <if condition="arguments-contain --tag">
      <action>Extract the tag value after `--tag`. Store as `filter-tag` for use in step 5.</action>
    </if>
  </step>

  <step id="display-profiles" number="5">
    <description>Display All Profiles</description>
    <action>Show a numbered list of profiles on the system.</action>
    <if condition="filter-tag-set">
      <action>Only show profiles whose tags array includes `filter-tag`. If no profiles match, tell the user: "No profiles match tag '<filter-tag>'."</action>
    </if>

    <output-format>
      <section heading="Your Profiles">
        <for-each item="profile" source="master-index.profiles (filtered by tag if set)">
          <output>
            <name>Profile display name</name>
            <id>Profile ID</id>
            <description>Short description from profile metadata</description>
            <available-actions>List of action names (e.g., code-review, debug)</available-actions>
            <tags>Tags from profile metadata</tags>
            <last-used>Last used date, or "never"</last-used>
          </output>
        </for-each>
      </section>

      <if condition="uninstalled-starters-exist">
        <section heading="Available to Install">
          <for-each item="uninstalled-starter" source="starter-catalog (minus already-installed, filtered by tag if set)">
            <output>
              <name>Starter display name</name>
              <id>Starter ID</id>
              <description>Short description from starter catalog</description>
              <available-actions>List of action names</available-actions>
              <tags>Tags from starter catalog</tags>
            </output>
          </for-each>
        </section>
      </if>

      <hint>You can also search across all plugins with `/things:search --tag <tag>`.</hint>
    </output-format>
  </step>

  <step id="prompt-user" number="6">
    <description>Prompt User</description>
    <ask-user-question>
      <question>What would you like to do?</question>
      <option>View profile details</option>
      <option>Install a starter</option>
      <option>Just browsing</option>
    </ask-user-question>

    <if condition="view-profile-details">
      <ask-user-question>
        <question>Which profile would you like to view?</question>
        <option-with-text-input>Enter profile ID or number:</option-with-text-input>
      </ask-user-question>
      <action>Read the profile's person file and display identity, philosophy, and available actions.</action>
      <read path="<home>/.things/shared/people/<id>/profile.md" output="person-profile" />
      <if condition="profile-is-uninstalled-starter">
        <action>Fall back to reading from the plugin's starters directory.</action>
        <read path="<plugin_root>/starters/<id>/person/profile.md" output="person-profile" />
      </if>
      <action>Display the identity, philosophy, and available actions.</action>
    </if>

    <if condition="install-a-starter">
      <ask-user-question>
        <question>Which starter would you like to install?</question>
        <option-with-text-input>Enter starter ID or number:</option-with-text-input>
      </ask-user-question>
      <action>Continue to step 7 with selected starter.</action>
    </if>

    <if condition="just-browsing">
      <action>Done. Remind user they can use `/profile <id> <action>` to use a profile.</action>
      <exit />
    </if>
  </step>

  <step id="install-starter" number="7">
    <description>Install Starter Profile</description>
    <for-each item="starter-to-install">

      <substep name="check-existing">
        <description>Check if already installed.</description>
        <if condition="already-installed">
          <ask-user-question>
            <question><name> is already installed. What would you like to do?</question>
            <option>Overwrite with starter version</option>
            <option>Skip this one</option>
            <option>Cancel</option>
          </ask-user-question>
          <if condition="skip"><action>Skip to next starter.</action></if>
          <if condition="cancel"><exit /></if>
        </if>
      </substep>

      <substep name="create-directories">
        <description>Create directories if needed.</description>
        <command language="bash" tool="Bash">mkdir -p <home>/.things/shared/people/<id></command>
        <command language="bash" tool="Bash">mkdir -p <home>/.things/think-like/profiles/<id></command>
      </substep>

      <substep name="copy-person-files">
        <description>Copy person files to shared/people.</description>
        <read path="<plugin_root>/starters/<id>/person/profile.md" output="person-profile-content" />
        <write path="<home>/.things/shared/people/<id>/profile.md" content="person-profile-content" />
        <read path="<plugin_root>/starters/<id>/person/index.json" output="person-index-content" />
        <write path="<home>/.things/shared/people/<id>/index.json" content="person-index-content" />
      </substep>

      <substep name="copy-action-files">
        <description>Copy action files to profiles directory.</description>
        <action>Copy all `.md` files from `<plugin_root>/starters/<id>/contexts/` to `<home>/.things/think-like/profiles/<id>/`.</action>
        <for-each item="action-file" source="starters/<id>/contexts/*.md">
          <read path="<plugin_root>/starters/<id>/contexts/<action-file>" output="action-content" />
          <write path="<home>/.things/think-like/profiles/<id>/<action-file>" content="action-content" />
        </for-each>
      </substep>

      <substep name="generate-profile-index">
        <description>Generate profile index.json.</description>
        <action>Read the person's `index.json` for metadata. List the action files that were copied.</action>
        <write path="<home>/.things/think-like/profiles/<id>/index.json">
          <schema name="profile-index">
          ```json
          {
            "id": "<id>",
            "display_name": "<name from person index>",
            "person_ref": "shared/people/<id>",
            "actions": [
              {"name": "<action>", "file": "<action>.md", "description": "<from action frontmatter>"}
            ],
            "tags": ["<from person index>"],
            "created": "<current_date>",
            "last_used": null
          }
          ```
          </schema>
        </write>
      </substep>

      <substep name="update-master-index">
        <description>Update master index.</description>
        <action>Add profile entry to master-index.</action>
        <action>Increment `total_profiles`.</action>
        <action>Update `last_updated`.</action>
        <write path="<home>/.things/think-like/profiles/master-index.json" content="updated-master-index" />
      </substep>

      <substep name="update-people-index">
        <description>Update shared/people master index.</description>
        <read path="<home>/.things/shared/people/master-index.json" output="people-index" />
        <if condition="people-index-exists">
          <action>Add person entry to existing index.</action>
        </if>
        <if condition="people-index-missing">
          <action>Create new people master index with this person entry.</action>
        </if>
        <write path="<home>/.things/shared/people/master-index.json" content="updated-people-index" />
      </substep>

    </for-each>
  </step>

  <step id="git-workflow" number="8">
    <description>Git Workflow</description>
    <git-workflow>
      <read path="<home>/.things/config.json" output="config" />
      <action>Check `config.git.auto_commit` setting.</action>
      <if condition="git-setting == 'auto'">
        <action>Commit and push changes.</action>
      </if>
      <if condition="git-setting == 'ask'">
        <ask-user-question>
          <question>Would you like to commit and push these changes?</question>
          <option>Yes</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="git-setting == 'manual'">
        <action>Skip git operations.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm" number="9">
    <description>Confirm</description>
    <completion-message>
      <output>
      Installed <n> profile(s): <names>

      Use `/profile <id> <action>` to try one out.
      </output>
    </completion-message>
  </step>

</steps>
