---
name: setup-wdyd
description: "Configure what-did-you-do plugin: register with things, set interview preferences, and initialize session tracking"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Configure the plugin to use your i-did-a-thing arsenal for interview preparation, practice sessions, and company-specific mock interviews. Seeds shared personas and company profiles.
</purpose>

<steps>

  <step id="check-prerequisites" number="1">
    <description>Check Prerequisites</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first to initialize your .things directory." Then stop.</if>

      <read path="<home>/.things/shared/professional-profile.json" output="profile" />

      <action>Check if `<home>/.things/what-did-you-do/preferences.json` exists.</action>
      <if condition="preferences-exist">Show current settings and ask if they want to reconfigure.</if>
      <if condition="preferences-missing">Fresh setup (continue to Step 2).</if>

      <if condition="reconfiguring">
        <constraint>Show current settings as defaults throughout.</constraint>
      </if>
    </load-config>
  </step>

  <step id="verify-arsenal" number="2">
    <description>Verify Arsenal</description>

    <validate>
      <action>Show the user their professional profile.</action>

      <output>
      > Found your shared config. Your arsenal will power your interview feedback.
      >
      > - Current role: `<current_role>`
      > - Target roles: `<target_roles>`
      > - Building skills: `<building_skills>`
      </output>

      <action>Check if `<home>/.things/i-did-a-thing/arsenal/` has any files.</action>

      <if condition="no-arsenal-files">

      > No arsenal entries yet. Run `/thing-i-did` to start building evidence. You can still use what-did-you-do, but feedback will be richer with logged entries.

      </if>
    </validate>
  </step>

  <step id="gather-preferences" number="3">
    <description>Gather Interview Preferences</description>

    <ask-user>
    How detailed should follow-up questions be during practice?

    <options>
    - `concise` -- no follow-ups, keep it moving
    - `detailed` -- first-level follow-ups to test depth
    - `coaching` -- deep follow-ups with probing questions and action items
    </options>
    </ask-user>

    <ask-user>
    Default interview stage to practice?

    <options>
    - `phone-screen` -- 30-min behavioral/culture fit
    - `technical` -- coding and system design
    - `onsite` -- full-day multi-round simulation
    - `bar-raiser` -- cross-functional deep dive
    - `no-default` -- ask me each time
    </options>
    </ask-user>
  </step>

  <step id="gather-trusted-sources" number="4">
    <description>Gather Trusted Sources for Question Updates</description>

    <ask-user>
    Do you want to enable question bank updates from external sources?

    <options>
    - Yes -- I'll provide trusted domains
    - No -- only use the built-in question bank
    </options>
    </ask-user>

    <if condition="enable-external-sources">
      <ask-user>
      Trusted domains for question sources (comma-separated, e.g., `leetcode.com, teamblind.com, levels.fyi`)
      </ask-user>

      <ask-user>
      Trusted URLs (specific pages, comma-separated -- optional)
      </ask-user>
    </if>
  </step>

  <step id="create-dirs" number="5">
    <description>Create Plugin Directories</description>

    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-did-you-do/sessions</command>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-did-you-do/questions</command>
  </step>

  <step id="seed-resources" number="6">
    <description>Seed Shared Resources</description>

    <action>Seed shared personas to `<home>/.things/shared/roles/` if not already present.</action>
    <command language="bash" tool="Bash">
for f in <plugin_root>/personas/*.md; do
  dest="<home>/.things/shared/roles/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
    </command>

    <action>Seed company profiles to `<home>/.things/shared/companies/` if not already present.</action>
    <command language="bash" tool="Bash">
for f in <plugin_root>/companies/*.yaml; do
  dest="<home>/.things/shared/companies/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
    </command>

    <action>Tell the user how many personas and companies were seeded.</action>
  </step>

  <step id="create-progress" number="7">
    <description>Create Progress File</description>

    <write path="<home>/.things/what-did-you-do/progress.json">
      <schema name="progress-file">
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_sessions": 0,
        "last_session": null,
        "dimensions": {
          "specificity": { "average": null, "trend": "stable" },
          "structure": { "average": null, "trend": "stable" },
          "impact": { "average": null, "trend": "stable" },
          "relevance": { "average": null, "trend": "stable" },
          "self_advocacy": { "average": null, "trend": "stable" }
        },
        "strongest_categories": [],
        "weakest_categories": [],
        "sessions": []
      }
      ```
      </schema>
    </write>
  </step>

  <step id="create-custom-questions" number="8">
    <description>Create Custom Questions Starter</description>

    <write path="<home>/.things/what-did-you-do/questions/custom.yaml">
      <schema name="custom-questions-template">
      ```yaml
      # Custom interview questions
      # Add your own questions here following the schema:
      #
      # - id: custom-001
      #   text: "Your question here"
      #   category: behavioral
      #   subcategory: custom
      #   skills_tested: [skill-1, skill-2]
      #   level: [mid, senior]
      #   stages: [phone-screen, onsite]
      #   interviewer_types: [engineering-manager]
      #   follow_ups:
      #     - text: "Follow-up question"
      #       depth: 2
      #   difficulty: 3
      #   expected_format: narrative
      #   time_budget_minutes: 5
      #   red_flags: ["vague answer"]
      #   green_flags: ["specific metrics"]

      questions: []
      ```
      </schema>
    </write>
  </step>

  <step id="write-preferences" number="9">
    <description>Write Preferences</description>

    <write path="<home>/.things/what-did-you-do/preferences.json">
      <schema name="preferences">
      ```json
      {
        "follow_up_depth": "<concise|detailed|coaching>",
        "default_stage": "<stage or no-default>",
        "trusted_sources": {
          "domains": ["<domain>"],
          "urls": ["<url>"]
        }
      }
      ```
      </schema>
    </write>
  </step>

  <step id="register-collections" number="10">
    <description>Register Collections</description>

    <read path="<home>/.things/registry.json" output="registry" />
    <action>Add the following collection (skip if already registered).</action>

    <schema name="collection-entry">
    what-did-you-do/sessions:

    ```json
    {
      "plugin": "what-did-you-do",
      "description": "Interview practice and mock session logs",
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

  <step id="update-environment" number="11">
    <description>Update Environment Tracking</description>

    <read path="<home>/.things/config.json" output="config" />
    <command language="bash" output="hostname" tool="Bash">hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown"</command>

    <action>Update the `environments.<hostname>.plugins` array to include `"what-did-you-do"` if not already present. Update `last_active`. Write back `config.json`.</action>
  </step>

  <step id="git-workflow" number="12">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>

      <if condition="workflow-auto">
        <action>Commit and push.</action>
      </if>
      <if condition="workflow-ask">
        <ask-user>Ask the user whether to commit and push.</ask-user>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user what was created.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm-setup" number="13">
    <description>Confirm Setup</description>

    <completion-message>

    > Your what-did-you-do setup is complete!
    >
    > - Sessions: `<home>/.things/what-did-you-do/sessions/`
    > - Follow-up depth: `<depth>`
    > - Default stage: `<stage>`
    > - Trusted sources: `<count or "built-in only">`
    >
    > Quick start:
    > - `/practice-wdyd` -- Drill a single question with coached feedback
    > - `/mock-wdyd` -- Simulate a full interview round
    > - `/prep-for-wdyd` -- Prepare for a specific company
    > - `/review-wdyd` -- Check your readiness across dimensions

    </completion-message>
  </step>

</steps>
