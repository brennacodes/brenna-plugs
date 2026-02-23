---
name: profile
description: "Apply an expert thinking profile to code - run a code review, architecture evaluation, security audit, or debugging session through the lens of DHH, Sandi Metz, or any installed profile. Use when user says 'think like X', 'review as X', 'profile X code-review'."
disable-model-invocation: false
allowed-tools: Read, Write, Bash, Glob, Grep, LSP, AskUserQuestion, Task
argument-hint: "<profile-id> <action> [target path or description]"
---

<purpose>
Load an expert thinking profile's action file and follow it directly. Action files are self-contained -- they include voice, approach, priorities, and output format. Single targets execute directly. Multiple targets launch parallel agents.
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

  <step id="detect-execution-mode" number="3">
    <description>Detect Execution Mode</description>
    <action>Determine whether to run in direct mode (single target) or parallel mode (multiple targets).</action>

    <parallel-triggers>
      <trigger>Multiple explicit targets (e.g., "plugins/a and plugins/b")</trigger>
      <trigger>User says "in parallel", "all at once", "simultaneously"</trigger>
      <trigger>User says "all plugins", "every plugin", "each plugin"</trigger>
      <trigger>Comma-separated paths or glob patterns expanding to multiple directories</trigger>
    </parallel-triggers>

    <direct-triggers>
      <trigger>Single target path or description (this is the default)</trigger>
      <trigger>No parallelism keywords</trigger>
      <trigger>User says "just this one", "only"</trigger>
    </direct-triggers>

    <action>If parallel mode detected, resolve all targets now:</action>
    <resolution-rules>
      <rule>"all plugins" → list directories under `plugins/` in the working directory (or ask the user to confirm the base path)</rule>
      <rule>Comma-separated → split into individual target paths</rule>
      <rule>Glob pattern → expand to matching directories</rule>
    </resolution-rules>

    <if condition="parallel and targets > 10">
      <ask-user-question>
        <question>That's {count} targets. Running all in parallel will use significant context. Run all at once, or batch into groups of 5?</question>
        <option label="All at once">Launch all targets in parallel</option>
        <option label="Batch (groups of 5)">Run 5 at a time, then the next 5</option>
      </ask-user-question>
    </if>
  </step>

  <step id="resolve-profile" number="4">
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

  <step id="load-and-execute" number="5">
    <description>Load and Execute Action File</description>
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

    <branch on="execution-mode">

      <direct-mode>
        <description>Single target — execute directly (default, unchanged behavior)</description>
        <constraint>Follow the action file as your instructions. Apply it to the target. Execute all 4 phases. Phase 4 (Counterpoint) is mandatory -- never skip it.</constraint>
      </direct-mode>

      <parallel-mode>
        <description>Multiple targets — launch parallel action-runner agents</description>

        <phase name="launch" number="1">
          <action>For each target, launch a Task with:</action>
          <task-config>
            <subagent_type>think-like:action-runner</subagent_type>
            <prompt>
              You are executing a think-like action file against a specific target.

              **Target**: <target path>
              **Target Label**: <short label, e.g., plugin name or directory name>

              ## Action File

              <full content of the action file, pasted verbatim>

              ## Instructions

              Follow the action file above as your complete instruction set. Apply it to the target path. Execute all 4 phases. Phase 4 (Counterpoint) is mandatory. Begin your output with `## <target label>`.
            </prompt>
          </task-config>
          <constraint>Launch ALL tasks in a single message before waiting for any results. This is critical for parallel execution — do not launch one, wait, then launch the next.</constraint>
        </phase>

        <phase name="collect" number="2">
          <action>Collect results from all agents.</action>
        </phase>

        <phase name="synthesize" number="3">
          <action>Present a combined report:</action>
          <output-structure>
            1. **Per-target sections**: Include each agent's full output under its target label header
            2. **Cross-Target Synthesis**: Add a final section that identifies:
               - Patterns that appear across multiple targets
               - Targets with the most/fewest issues
               - Systemic concerns vs. isolated findings
               - Priority ordering across all targets
          </output-structure>
        </phase>

        <fallback>
          <condition>If the action-runner agent is not available (agent type not found)</condition>
          <action>Fall back to sequential direct execution. Warn the user: "Parallel agent not available — running sequentially. This will take longer." Then execute the action file directly against each target one at a time, collecting results.</action>
        </fallback>
      </parallel-mode>

    </branch>
  </step>

  <step id="session-logging" number="6">
    <description>Session Logging</description>
    <if condition="preferences.session_logging == true">

      <branch on="execution-mode">

        <direct-mode>
          <write path="<home>/.things/think-like/sessions/<date>-<profile>-<action>.md">
            <action>Write the full output from step 5 to the session file. The action file's Output Format section defines the structure — use whatever was actually produced. Prepend frontmatter and append the footer, but the body is the complete action output as-delivered in the conversation.</action>

            <template name="session-log-wrapper">
            ```markdown
            ---
            profile: "<id>"
            action: "<action>"
            target: "<target description>"
            date: <YYYY-MM-DD>
            ---

            <full action output from step 5 — preserve all structure, tables, code blocks, and formatting exactly as delivered>
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
        </direct-mode>

        <parallel-mode>
          <write path="<home>/.things/think-like/sessions/<date>-<profile>-<action>-batch.md">
            <action>Write a single batch session log containing all parallel results plus the cross-target synthesis.</action>

            <template name="batch-session-log">
            ```markdown
            ---
            profile: "<id>"
            action: "<action>"
            mode: "parallel"
            targets:
              - "<target 1>"
              - "<target 2>"
              - "..."
            date: <YYYY-MM-DD>
            ---

            <per-target results followed by cross-target synthesis — preserve all structure exactly as delivered>
            ```
            </template>
          </write>
        </parallel-mode>

      </branch>

    </if>
  </step>

  <step id="update-last-used" number="7">
    <description>Update Last Used</description>
    <read path="<home>/.things/think-like/profiles/<id>/index.json" output="profile-index" />
    <action>Update `last_used` to current date.</action>
    <write path="<home>/.things/think-like/profiles/<id>/index.json" content="updated-profile-index" />
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>
    <completion-message>
      <action>After the review output, add:</action>
      <output>
      ---
      Profile: <name> | Action: <action> | Mode: <direct/parallel> | Targets: <count> | Session logged: <yes/no>

      `/profile <id> <action>` to run again | `/manage-profiles list` to see all profiles
      </output>
    </completion-message>
  </step>

</steps>
