---
name: setup-wdyk
description: "Configure what-do-you-know plugin: register with heres-the-thing, set learning preferences, seed personas, and initialize learning session tracking"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Configure the plugin to use your i-did-a-thing arsenal for knowledge reinforcement, concept quizzing, gap analysis, and personalized learning plans. Seeds shared personas and company profiles.
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
      <read path="<home>/.things/shared/professional-profile.json" output="profile" />
      <action>Check if `<home>/.things/what-do-you-know/preferences.json` exists.</action>
      <if condition="preferences-exist">
        <action>Show current settings and ask if they want to reconfigure.</action>
      </if>
      <if condition="preferences-missing">
        <action>Fresh setup (continue to Step 2).</action>
      </if>
      <if condition="reconfiguring">
        <action>Show current settings as defaults throughout.</action>
      </if>
    </load-config>
  </step>

  <step id="verify-arsenal" number="2">
    <description>Verify Arsenal</description>
    <action>Show the user their professional profile.</action>

    <template name="profile-summary">
      <output>
      Found your shared config. Your arsenal will power your learning sessions.

      - Current role: `<current_role>`
      - Target roles: `<target_roles>`
      - Building skills: `<building_skills>`
      - Aspirational skills: `<aspirational_skills>`
      </output>
    </template>

    <validate name="arsenal-exists">
      <action>Check if `<home>/.things/i-did-a-thing/arsenal/` has any files.</action>
    </validate>

    <if condition="no-arsenal-entries">
      <output>
      No arsenal entries yet. Run `/thing-i-did` to start building evidence. You can still use what-do-you-know, but sessions will be richer with logged entries.
      </output>
    </if>
  </step>

  <step id="gather-learning-preferences" number="3">
    <description>Gather Learning Preferences</description>
    <ask-user-question>
      <question>What depth level for learning sessions by default?</question>
      <option>`exploratory` -- broad topic overview, identify what you know and don't (Recommended)</option>
      <option>`focused` -- targeted deep-dive into specific concepts</option>
      <option>`deep` -- intensive probing with detailed technical questions</option>
    </ask-user-question>

    <ask-user-question>
      <question>Default session length?</question>
      <option>`short` -- ~15 minutes, quick knowledge check</option>
      <option>`medium` -- ~30 minutes, balanced exploration (Recommended)</option>
      <option>`deep` -- ~60 minutes, comprehensive deep-dive</option>
    </ask-user-question>

    <ask-user-question>
      <question>Default persona for learning sessions?</question>
      <option>Staff Engineer -- technical depth, architecture, tradeoffs (Recommended)</option>
      <option>Engineering Manager -- collaboration, communication, growth</option>
      <option>Principal Engineer -- system thinking, organizational impact</option>
      <option>Bar Raiser -- cross-functional depth, judgment</option>
    </ask-user-question>

    <ask-user-question>
      <question>Any specific focus areas?</question>
      <option-with-text-input>Comma-separated topics, or leave empty to follow your building_skills + aspirational_skills from profile</option-with-text-input>
    </ask-user-question>
  </step>

  <step id="create-directories" number="4">
    <description>Create Plugin Directories</description>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-do-you-know/sessions</command>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-do-you-know/study-plans</command>
  </step>

  <step id="seed-personas" number="5">
    <description>Seed Shared Resources</description>
    <substep name="seed-personas">
      <action>Seed shared personas to `<home>/.things/shared/roles/` if not already present.</action>
      <command language="bash" tool="Bash">
