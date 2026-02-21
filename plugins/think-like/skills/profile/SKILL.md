---
name: profile
description: "Apply an expert thinking profile to code - run a code review, architecture evaluation, security audit, or debugging session through the lens of DHH, Sandi Metz, or any installed profile. Use when user says 'think like X', 'review as X', 'profile X code-review'."
disable-model-invocation: false
allowed-tools: Read, Write, Bash, Glob, Grep, LSP, AskUserQuestion
argument-hint: "<profile-id> <action> [target path or description]"
---

<purpose>
Load an expert thinking profile's action file and follow it directly. Action files are self-contained -- they include voice, approach, priorities, and output format. No subagent is needed.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>
    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <read path="<home>/.things/config.json" output="config" />
      <read path="<home>/.things/think-like/profiles/master-index.json" output="master-index" />
      <read path="<home>/.things/think-like/preferences.json" output="preferences" />
      <if condition="any-missing">Tell the user to run `/setup-tl`.</if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>
    <action>Parse `$ARGUMENTS` for profile ID, action, and optional target.</action>

    <if condition="no-profile-id">
      <action>Check `preferences.json` for `default_profile`. If set, use it.</action>
      <if condition="no-default-profile">
        <action>List available profiles from `master-index.json`.</action>
        <ask-user-question>
          <question>Which profile would you like to use?</question>
          <option-with-text-input>Enter profile ID or name:</option-with-text-input>
        </ask-user-question>
      </if>
    </if>

    <if condition="no-action">
      <action>Look up the profile's available actions from `master-index.json`.</action>
      <if condition="only-one-action">
        <action>Use it.</action>
      </if>
      <if condition="multiple-actions">
        <ask-user-question>
          <question>Which action would you like to run?</question>
          <option-with-text-input>Enter action name:</option-with-text-input>
        </ask-user-question>
      </if>
    </if>

    <if condition="no-target">
      <ask-user-question>
        <question>What should I review? Provide a file path, directory, or describe what to look at.</question>
      </ask-user-question>
    </if>
  </step>

  <step id="resolve-profile" number="3">
    <description>Resolve Profile</description>

    <phase name="find-profile" number="1">
      <action>Find the profile in `master-index.json` by ID.</action>
      <if condition="not-found">
        <action>Search by partial match or display name.</action>
        <if condition="still-not-found">
          <action>Tell the user: "Profile '<id>' not found. Run `/manage-profiles list` to see available profiles."</action>
          <exit />
        </if>
      </if>
    </phase>

    <phase name="verify-action" number="2">
      <action>Verify the requested action exists for this profile by checking the profile's actions in `master-index.json`.</action>
      <if condition="action-not-found">
        <action>Tell the user: "Profile '<name>' doesn't have a '<action>' action. Available: <list>. Run `/manage-profiles edit <id>` to add one."</action>
        <exit />
      </if>
    </phase>
  </step>

  <step id="load-and-follow-action" number="4">
    <description>Load and Follow Action File</description>
    <read path="<home>/.things/think-like/profiles/<id>/<action>.md" output="action-file" />

    <action>This file IS the complete instruction set. It contains:</action>
    <output-format>
    - Voice: How to communicate (tone, phrases, rhetorical patterns)
    - Approach: The 4-phase execution structure
    - Lens: How this person approaches this activity
    - Priorities: What to check, in order
    - Typical Questions: Questions to ask in their voice
    - Red Flags: Patterns to flag
    - Approval Signals: Patterns to praise
    - Output Format: How to structure findings
    - Counterpoint: Mandatory blind spots to surface
    </output-format>

    <constraint>Follow the action file as your instructions. Apply it to the target. Execute all 4 phases. Phase 4 (Counterpoint) is mandatory -- never skip it.</constraint>
  </step>

  <step id="session-logging" number="5">
    <description>Session Logging</description>
    <if condition="preferences.session_logging == true">
      <write path="<home>/.things/think-like/sessions/<date>-<profile>-<action>.md">
        <action>Write the full output from step 4 to the session file. The action file's Output Format section defines the structure — use whatever was actually produced. Prepend frontmatter and append the footer, but the body is the complete action output as-delivered in the conversation.</action>

        <template name="session-log-wrapper">
        ```markdown
        ---
        profile: "<id>"
        action: "<action>"
        target: "<target description>"
        date: <YYYY-MM-DD>
        ---

        <full action output from step 4 — preserve all structure, tables, code blocks, and formatting exactly as delivered>
        ```
        </template>

        <constraint>The action output IS the session log body. Do not summarize, compress, or restructure it. Different actions produce different output formats — a security audit looks nothing like a code review. Write what was produced, not a generic summary.</constraint>

        <fallback>If for any reason the action output is unavailable, fall back to this minimal format:</fallback>
        <template name="session-log-fallback">
        ```markdown
        ## Target
        <what was reviewed>

        ## Summary
        <2-3 sentence summary of key findings>

        ## Key Findings
        <bulleted list of findings>
        ```
        </template>
      </write>
    </if>
  </step>

  <step id="update-last-used" number="6">
    <description>Update Last Used</description>
    <read path="<home>/.things/think-like/profiles/<id>/index.json" output="profile-index" />
    <action>Update `last_used` to current date.</action>
    <write path="<home>/.things/think-like/profiles/<id>/index.json" content="updated-profile-index" />
  </step>

  <step id="confirm" number="7">
    <description>Confirm</description>
    <completion-message>
      <action>After the review output, add:</action>
      <output>
      ---
      Profile: <name> | Action: <action> | Session logged: <yes/no>

      `/profile <id> <action>` to run again | `/manage-profiles list` to see all profiles
      </output>
    </completion-message>
  </step>

</steps>
