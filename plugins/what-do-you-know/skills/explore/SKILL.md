---
name: explore
description: "Deep-dive into a topic using your arsenal evidence, with persona-driven probing questions and concept mapping"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<topic> [--persona staff-engineer|engineering-manager|...] [--depth exploratory|focused|deep]"
---

<references>
  <reference path="references/exploration-framework.md" />
</references>

<purpose>
Conduct a topic-driven deep dive that probes your understanding through conversation, maps what you know against what you've done, and identifies where your knowledge is strong, partial, or missing.
</purpose>

<steps>

  <step id="load-configuration" number="1">
    <description>Load Configuration</description>
    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>
      <read path="<home>/.things/shared/professional-profile.json" output="profile" />
      <read path="<home>/.things/what-do-you-know/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-wdyk` first." Then stop.</if>
      <substep name="extract-profile-fields">
        <action>Extract `building_skills`, `aspirational_skills`, `current_role`, `target_roles` from the professional profile, and `default_depth`, `default_persona`, `session_length` from preferences.</action>
      </substep>
    </load-config>
  </step>

  <step id="load-arsenal" number="2">
    <description>Load the User's Arsenal</description>
    <action>Read all files in `<home>/.things/i-did-a-thing/arsenal/` to understand logged skills and evidence. Read `<home>/.things/i-did-a-thing/index.json` for structured entry data.</action>
    <if condition="no-logs-exist">
      <output>
      You haven't logged any entries yet. Run `/thing-i-did` first so I have your experience to explore with. I can still probe your knowledge, but sessions are much richer when grounded in your actual work.
      </output>
    </if>
  </step>

  <step id="select-topic" number="3">
    <description>Select Topic</description>
    <if condition="topic-provided">
      <action>Use the topic from the argument.</action>
    </if>
    <if condition="no-topic">
      <ask-user-question>
        <question>What topic do you want to explore?</question>
        <option-with-text-input>Free text -- e.g., "distributed systems", "API design", "observability"</option-with-text-input>
      </ask-user-question>
    </if>
  </step>

  <step id="search-arsenal" number="4">
    <description>Search Arsenal for Topic Evidence</description>
    <action>Search `<home>/.things/i-did-a-thing/index.json` for entries matching the topic by:</action>
    - Tags that match or relate to the topic
    - `skills_used` and `skills_developed` fields
    - Entry titles and descriptions containing topic-related terms

    <action>Collect all matching entries as context for the session.</action>
  </step>

  <step id="load-session-history" number="5">
    <description>Load Session History</description>
    <command language="bash" tool="Bash">bash <plugin_root>/scripts/search-sessions.sh --topic <topic> --recent 5</command>
    <constraint>Use previous session data to avoid re-asking the same probing questions and to track progress on this topic.</constraint>
  </step>

  <step id="select-persona" number="6">
    <description>Select Persona</description>
    <if condition="persona-provided">
      <action>Use the specified persona.</action>
    </if>
    <if condition="no-persona">
      <action>Use the `default_persona` from config.</action>
    </if>
    <substep name="load-persona">
      <action>Load the selected persona from `<home>/.things/shared/roles/<persona>.md`.</action>
    </substep>
    <constraint>Adopt the persona's voice, evaluation weights, and follow-up patterns -- but adapt them for learning rather than interview coaching. The persona is probing to understand and deepen knowledge, not to evaluate interview readiness.</constraint>
  </step>

  <step id="select-depth" number="7">
    <description>Select Depth</description>
    <if condition="depth-provided">
      <action>Use the specified depth.</action>
    </if>
    <if condition="no-depth">
      <action>Use `default_depth` from config.</action>
    </if>

    - exploratory -- Broad overview: "What do you know about X? Walk me through the landscape." Cover breadth, identify strong and weak areas.
    - focused -- Targeted deep-dive: "Let's go deep on X. Explain how it works under the hood." Probe internals, edge cases, tradeoffs.
    - deep -- Intensive probing: "You've worked with X. Let's stress-test your mental model." Challenge assumptions, explore failure modes, demand precision.
  </step>

  <step id="begin-probing-dialogue" number="8">
    <description>Begin Probing Dialogue</description>
    <action>Use the persona's voice to begin exploring the topic. Ground questions in the user's actual experience from their arsenal.</action>

    Question patterns:
    - Experience-grounded: "You made an architecture decision about [X] in [project from arsenal]. Walk me through your reasoning."
    - Scale challenge: "What would break first if you scaled this 10x?"
    - Comparison: "How does your approach compare to [standard approach]?"
    - Edge cases: "What happens when [edge case]? How would you handle it?"
    - Teaching test: "If you had to explain [concept] to a junior engineer, where would you start?"
    - Connection probing: "How does [concept A] relate to [concept B from their experience]?"
    - Gap detection: "What's the difference between [similar concept A] and [similar concept B]?"

    <constraint>
    Adapt the probing based on depth level:
    - exploratory: 4-6 questions, broad coverage, identify landscape
    - focused: 6-8 questions, targeted depth in specific areas
    - deep: 8-12 questions, intensive probing, challenge mental models
    </constraint>
  </step>

  <step id="probe-and-adapt" number="9">
    <description>Probe Deeper Where Strong, Widen Where Thin</description>
    <action>As the user responds, adapt the probing strategy.</action>
    <if condition="strong-understanding">Push deeper: "What's happening at the layer below that?" or "What are the tradeoffs of that approach vs. alternatives?"</if>
    <if condition="thin-understanding">Widen: "Let's set that aside for now. What about [related concept]?" or "That's a gap worth noting. Let me ask about something adjacent."</if>
    <if condition="arsenal-reference">Connect: "You mentioned [entry]. How does that experience inform your understanding of the general principle?"</if>
    <constraint>
    Use the `session_length` config to pace the conversation:
    - short: ~15 min, 4-5 exchanges
    - medium: ~30 min, 7-8 exchanges
    - deep: ~60 min, 12+ exchanges
    </constraint>
  </step>

  <step id="score-dimensions" number="10">
    <description>Score on Learning Dimensions</description>
    <action>After the dialogue, score the user on five dimensions (from `references/exploration-framework.md`):</action>
    1. Depth (1-5) -- How far below the surface can they explain? Internals vs. buzzwords
    2. Accuracy (1-5) -- Are their mental models technically correct?
    3. Connections (1-5) -- Can they relate this to adjacent concepts and their own experiences?
    4. Application (1-5) -- Can they apply the knowledge to new situations?
    5. Articulation (1-5) -- Can they explain it clearly to someone else?
  </step>

  <step id="produce-concept-map" number="11">
    <description>Produce Concept Map</description>
    <action>Classify concepts discussed into strong, partial, and gap categories.</action>
    - Strong -- demonstrated depth, accuracy, and ability to teach
    - Partial -- understands the basics but gaps in depth or precision
    - Gap -- couldn't explain or had significant misconceptions

    <template name="concept-map">
      <output>
      Concept Map: [Topic]

      Strong:
      - [concept] -- [evidence of strength]

      Partial:
      - [concept] -- [what's missing]

      Gap:
      - [concept] -- [what to learn]
      </output>
    </template>
  </step>

  <step id="deliver-feedback" number="12">
    <description>Deliver Feedback</description>
    <action>Use the persona's voice to deliver feedback.</action>

    <template name="persona-assessment">
      <output>
      [Persona Name]'s Assessment

      | Dimension | Score | Notes |
      |-----------|-------|-------|
      | Depth | x/5 | brief note |
      | Accuracy | x/5 | brief note |
      | Connections | x/5 | brief note |
      | Application | x/5 | brief note |
      | Articulation | x/5 | brief note |

      Strongest area: what they demonstrated well

      Biggest opportunity: most impactful area to deepen

      From your arsenal: connections to logged experiences that could ground further learning
      </output>
    </template>
  </step>

  <step id="log-session" number="13">
    <description>Log the Session</description>
    <write path="<home>/.things/what-do-you-know/sessions/<date>-explore-<topic-slug>.md">

      <schema name="session-frontmatter">
      ```markdown
      ---
      type: explore
      date: <date>
      topic: <topic>
      persona: <persona>
      depth: <exploratory|focused|deep>
      scores:
        depth: <1-5>
        accuracy: <1-5>
        connections: <1-5>
        application: <1-5>
        articulation: <1-5>
        overall: <average>
      strong_concepts:
        - <concept>
      partial_concepts:
        - <concept>
      gap_concepts:
        - <concept>
      arsenal_references:
        - file: "<log filename>"
          relevance: "<how it was used>"
      ---
      ```
      </schema>

      <section name="body">
      ```markdown
      # Explore Session: <topic> -- <date>

      ## Topic
      <topic>

      ## Concept Map
      <strong / partial / gap breakdown>

      ## Key Exchanges
      <summary of most revealing Q&A moments>

      ## Feedback
      <summary of feedback given>

      ## Recommended Next Steps
      <what to explore, quiz, or bridge next>
      ```
      </section>

    </write>
  </step>

  <step id="update-knowledge-and-progress" number="14">
    <description>Update Knowledge Map and Progress</description>
    <substep name="update-knowledge-map">
      <action>Read and update `<home>/.things/what-do-you-know/knowledge-map.json`:</action>
      - Add or update topic entries under strong / building / gap / blind_spot based on scores
      - Note specific concepts in each category
    </substep>
    <substep name="update-progress">
      <action>Read and update `<home>/.things/what-do-you-know/progress.json`:</action>
      - Update dimension averages with new scores
      - Update topic breakdown
      - Add to sessions list
    </substep>
  </step>

  <step id="handle-git-workflow" number="15">
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
            <question>Would you like to commit and push this explore session?</question>
            <option>Yes</option>
            <option>No</option>
          </ask-user-question>
        </if>
        <if condition="workflow-auto">
          <action>Automatically `git add` the session file, knowledge-map.json, and progress.json, `git commit -m "explore: <topic>"`, and `git push`.</action>
        </if>
        <if condition="workflow-manual">
          <action>Tell the user the session has been saved and they can commit when ready.</action>
        </if>
      </substep>
    </git-workflow>
  </step>

  <step id="suggest-next-steps" number="16">
    <description>Suggest Next Steps</description>
    <completion-message>
      <template name="next-steps">
        <output>
        Next steps for [topic]:
        - Quiz yourself: `/quiz --topic <topic>` -- test retention with spaced repetition
        - Bridge a gap: `/bridge <gap-concept>` -- build a learning plan from existing knowledge
        - Explore adjacent: `/explore <related-topic>` -- broaden your map
        - Log an experience: `/thing-i-did` -- capture what you just learned
        </output>
      </template>

      <ask-user-question>
        <question>What next?</question>
        <option>Explore another topic</option>
        <option>Quiz this topic</option>
        <option>Bridge a gap from this session</option>
        <option>Done for now</option>
      </ask-user-question>
    </completion-message>
  </step>

</steps>