for f in <plugin_root>/personas/*.md; do
  dest="<home>/.things/shared/roles/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
      </command>
    </substep>

    <substep name="seed-companies">
      <action>Seed company profiles to `<home>/.things/shared/companies/` if not already present.</action>
      <command language="bash" tool="Bash">
for f in <plugin_root>/companies/*.yaml; do
  dest="<home>/.things/shared/companies/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
      </command>
    </substep>

    <action>Tell the user how many personas and companies were seeded (or "all already present").</action>
  </step>

  <step id="create-progress-file" number="6">
    <description>Create Progress File</description>
    <write path="<home>/.things/what-do-you-know/progress.json">

      <schema name="progress-file">
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_sessions": 0,
        "last_session": null,
        "dimensions": {
          "depth": { "average": null, "trend": "stable" },
          "accuracy": { "average": null, "trend": "stable" },
          "connections": { "average": null, "trend": "stable" },
          "application": { "average": null, "trend": "stable" },
          "articulation": { "average": null, "trend": "stable" }
        },
        "strongest_topics": [],
        "weakest_topics": [],
        "sessions": []
      }
      ```
      </schema>

    </write>
  </step>

  <step id="create-knowledge-map" number="7">
    <description>Create Knowledge Map</description>
    <write path="<home>/.things/what-do-you-know/knowledge-map.json">

      <schema name="knowledge-map-file">
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "strong": [],
        "building": [],
        "gap": [],
        "blind_spot": []
      }
      ```
      </schema>

      <schema name="knowledge-map-entry">
      Each entry in the arrays should follow this structure when populated:

      ```json
      {
        "topic": "<topic name>",
        "concepts": ["<concept>"],
        "last_session": "<date>",
        "notes": "<brief description>"
      }
      ```
      </schema>

    </write>
  </step>

  <step id="write-preferences" number="8">
    <description>Write Preferences</description>
    <write path="<home>/.things/what-do-you-know/preferences.json">

      <schema name="preferences-file">
      ```json
      {
        "default_depth": "<exploratory|focused|deep>",
        "default_persona": "<persona>",
        "session_length": "<short|medium|deep>",
        "focus_areas": ["<area>"]
      }
      ```
      </schema>

    </write>
  </step>

  <step id="register-collections" number="9">
    <description>Register Collections</description>
    <action>Read `<home>/.things/registry.json` and add (skip if already registered):</action>

    <schema name="sessions-collection">
    what-do-you-know/sessions:
    ```json
    {
      "plugin": "what-do-you-know",
      "description": "Learning exploration and quiz session logs",
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

    <schema name="study-plans-collection">
    what-do-you-know/study-plans:
    ```json
    {
      "plugin": "what-do-you-know",
      "description": "Personalized learning plans bridging from existing knowledge to gap topics",
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

    <action>Write the updated `registry.json`.</action>
  </step>

  <step id="update-environment-tracking" number="10">
    <description>Update Environment Tracking</description>
    <substep name="read-config">
      <read path="<home>/.things/config.json" output="config" />
    </substep>
    <substep name="get-hostname">
      <command language="bash" output="hostname" tool="Bash">hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown"</command>
    </substep>
    <substep name="update-environment">
      <action>Update the `environments.<hostname>.plugins` array to include `"what-do-you-know"` if not already present. Update `last_active`. Write back `config.json`.</action>
    </substep>
  </step>

  <step id="handle-git-workflow" number="11">
    <description>Handle Git Workflow</description>
    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>
      <if condition="workflow-auto">
        <action>Commit and push.</action>
      </if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Would you like to commit and push the setup files?</question>
          <option>Yes</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user what was created.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm-setup" number="12">
    <description>Confirm Setup</description>
    <completion-message>
      <template name="setup-confirmation">
        <output>
        Your what-do-you-know setup is complete!

        - Sessions: `<home>/.things/what-do-you-know/sessions/`
        - Default depth: `<depth>`
        - Session length: `<length>`
        - Default persona: `<persona>`
        - Focus areas: `<areas or "following building_skills + aspirational_skills">`

        Quick start:
        - `/explore` -- Deep-dive into a topic from your experience
        - `/quiz` -- Test your knowledge with concept questions
        - `/gaps` -- Analyze knowledge gaps across your skill areas
        - `/bridge` -- Build a learning plan for a specific gap
        </output>
      </template>
    </completion-message>
  </step>

</steps>
