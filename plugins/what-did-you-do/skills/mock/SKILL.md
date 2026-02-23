---
name: mock
description: "Simulate a full interview round with timed questions, persona-consistent follow-ups, and end-of-round assessment"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[company: amazon|google|meta|<custom>] [--stage phone-screen|technical|onsite|bar-raiser|system-design] [--duration 30|45|60]"
---

<references>
  - references/mock-formats.md
  - references/timing-guide.md
</references>

<purpose>
Run a realistic interview round: multiple questions, consistent persona, timed pacing, and a comprehensive debrief at the end.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.</if>

      <read path="<home>/.things/shared/professional-profile.json" output="profile" />

      <read path="<home>/.things/what-did-you-do/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-wdyd` first." Then stop.</if>
    </load-config>
  </step>

  <step id="load-arsenal-and-history" number="2">
    <description>Load Arsenal and Session History</description>

    <action>Read `<home>/.things/i-did-a-thing/arsenal/` and professional goals from `<home>/.things/shared/professional-profile.json`.</action>

    <command language="bash" tool="Bash">bash <plugin_root>/scripts/search-sessions.sh --type mock --recent 5</command>
  </step>

  <step id="select-company-and-stage" number="3">
    <description>Select Company and Stage</description>

    <if condition="company-provided">
      <read path="<home>/.things/shared/companies/<company>.yaml" output="company-profile" />
    </if>

    <if condition="no-company-specified">
      <ask-user>
      Which company are you preparing for?

      <options>
      - Amazon -- LP-driven, bar raiser focus
      - Google -- technical excellence, Googleyness
      - Meta -- move fast, impact-driven
      - Generic -- no company-specific framing
      - Custom -- I have a company profile set up
      </options>
      </ask-user>
    </if>

    <if condition="stage-provided">
      <action>Use the provided `--stage`.</action>
    </if>

    <if condition="no-stage-and-company-selected">
      <action>Present the company's interview stages.</action>
    </if>

    <if condition="no-stage-and-generic">
      <ask-user>
      Which interview stage?

      <options>
      - Phone Screen (30 min) -- 3-4 questions, culture and motivation
      - Technical (45 min) -- coding and technical discussion
      - Onsite Behavioral (45 min) -- 4-5 deep behavioral questions
      - System Design (45 min) -- one end-to-end design problem
      - Bar Raiser (60 min) -- cross-functional deep dive
      </options>
      </ask-user>
    </if>
  </step>

  <step id="configure-round" number="4">
    <description>Configure the Round</description>

    <action>Based on company profile and stage, determine round parameters.</action>

    <constraint>Duration: from `--duration` arg, company profile, or stage default.</constraint>
    <constraint>Question count: from `references/mock-formats.md`.</constraint>
    <constraint>Persona: from company profile's `persona` field for this stage, or select appropriate persona.</constraint>
    <constraint>Evaluation focus: from company profile or stage defaults.</constraint>
    <constraint>Question categories: from company values -> question_themes mapping.</constraint>

    <read path="<home>/.things/shared/roles/<persona>.md" output="persona" />
  </step>

  <step id="brief-user" number="5">
    <description>Brief the User</description>

    <template name="briefing">

    > **Mock Interview: [Company] -- [Stage]**
    >
    > Duration: ~[X] minutes
    > Questions: [N]
    > Interviewer: [Persona Role]
    > Focus: [evaluation areas]
    >
    > I'll ask questions one at a time. Answer as you would in a real interview. I'll hold all feedback until the debrief at the end.
    >
    > Ready?

    </template>

    <constraint>Wait for confirmation before proceeding.</constraint>
  </step>

  <step id="conduct-round" number="6">
    <description>Conduct the Round</description>

    <for-each item="question" source="round-questions">

      <substep name="select-question">
        <description>Select a question using the same spaced repetition algorithm as the practice skill, but filtered by the company's `question_themes` and stage's `evaluation_focus`.</description>
      </substep>

      <substep name="ask-question">
        <description>Ask the question in the persona's voice.</description>
      </substep>

      <substep name="receive-answer">
        <description>Receive the answer.</description>
      </substep>

      <substep name="optional-follow-up">
        <description>Follow-up handling.</description>
        <if condition="has-follow-ups-and-time-permits">Ask ONE `depth: 2` follow-up in persona voice.</if>
      </substep>

      <substep name="silent-score">
        <description>Score silently.</description>
        <constraint>Silently score the answer -- do NOT share scores yet.</constraint>
      </substep>

      <substep name="track-time">
        <description>Track time spent per question (use `references/timing-guide.md`).</description>
      </substep>

      <substep name="transition">
        <description>Transition to next question naturally in persona voice.</description>

        Between questions, use persona-appropriate transitions:
        - Staff Engineer: "Good. Let me shift gears..."
        - Engineering Manager: "Thank you for sharing that. I'd like to explore..."
        - Bar Raiser: "Interesting. Here's a different angle..."
      </substep>

    </for-each>

    <constraint>Do NOT provide feedback between questions. Save it all for the debrief.</constraint>
  </step>

  <step id="debrief" number="7">
    <description>End-of-Round Debrief</description>

    <action>After all questions, break character and deliver a comprehensive assessment.</action>

    <template name="overall-assessment">

    > **Mock Interview Debrief**
    >
    > **Overall Assessment: [Strong / Advancing / Developing / Not Ready]**
    >
    > **Dimension Scores:**
    >
    > | Dimension | Avg Score | Strongest Answer | Weakest Answer |
    > |-----------|-----------|-----------------|----------------|
    > | Specificity | x/5 | Q<n> | Q<n> |
    > | Structure | x/5 | Q<n> | Q<n> |
    > | Impact | x/5 | Q<n> | Q<n> |
    > | Relevance | x/5 | Q<n> | Q<n> |
    > | Self-Advocacy | x/5 | Q<n> | Q<n> |

    </template>

    <if condition="company-specific">
      <template name="company-alignment">

      > **[Company] Alignment:**
      > - Values demonstrated: <list>
      > - Values missing: <list>
      > - Level calibration: <assessment vs target level>

      </template>
    </if>

    <template name="per-question-breakdown">

    > **Q1: "<question>"**
    > Score: x/5 | Strengths: <brief> | To improve: <brief>
    > Arsenal suggestion: <relevant log> (`<evidence_type>`) -- e.g., "Your lesson about X is directly relevant" or "Your decision entry on Y demonstrates the tradeoff analysis they want"

    </template>

    <template name="action-items">

    > **Top 3 Action Items:**
    > 1. <most impactful improvement>
    > 2. <next priority>
    > 3. <third priority>

    </template>
  </step>

  <step id="log-session" number="8">
    <description>Log the Session</description>

    <write path="<home>/.things/what-did-you-do/sessions/<date>-mock-<company>-<stage>.md">
      <action>Write session file with full frontmatter including all per-question scores, company alignment, and overall assessment.</action>
    </write>
  </step>

  <step id="update-progress" number="9">
    <description>Update Progress Dashboard</description>

    <action>Update `<home>/.things/what-did-you-do/progress.json` with new scores and session entry.</action>
  </step>

  <step id="git-workflow" number="10">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push this mock session?"</ask-user>
      </if>
      <if condition="workflow-auto">
        <action>Automatically `git add` the session file and progress.json, `git commit -m "mock: <company> <stage>"`, and `git push`.</action>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the session has been saved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="suggest-unlogged" number="11">
    <description>Suggest Unlogged Accomplishments</description>

    <if condition="user-mentioned-unlogged-experiences">

    > During the mock, you referenced some experiences I don't see in your logs:
    > - <experience> -- this sounds like a <evidence type> entry
    >
    > Logging these would strengthen your arsenal. Run `/thing-i-did` when ready.

    </if>
  </step>

  <step id="offer-next-steps" number="12">
    <description>Offer Next Steps</description>

    <ask-user>
    What next?

    <options>
    - Run another mock round (same company, different stage)
    - Drill specific questions that were weak
    - Review progress across all mocks
    - Prep for a specific company (`/prep-for`)
    - Done for now
    </options>
    </ask-user>
  </step>

</steps>
