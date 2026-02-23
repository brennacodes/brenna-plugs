---
name: quiz
description: "Test your knowledge with dynamically generated concept questions drawn from your actual projects and experiences"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--topic <topic>] [--persona staff-engineer|engineering-manager|...] [--count 3|5|10]"
---

<references>
  <reference path="references/quiz-rubric.md" />
</references>

<purpose>
Generate concept questions dynamically from your arsenal and index, present them in a persona's voice, score answers on learning dimensions, and track progress via spaced repetition.
</purpose>

<steps>

  <step id="load-configuration" number="1">
    <description>Load Configuration</description>
    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.</if>
      <read path="<home>/.things/shared/professional-profile.json" output="profile" />
      <read path="<home>/.things/what-do-you-know/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-wdyk` first." Then stop.</if>
      <substep name="extract-profile-fields">
        <action>Extract `building_skills`, `aspirational_skills` from the professional profile, and `default_depth`, `default_persona`, `session_length` from preferences.</action>
      </substep>
    </load-config>
  </step>

  <step id="load-arsenal-and-index" number="2">
    <description>Load Arsenal and Index</description>
    <read path="<home>/.things/i-did-a-thing/index.json" output="index" />
    <action>Read all files in `<home>/.things/i-did-a-thing/arsenal/` for skill evidence.</action>
    <if condition="no-logs-exist">
      <output>
      You haven't logged any entries yet. Run `/thing-i-did` first -- quiz questions are generated from your actual projects and experiences.
      </output>
      <exit />
    </if>
  </step>

  <step id="load-session-history" number="3">
    <description>Load Session History</description>
    <command language="bash" tool="Bash">bash <plugin_root>/scripts/search-sessions.sh --recent 20</command>
    <constraint>Use session history for spaced repetition: weight toward topics with lower scores, longer time since last quiz, and gaps identified in explore sessions.</constraint>
  </step>

  <step id="select-topic" number="4">
    <description>Select Topic</description>
    <if condition="topic-provided">
      <action>Use the provided topic.</action>
    </if>
    <if condition="no-topic">
      <action>Select a topic using spaced repetition weighting:</action>
      1. Topics with gap or partial scores from recent explore/quiz sessions
      2. Topics from `building_skills` and `aspirational_skills` not recently quizzed
      3. Topics with declining scores (tested before but getting worse)
      4. Random selection from arsenal skill areas not yet explored
    </if>
    <ask-user-question>
      <question>I'm thinking we should quiz [topic] -- it's been [reason]. Sound good?</question>
      <option>Yes -- let's do it</option>
      <option>Different topic -- I have something in mind</option>
    </ask-user-question>
  </step>

  <step id="select-persona" number="5">
    <description>Select Persona</description>
    <if condition="persona-provided">
      <action>Use the specified persona.</action>
    </if>
    <if condition="no-persona">
      <action>Use `default_persona` from config.</action>
    </if>
    <substep name="load-persona">
      <action>Load the selected persona from `<home>/.things/shared/roles/<persona>.md`. Adopt their voice for question delivery and feedback.</action>
    </substep>
  </step>

  <step id="determine-question-count" number="6">
    <description>Determine Question Count</description>
    <if condition="count-provided">
      <action>Use the provided count.</action>
    </if>
    <if condition="no-count">
      <action>Base on `session_length`:</action>
      - short --> 3 questions
      - medium --> 5 questions
      - deep --> 10 questions
    </if>
  </step>

  <step id="generate-questions" number="7">
    <description>Generate Questions Dynamically</description>
    <action>Generate questions from `<home>/.things/i-did-a-thing/index.json` -- NOT from a static question bank. Each question should reference the user's actual projects and experiences.</action>
    <constraint>Questions must be dynamically generated from index entries, never from a pre-built question bank.</constraint>

    Question patterns:
    - Mechanism: "Explain how [mechanism from their project] works under the hood." (e.g., "Explain how the PostToolUse hook mechanism works in your screenshotr plugin")
    - Tradeoff: "What are the tradeoffs of [approach they chose] vs. [alternative]?" (e.g., "What are the tradeoffs of atomic file writes vs. direct writes?")
    - Decision rationale: "You chose [decision from log]. What alternatives exist and why did you pick this?" (e.g., "You chose Homebrew for distribution. What alternatives exist and why?")
    - Failure mode: "What would go wrong if [component from their project] failed? How would you detect and recover?"
    - Generalization: "You applied [pattern] in [project]. Where else would this pattern be useful? Where would it break down?"
    - Connection: "How does [concept A from project 1] relate to [concept B from project 2]?"
    - Teaching: "Explain [concept from their work] to someone who's never seen it before."

    Selection algorithm:
    1. Filter index entries by topic relevance (tags, skills_used, skills_developed)
    2. For each entry, identify 2-3 potential question angles
    3. Score potential questions:
       - `gap_weight = 5 - avg_score_for_topic` (from session history)
       - `recency_bonus = days_since_last_asked / 14` (capped at 2.0)
       - `variety_bonus = 1.5 if question_type not recently used`
    4. Select from top-scored questions with weighted randomness
  </step>

  <step id="present-questions" number="8">
    <description>Present Questions</description>
    <action>Present questions one at a time in the persona's voice.</action>

    <template name="question-presentation">
      <output>
      [Persona Name]: question

      Take your time. Think through it carefully before answering.
      </output>
    </template>

    <constraint>After each answer, briefly acknowledge but don't give detailed feedback yet.</constraint>
    <if condition="session-short">
      <action>Give per-question feedback instead of batching.</action>
    </if>
  </step>

  <step id="score-each-answer" number="9">
    <description>Score Each Answer</description>
    <action>Score each answer on the five learning dimensions (from `references/quiz-rubric.md`):</action>
    1. Depth (1-5) -- Surface-level recall vs. deep understanding
    2. Accuracy (1-5) -- Technically correct mental models
    3. Connections (1-5) -- Links to related concepts and experiences
    4. Application (1-5) -- Can apply to new scenarios
    5. Articulation (1-5) -- Clear, structured explanation

    <substep name="classify-concept">
      <action>Classify each answer's concept as: strong | partial | gap</action>
    </substep>
  </step>

  <step id="deliver-feedback" number="10">
    <description>Deliver Feedback</description>
    <action>After all questions, deliver batched feedback.</action>

    <template name="quiz-results">
      <output>
      Quiz Results: [Topic]

      | # | Concept | Score | Strength |
      |---|---------|-------|----------|
      | 1 | concept | x/5 | strong/partial/gap |
      | 2 | concept | x/5 | strong/partial/gap |
      | ... | | | |
      </output>
    </template>

    <template name="dimension-scores">
      <output>
      Overall Dimensions:

      | Dimension | Score | Notes |
      |-----------|-------|-------|
      | Depth | x/5 | brief note |
      | Accuracy | x/5 | brief note |
      | Connections | x/5 | brief note |
      | Application | x/5 | brief note |
      | Articulation | x/5 | brief note |
      </output>
    </template>

    <template name="feedback-summary">
      <output>
      What you nailed: strongest answers

      Where to dig deeper: weakest areas with specific suggestions

      From your arsenal: entries that could strengthen weak answers
      </output>
    </template>
  </step>

  <step id="log-session" number="11">
    <description>Log the Session</description>
    <write path="<home>/.things/what-do-you-know/sessions/<date>-quiz-<topic-slug>.md">

      <schema name="session-frontmatter">
      ```markdown
      ---
      type: quiz
      date: <date>
      topic: <topic>
      persona: <persona>
      question_count: <N>
      scores:
        depth: <1-5>
        accuracy: <1-5>
        connections: <1-5>
        application: <1-5>
        articulation: <1-5>
        overall: <average>
      per_question:
        - concept: "<concept>"
          score: <1-5>
          strength: strong|partial|gap
        - concept: "<concept>"
          score: <1-5>
          strength: strong|partial|gap
      arsenal_references:
        - file: "<log filename>"
      ---
      ```
      </schema>

      <section name="body">
      ```markdown
      # Quiz Session: <topic> -- <date>

      ## Questions and Answers
      <per-question summary>

      ## Feedback
      <summary of feedback>

      ## Spaced Repetition Notes
      <concepts to re-quiz, suggested interval>
      ```
      </section>

    </write>
  </step>

  <step id="update-progress" number="12">
    <description>Update Progress</description>
    <action>Read and update `<home>/.things/what-do-you-know/progress.json` and `<home>/.things/what-do-you-know/knowledge-map.json` with new scores and concept classifications.</action>
  </step>

  <step id="handle-git-workflow" number="13">
    <description>Handle Git Workflow</description>
    <git-workflow>
      <substep name="pull-latest">
        <action>Before committing, pull latest changes from the remote (if one exists) to avoid conflicts.</action>
        <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>
      </substep>
      <substep name="commit-by-workflow">
        <action>Based on the `git_workflow` setting in `config.json`:</action>
        <if condition="workflow-ask">
          <ask-user-question>
            <question>Would you like to commit and push this quiz session?</question>
            <option>Yes</option>
            <option>No</option>
          </ask-user-question>
        </if>
        <if condition="workflow-auto">
          <action>Automatically `git add` the session file, progress.json, and knowledge-map.json, `git commit -m "quiz: <topic>"`, and `git push`.</action>
        </if>
        <if condition="workflow-manual">
          <action>Tell the user the session has been saved and they can commit when ready.</action>
        </if>
      </substep>
    </git-workflow>
  </step>

  <step id="offer-next-steps" number="14">
    <description>Offer Next Steps</description>
    <completion-message>
      <ask-user-question>
        <question>What next?</question>
        <option>Quiz again (same topic, different questions)</option>
        <option>Quiz a different topic</option>
        <option>Explore a weak area from this quiz</option>
        <option>Bridge a gap to build a learning plan</option>
        <option>Done for now</option>
      </ask-user-question>

      <if condition="quiz-same-topic">
        <action>Go back to Step 7.</action>
      </if>
      <if condition="quiz-different-topic">
        <action>Go to Step 4.</action>
      </if>
    </completion-message>
  </step>

</steps>
