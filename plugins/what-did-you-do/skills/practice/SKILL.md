---
name: practice
description: "Drill a single interview question with persona-driven feedback, arsenal cross-references, and spaced repetition selection"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[category: behavioral|technical|leadership|situational|system-design] [--persona staff-engineer|engineering-manager|...]"
---

<references>
  - references/feedback-rubric.md
  - references/answer-anti-patterns.md
  - references/stage-coaching.md
</references>

<purpose>
Select a question using spaced repetition, adopt an interviewer persona, coach the user's answer, then log a detailed session file.
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

  <step id="load-arsenal" number="2">
    <description>Load the User's Arsenal</description>

    <action>Read all files in `<home>/.things/i-did-a-thing/arsenal/` to understand logged skills and evidence. Read professional goals from `<home>/.things/shared/professional-profile.json`.</action>

    <if condition="no-logs-exist">

    > You haven't logged any entries yet. Run `/thing-i-did` first so I have your arsenal to coach you with. I can still ask questions, but my feedback will be much richer with your evidence loaded.

    </if>
  </step>

  <step id="load-session-history" number="3">
    <description>Load Session History</description>

    <command language="bash" tool="Bash">bash <plugin_root>/scripts/search-sessions.sh --recent 10</command>

    <constraint>Use recent session data for spaced repetition: avoid recently asked questions, weight toward weak dimensions.</constraint>
  </step>

  <step id="select-persona" number="4">
    <description>Select Persona</description>

    <if condition="persona-specified">
      <read path="<home>/.things/shared/roles/<persona>.md" output="persona" />
    </if>

    <if condition="no-persona-specified">
      <action>Select based on the question's `interviewer_types` field.</action>
    </if>

    <if condition="no-persona-and-no-question-yet">
      <ask-user>
      Who's interviewing you today?

      <options>
      - Staff Engineer -- technical depth, architecture, tradeoffs
      - Engineering Manager -- collaboration, communication, growth
      - Principal Engineer -- system thinking, organizational impact
      - Bar Raiser -- judgment, ownership, cross-functional depth
      - Recruiter -- motivation, culture fit, communication clarity
      - Surprise -- I'll pick based on the question
      </options>
      </ask-user>
    </if>

    <action>Read the selected persona file and adopt their voice, evaluation weights, and follow-up patterns.</action>
  </step>

  <step id="select-category" number="5">
    <description>Select Question Category</description>

    <if condition="category-provided">
      <action>Use the provided category argument.</action>
    </if>

    <if condition="no-category-provided">
      <ask-user>
      What kind of question?

      <options>
      - `behavioral` -- "Tell me about a time when..."
      - `technical` -- Architecture, code quality, operations
      - `system-design` -- End-to-end system architecture
      - `leadership` -- Mentorship, decisions, strategy
      - `situational` -- "What would you do if..."
      - `surprise` -- Weighted toward your gaps
      </options>
      </ask-user>
    </if>
  </step>

  <step id="select-question" number="6">
    <description>Select Question Using Spaced Repetition</description>

    <action>Read `<plugin_root>/questions/<category>.yaml` and `<home>/.things/what-did-you-do/questions/custom.yaml` for custom questions.</action>

    <algorithm name="spaced-repetition">
      <phase name="filter-category" number="1">Filter by category (and stage if `default_stage` is set in config).</phase>
      <phase name="filter-level" number="2">Filter by level appropriate to `current_role` and `target_roles`.</phase>
      <phase name="filter-recency" number="3">Filter out questions asked in the last 7 days (from session history).</phase>
      <phase name="score-candidates" number="4">
        Score remaining questions:
        - `weakness_weight = 5 - avg_score_for_skills_tested` (from session history)
        - `recency_bonus = days_since_last_asked / 14` (capped at 2.0)
        - `aspirational_bonus = 1.5 if any skill_tested is in aspirational_skills, else 0`
        - `total = weakness_weight + recency_bonus + aspirational_bonus`
      </phase>
      <phase name="weighted-random" number="5">Select from top-scored questions with some randomness (weighted random, not strictly top).</phase>
    </algorithm>
  </step>

  <step id="ask-question" number="7">
    <description>Ask the Question</description>

    <action>Present the question in the persona's voice.</action>

    <template name="persona-question">

    > **[Persona Name]**: <question>
    >
    > Take your time. Answer as if you're in an actual interview.

    </template>

    <constraint>Note the question's `time_budget_minutes` and `expected_format` for coaching context, but don't display them to the user.</constraint>
  </step>

  <step id="analyze-answer" number="8">
    <description>Receive and Analyze the Answer</description>

    <action>After the user answers, analyze against five dimensions (from `references/feedback-rubric.md`).</action>

    <rubric>
    1. Specificity (1-5) -- Concrete details vs vague claims
    2. Structure (1-5) -- Clear narrative arc (STAR/CAR)
    3. Impact (1-5) -- Quantified outcomes, scope of effect
    4. Relevance (1-5) -- Actually answers the question asked
    5. Self-Advocacy (1-5) -- Owns contribution without hogging credit
    </rubric>

    <validate>Check the answer against the question's `red_flags` and `green_flags`.</validate>

    <action>Cross-reference with arsenal, prioritizing evidence types by question theme.</action>

    <if condition="question-about-failure-or-challenge">Prioritize `lesson` entries from arsenal.</if>
    <if condition="question-about-expertise-or-depth">Prioritize `expertise` entries.</if>
    <if condition="question-about-technical-decision">Prioritize `decision` entries.</if>
    <if condition="question-about-influence-or-mentoring">Prioritize `influence` entries.</if>
    <if condition="question-about-vision-or-hypothetical">Prioritize `insight` entries.</if>
    <if condition="standard-behavioral-question">Default to `accomplishment` entries.</if>

    For each relevant arsenal entry:
    - Find logged entries that could strengthen the answer
    - Identify skills demonstrated but not mentioned
    - Note metrics from logs they could have cited
  </step>

  <step id="follow-ups" number="9">
    <description>Deliver Follow-Ups (Based on Depth Config)</description>

    Based on `follow_up_depth` in config:

    <if condition="depth-concise">
      <action>Skip follow-ups. Go directly to feedback.</action>
    </if>

    <if condition="depth-detailed">
      <action>Ask the question's `depth: 2` follow-up in the persona's voice. Analyze the follow-up answer.</action>
    </if>

    <if condition="depth-coaching">
      <action>Ask `depth: 2` follow-up, analyze, then ask `depth: 3` follow-up. Continue the conversation until the user is satisfied.</action>
    </if>
  </step>

  <step id="deliver-feedback" number="10">
    <description>Deliver Feedback</description>

    <action>Use the persona's voice and evaluation weights. Reference `references/feedback-rubric.md` for scoring and `references/answer-anti-patterns.md` for anti-pattern detection. Use `references/stage-coaching.md` for stage-specific guidance.</action>

    <template name="feedback-format">

    > **[Persona Name]'s Assessment**
    >
    > | Dimension | Score | Notes |
    > |-----------|-------|-------|
    > | Specificity | x/5 | <brief note> |
    > | Structure | x/5 | <brief note> |
    > | Impact | x/5 | <brief note> |
    > | Relevance | x/5 | <brief note> |
    > | Self-Advocacy | x/5 | <brief note> |
    >
    > What worked: <specific strength in the persona's voice>
    >
    > To strengthen: <specific improvement in the persona's voice>
    >
    > From your arsenal: <reference to logged entries that could enhance the answer, adapted by evidence type -- e.g., "Your lesson about X is directly relevant here" or "Your expertise entry on X covers exactly what they're asking about" or "Your decision entry about X demonstrates the tradeoff analysis they want to see">
    >
    > Anti-patterns detected: <any from the question's red_flags or references/answer-anti-patterns.md>

    </template>

    <if condition="depth-coaching">
      <template name="coaching-action-items">

      > Action items:
      > 1. <specific thing to practice>
      > 2. <accomplishment to log that would fill a gap>
      > 3. <skill to develop>

      </template>
    </if>
  </step>

  <step id="log-session" number="11">
    <description>Log the Session</description>

    <write path="<home>/.things/what-did-you-do/sessions/<date>-practice-<question-id>.md">
      <schema name="session-frontmatter">
      ```markdown
      ---
      type: practice
      date: <date>
      question_id: <id>
      question_category: <category>
      question_text: "<text>"
      persona: <persona used>
      follow_up_depth: <concise|detailed|coaching>
      scores:
        specificity: <1-5>
        structure: <1-5>
        impact: <1-5>
        relevance: <1-5>
        self_advocacy: <1-5>
        overall: <average>
      anti_patterns_detected:
        - pattern: "<name>"
          example: "<quote from user's answer>"
      green_flags_hit:
        - "<flag>"
      arsenal_references:
        - file: "<log filename>"
          relevance: "<how it could strengthen the answer>"
      skills_tested:
        - "<skill>"
      unlogged_accomplishment_hints:
        - "<something the user mentioned that isn't in their logs>"
      comparison_to_previous:
        same_question: <null or previous score>
        same_skills: <avg score for these skills across sessions>
      ---
      ```
      </schema>

      <template name="session-body">
      ```markdown
      # Practice Session: <date>

      ## Question
      <question text>

      ## User's Answer
      <summary of their answer>

      ## Feedback Given
      <summary of feedback>

      ## Arsenal Connections
      <which logs were referenced and how>
      ```
      </template>
    </write>
  </step>

  <step id="update-progress" number="12">
    <description>Update Progress Dashboard</description>

    <action>Read and update `<home>/.things/what-did-you-do/progress.json`.</action>

    - Update dimension averages with new scores
    - Update category breakdown
    - Add to recent sessions list
    - Recalculate strongest/weakest categories
  </step>

  <step id="git-workflow" number="13">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push this practice session?"</ask-user>
      </if>
      <if condition="workflow-auto">
        <action>Automatically `git add` the session file and progress.json, `git commit -m "practice: <question-id>"`, and `git push`.</action>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the session has been saved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="suggest-unlogged" number="14">
    <description>Suggest Logging Unlogged Accomplishments</description>

    <if condition="user-mentioned-unlogged-experiences">

    > I noticed you mentioned some experiences that aren't logged yet:
    > - <experience summary> -- this sounds like a <evidence type> entry
    >
    > These would strengthen your arsenal. Run `/thing-i-did` when you're ready to log them.

    </if>
  </step>

  <step id="offer-next-steps" number="15">
    <description>Offer Next Steps</description>

    <ask-user>
    What next?

    <options>
    - Practice another question
    - Practice the same category again
    - Review my progress across sessions
    - Done for now
    </options>
    </ask-user>

    <if condition="another-question">Go back to Step 5.</if>
    <if condition="review-progress">Display a summary from `progress.json`.</if>
  </step>

</steps>
