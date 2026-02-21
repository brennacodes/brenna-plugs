---
name: create-profile
description: "Build a new expert thinking profile - research a person or archetype, synthesize their technical philosophy, and generate self-contained action files. Use when user says 'create a profile', 'add a profile', 'build a profile for X'."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task
argument-hint: "<name or archetype> [reference URLs...]"
---

<references>
  <reference name="profile-builder-guide" path="references/profile-builder-guide.md" />
  <reference name="builder-agents" path="$CLAUDE_PLUGIN_ROOT/agents/builders/" />
  <reference name="shared-context-templates" path="$HOME/.things/shared/contexts/" />
</references>

<purpose>
Build a new expert thinking profile by researching a person or archetype and synthesizing their technical philosophy into structured profile and action files.
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
      <if condition="either-missing">Tell the user to run `/setup-tl`.</if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>
    <action>Parse `$ARGUMENTS` for subject (a person name or archetype) and optional reference URLs.</action>
    <if condition="no-arguments-provided">
      <ask-user-question>
        <question>Who should this profile model? This can be a real person (e.g., Kent Beck) or an archetype (e.g., performance-obsessed SRE).</question>
      </ask-user-question>
    </if>
  </step>

  <step id="check-duplicates" number="3">
    <description>Check for Duplicates</description>
    <action>Generate an ID from the subject name: lowercase, hyphens for spaces, alphanumeric only (e.g., "Kent Beck" -> `kent-beck`).</action>
    <action>Check if `<home>/.things/shared/people/<id>/` already exists.</action>
    <if condition="profile-already-exists">
      <ask-user-question>
        <question>A profile for this person already exists. What would you like to do?</question>
        <option>Update existing profile with new research</option>
        <option>Create anyway with a different ID</option>
        <option>Cancel</option>
      </ask-user-question>
    </if>
  </step>

  <step id="gather-references" number="4">
    <description>Gather References</description>
    <if condition="urls-or-github-info-in-arguments">
      <action>Note them for the research phase.</action>
    </if>
    <if condition="no-references-provided">
      <ask-user-question>
        <question>How should I research this person's technical thinking?</question>
        <option>Mine their GitHub PR comments -- I'll provide username and repos</option>
        <option>I have reference links (blogs, talks, repos)</option>
        <option>Just use web search</option>
        <option>I'll describe their philosophy myself</option>
      </ask-user-question>

      <if condition="user-selects-mine-github-pr-comments">
        <action>Ask for their GitHub username and which repos to analyze (comma-separated `owner/repo`). The profile-builder will use `gh api` to fetch their review comments and extract patterns, priorities, and voice. This produces the highest-signal profiles for code review actions.</action>
      </if>
      <if condition="user-selects-reference-links">
        <action>Accept URLs to blogs, conference talks, GitHub repos, articles.</action>
      </if>
      <if condition="user-selects-describe-philosophy">
        <action>Accept freeform text describing the person's philosophy, style, and stances.</action>
      </if>
    </if>
  </step>

  <step id="determine-actions" number="5">
    <description>Determine Actions</description>
    <ask-user-question>
      <question>Which actions should this profile cover?</question>
      <option>Code review -- line-by-line code evaluation</option>
      <option>PR review -- holistic pull request assessment (approach, scope, risk)</option>
      <option>Architecture -- system design and structure evaluation</option>
      <option>Security audit -- security-focused code and design review</option>
      <option>Code smell -- pattern and anti-pattern detection</option>
      <option>Debug -- hypothesis-driven debugging and root cause analysis</option>
    </ask-user-question>
  </step>

  <step id="set-expectations" number="6">
    <description>Set Expectations</description>
    <action>Before launching the build, let the user know this may take a while.</action>
    <output>
    Heads up — building a profile for the first time can take up to 10 minutes depending on the number of actions and source material. I'll be researching, synthesizing, and generating self-contained action files for each action you selected. Sit tight.
    </output>
  </step>

  <step id="research-and-build" number="7">
    <description>Research and Build</description>
    <action>Launch the profile-builder agent (Task tool, subagent_type: general-purpose) with the following prompt.</action>

    <template name="profile-builder-prompt">
    You are the profile-builder agent for think-like. Your job is to:
    1. Research the person/archetype
    2. Create person profile at `<home>/.things/shared/people/<id>/`
    3. For EACH requested action, read the appropriate shared context template from `<home>/.things/shared/contexts/<action-type>.md` and invoke the appropriate builder agent to produce self-contained action files at `<home>/.things/think-like/profiles/<id>/<action>.md`

    Subject: <subject name>
    ID: <generated id>
    GitHub username: <username or "none">
    GitHub repos to mine: <owner/repo list or "none">
    Reference URLs: <urls or "none">
    User-provided context: <context or "none">
    Requested actions: <list of actions>

    <output-files>
    - Person profile: `<home>/.things/shared/people/<id>/profile.md`
    - Person index: `<home>/.things/shared/people/<id>/index.json`
    - Action files: `<home>/.things/think-like/profiles/<id>/<action>.md` (one per requested action)
    - Profile index: `<home>/.things/think-like/profiles/<id>/index.json`
    </output-files>

    Builder agent references: `<plugin_root>/agents/builders/` -- read the appropriate builder for each action type
    Shared context templates: `<home>/.things/shared/contexts/` -- read template for each action
    File format guide: `<plugin_root>/skills/create-profile/references/profile-builder-guide.md`

    Use WebSearch and WebFetch to research. Write all output files when complete.
    </template>

    <constraint>Where `<plugin_root>` is resolved via `${CLAUDE_PLUGIN_ROOT}` or the plugin's installed path.</constraint>
  </step>

  <step id="update-indexes" number="8">
    <description>Update Indexes</description>
    <action>After the agent completes, update both master indexes.</action>

    <substep name="update-people-index">
      <description>Update shared/people master index.</description>
      <read path="<home>/.things/shared/people/master-index.json" output="people-index" />
      <action>Add entry:</action>
      <schema name="people-entry">
      ```json
      {
        "id": "<id>",
        "display_name": "<name>",
        "type": "person",
        "created": "<current_date>",
        "referenced_by": ["think-like"]
      }
      ```
      </schema>
      <action>Increment `total_people`, update `last_updated`.</action>
      <write path="<home>/.things/shared/people/master-index.json" content="updated-people-index" />
    </substep>

    <substep name="update-profiles-index">
      <description>Update think-like profiles master index.</description>
      <read path="<home>/.things/think-like/profiles/master-index.json" output="profiles-index" />
      <action>Add entry:</action>
      <schema name="profile-entry">
      ```json
      {
        "id": "<id>",
        "display_name": "<name>",
        "person_ref": "shared/people/<id>",
        "actions": ["<action1>", "<action2>"],
        "tags": ["<from profile index.json>"],
        "created": "<current_date>"
      }
      ```
      </schema>
      <action>Increment `total_profiles`, update `last_updated`.</action>
      <write path="<home>/.things/think-like/profiles/master-index.json" content="updated-profiles-index" />
    </substep>
  </step>

  <step id="git-workflow" number="9">
    <description>Git Workflow</description>
    <git-workflow>
      <read path="<home>/.things/config.json" output="config" />
      <action>Check `config.git.workflow` setting.</action>
      <if condition="workflow == 'auto'">
        <action>Stage new files, commit with message `think-like: add profile for <name>`, push.</action>
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

  <step id="confirm" number="10">
    <description>Confirm</description>
    <completion-message>
      <output>
      Profile created for <name>!

      - Person: `shared/people/<id>/`
      - Actions: <list of action files>
      - Speculative: <yes/no>

      Use `/profile <id> <action>` to apply this profile.
      </output>
    </completion-message>
  </step>

</steps>
