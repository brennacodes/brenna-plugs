---
name: update-questions
description: "Add new questions to the bank from trusted external sources with validation and deduplication"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
argument-hint: "<url or 'manual'>"
---

<references>
  - references/source-validation.md
</references>

<purpose>
Add new interview questions to the question bank from trusted sources or manual entry, with validation, deduplication, and proper metadata tagging.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/setup-htt` first." Then stop.</if>

      <read path="<home>/.things/shared/professional-profile.json" output="profile" />

      <read path="<home>/.things/what-did-you-do/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-wdyd` first." Then stop.</if>
    </load-config>
  </step>

  <step id="determine-source" number="2">
    <description>Determine Source</description>

    <if condition="url-provided">
      <validate>
        <action>Validate the URL against `trusted_sources.domains` and `trusted_sources.urls` using `references/source-validation.md`.</action>

        <if condition="url-untrusted">

        > That URL isn't in your trusted sources. Add it via `/setup-wdyd` or provide a trusted source.

        <exit />
        </if>

        <if condition="url-trusted">
          <action>Use WebFetch to retrieve the content.</action>
        </if>
      </validate>
    </if>

    <if condition="manual-provided">
      <action>Proceed to manual entry flow (Step 5).</action>
    </if>

    <if condition="no-argument">
      <ask-user>
      How do you want to add questions?

      <options>
      - From a URL -- I'll paste a link to interview questions
      - Manual entry -- I'll type them in
      - Browse suggestions -- show me what's new from my trusted sources
      </options>
      </ask-user>
    </if>
  </step>

  <step id="parse-content" number="3">
    <description>Parse External Content</description>

    <action>From the fetched URL content, extract potential interview questions. Look for:</action>

    - Questions in quote format or numbered lists
    - Follow-up questions
    - Category indicators (behavioral, technical, etc.)
    - Skill/topic tags
    - Difficulty indicators
  </step>

  <step id="validate-and-enrich" number="4">
    <description>Validate and Enrich Questions</description>

    <action>For each extracted question, apply the schema from `references/source-validation.md`.</action>

    <phase name="deduplication" number="1">
      <action>Check against existing questions in all `<plugin_root>/questions/*.yaml` files. Flag duplicates or near-duplicates.</action>
    </phase>

    <phase name="categorize" number="2">
      <action>Classify into behavioral, technical, system-design, leadership, or situational.</action>
    </phase>

    <phase name="generate-metadata" number="3">
      <action>Generate required fields.</action>

      <schema name="question-metadata">
      - `id`: `ext-<source-hash>-<seq>`
      - `skills_tested`: inferred from question content
      - `level`: inferred from complexity
      - `stages`: inferred from question type
      - `interviewer_types`: inferred from category
      - `difficulty`: 1-5 scale
      - `expected_format`: narrative / whiteboard / coding
      - `time_budget_minutes`: estimated
      - `red_flags` and `green_flags`: generated from question intent
      - `source`: URL or "manual"
      - `added_date`: today
      </schema>
    </phase>

    <phase name="generate-follow-ups" number="4">
      <action>For questions without follow-ups, generate depth-2 and depth-3 follow-ups.</action>
    </phase>
  </step>

  <step id="manual-entry" number="5">
    <description>Manual Entry Flow</description>

    <if condition="manual-entry">
      <ask-user>
      Question text? (free text)
      </ask-user>

      <ask-user>
      Category?

      <options>
      - behavioral
      - technical
      - system-design
      - leadership
      - situational
      </options>
      </ask-user>

      <ask-user>
      What skills does this test? (comma-separated)
      </ask-user>

      <ask-user>
      Difficulty? (1=easy, 5=very hard)
      </ask-user>

      <ask-user>
      Any follow-up questions? (free text, or skip)
      </ask-user>

      <action>Generate the remaining metadata fields automatically.</action>
    </if>
  </step>

  <step id="present-for-review" number="6">
    <description>Present for Review</description>

    <template name="question-review">

    > Questions to Add:
    >
    > 1. "<question>"
    >    Category: <cat> | Skills: <skills> | Difficulty: <n>
    >    Status: New / Duplicate of <existing-id>
    >
    > 2. "<question>"
    >    ...

    </template>

    <ask-user>
    Which questions should I add?

    <options>
    - All of them
    - Let me select which ones
    - None -- cancel
    </options>
    </ask-user>

    <if condition="selecting-individually">
      <action>Present each question individually for yes/no.</action>
    </if>
  </step>

  <step id="write-questions" number="7">
    <description>Write Questions</description>

    <constraint>For new questions, determine the target file:
    - Built-in categories -> `<home>/.things/what-did-you-do/questions/custom.yaml`
    - User questions always go to the questions directory, never modifying built-in files
    </constraint>

    <action>Read the existing `custom.yaml`, append the new questions, and write it back.</action>
  </step>

  <step id="rebuild-index" number="8">
    <description>Rebuild Index</description>

    <command language="bash" tool="Bash">bash <plugin_root>/scripts/rebuild-question-index.sh</command>
  </step>

  <step id="git-workflow" number="9">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push the updated question bank?"</ask-user>
      </if>
      <if condition="workflow-auto">
        <action>Automatically `git add` the custom.yaml, `git commit -m "questions: add <N> custom questions"`, and `git push`.</action>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the questions have been saved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm" number="10">
    <description>Confirm</description>

    <completion-message>

    > Added [N] new questions to your custom question bank.
    >
    > - <category>: <count>
    > - <category>: <count>
    >
    > These questions will appear in your practice and mock sessions. Run `/practice` to try them out.

    </completion-message>
  </step>

</steps>
