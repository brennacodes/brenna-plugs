---
name: review
description: "Assess interview readiness across all dimensions with trend analysis, gap identification, and targeted recommendations"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--company amazon|google|meta] [--since YYYY-MM-DD]"
---

<references>
  - references/readiness-model.md
</references>

<purpose>
Analyze all practice and mock sessions to produce a comprehensive readiness assessment with trends, gaps, and specific action items.
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

  <step id="load-sessions" number="2">
    <description>Load All Session Data</description>

    <action>Read all files in `<home>/.things/what-did-you-do/sessions/`.</action>

    <if condition="since-provided">Filter to sessions after that date.</if>
    <if condition="company-provided">Load the company profile for company-specific calibration.</if>

    <if condition="no-sessions-exist">

    > No practice sessions found. Run `/practice` or `/mock` first to build data for a readiness review.

    <exit />
    </if>
  </step>

  <step id="load-arsenal-and-profile" number="3">
    <description>Load Arsenal and Profile</description>

    <action>Read `<home>/.things/i-did-a-thing/arsenal/` for skill evidence. Professional profile comes from `<home>/.things/shared/professional-profile.json` (already loaded in Step 1).</action>
  </step>

  <step id="compute-readiness" number="4">
    <description>Compute Readiness Assessment</description>

    <action>Use the model in `references/readiness-model.md` to compute the following.</action>

    <phase name="dimension-analysis" number="1">
      Dimension Analysis:

      <for-each item="dimension" source="specificity, structure, impact, relevance, self-advocacy">
        - Current average (last 5 sessions)
        - All-time average
        - Trend (improving / stable / declining)
        - Weakest question category for this dimension
      </for-each>
    </phase>

    <phase name="category-analysis" number="2">
      Category Analysis:

      <for-each item="category" source="behavioral, technical, leadership, situational, system-design">
        - Average score
        - Number of sessions
        - Strongest and weakest dimension within this category
        - Questions that scored lowest
      </for-each>
    </phase>

    <phase name="skill-coverage" number="3">
      Skill Coverage:

      <action>Compare `building_skills` and `aspirational_skills` from profile against skills tested in sessions.</action>

      - Skills practiced (with frequency and average scores)
      - Skills never practiced
      - Skills tested but not in user's goals (may indicate profile needs updating)
    </phase>

    <phase name="anti-pattern-tracking" number="4">
      Anti-Pattern Tracking:

      <action>Across all sessions, identify:</action>

      - Most frequent anti-patterns
      - Anti-patterns that have improved (no longer appearing)
      - Persistent anti-patterns (appearing in recent sessions despite earlier coaching)
    </phase>
  </step>

  <step id="company-calibration" number="5">
    <description>Company-Specific Calibration (if applicable)</description>

    <if condition="company-provided-or-recent-company-mocks">

      <phase name="values-alignment" number="1">
        Values Alignment:

        <action>For each company value, assess how well the user's session scores demonstrate alignment. Map values -> question_themes -> skills_tested -> session scores.</action>
      </phase>

      <phase name="level-readiness" number="2">
        Level Readiness:

        <action>Compare the user's average scores against the company's `level_expectations` for their target role.</action>
      </phase>

      <phase name="stage-readiness" number="3">
        Stage Readiness:

        <action>For each interview stage in the company's process, assess readiness based on mock sessions for that stage.</action>
      </phase>

    </if>
  </step>

  <step id="present-assessment" number="6">
    <description>Present the Assessment</description>

    <template name="readiness-report">

    > Interview Readiness Review
    > Based on [N] sessions from [date range]
    >
    > Overall Readiness: [Strong / Advancing / Developing / Not Ready]
    >
    > Dimension Scores:
    >
    > | Dimension | Current Avg | All-Time Avg | Trend | Weakest Category |
    > |-----------|------------|-------------|-------|-----------------|
    > | Specificity | x/5 | x/5 | up/stable/down | <category> |
    > | Structure | x/5 | x/5 | up/stable/down | <category> |
    > | Impact | x/5 | x/5 | up/stable/down | <category> |
    > | Relevance | x/5 | x/5 | up/stable/down | <category> |
    > | Self-Advocacy | x/5 | x/5 | up/stable/down | <category> |
    >
    > Strongest Areas: <top 2-3>
    > Biggest Gaps: <top 2-3>
    >
    > Category Readiness:
    >
    > | Category | Avg Score | Sessions | Status |
    > |----------|-----------|----------|--------|
    > | Behavioral | x/5 | N | Ready/Developing/Gap |
    > | Technical | x/5 | N | Ready/Developing/Gap |
    > | Leadership | x/5 | N | Ready/Developing/Gap |
    > | Situational | x/5 | N | Ready/Developing/Gap |
    > | System Design | x/5 | N | Ready/Developing/Gap |
    >
    > Persistent Anti-Patterns:
    > - <pattern>: seen in X of last Y sessions. <coaching note>
    >
    > Skills Coverage:
    > - Practiced: <list with scores>
    > - Never practiced: <list>

    </template>

    <if condition="company-specific">
      <template name="company-readiness-section">

      > [Company] Readiness:
      > - Values coverage: X/Y demonstrated
      > - Target level: <level> -- [Ready / Close / Gap]
      > - Stage readiness: <per-stage assessment>

      </template>
    </if>
  </step>

  <step id="generate-action-plan" number="7">
    <description>Generate Action Plan</description>

    <template name="action-plan">

    > Recommended Next Steps (priority order):
    >
    > 1. [Highest priority]: <specific action -- e.g., "Practice 3 more leadership questions focusing on structure">
    > 2. [Second priority]: <specific action>
    > 3. [Third priority]: <specific action>
    >
    > Arsenal Gaps:
    > - <skills that need more logged evidence>
    > - Run `/thing-i-did` to log accomplishments in these areas
    >
    > Recommended Practice Plan:
    > - This week: <category> questions with <persona> focus
    > - Next week: <category> questions, then a full mock
    > - Before interview: Full mock for each stage

    </template>
  </step>

  <step id="update-progress" number="8">
    <description>Update Progress Dashboard</description>

    <write path="<home>/.things/what-did-you-do/progress.json">
      <action>Write the updated assessment.</action>
    </write>
  </step>

  <step id="git-workflow" number="9">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push the updated progress?"</ask-user>
      </if>
      <if condition="workflow-auto">
        <action>Automatically `git add` progress.json, `git commit -m "review: update readiness assessment"`, and `git push`.</action>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the progress dashboard has been updated and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="offer-next-steps" number="10">
    <description>Offer Next Steps</description>

    <ask-user>
    What would you like to do?

    <options>
    - Practice my weakest category
    - Run a full mock for [company]
    - Drill a specific dimension (specificity, structure, etc.)
    - Update my professional profile
    - Done for now
    </options>
    </ask-user>
  </step>

</steps>
