---
name: gaps
description: "Analyze knowledge gaps across your skills by cross-referencing arsenal evidence, learning sessions, and career goals"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--focus building|aspirational|all]"
---

<references>
  <reference path="references/gap-analysis-model.md" />
</references>

<purpose>
Cross-reference your career goals, arsenal evidence, and learning session history to identify knowledge gaps, blind spots, and areas of strength. Produces a prioritized gap report with actionable next steps.
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
        <action>Extract `building_skills`, `aspirational_skills`, `current_role`, `target_roles` from the professional profile.</action>
      </substep>
    </load-config>
  </step>

  <step id="load-all-data" number="2">
    <description>Load All Data</description>
    <action>Read the following data files:</action>
    <read path="<home>/.things/i-did-a-thing/index.json" output="index" />
    <action>Read all files in `<home>/.things/i-did-a-thing/arsenal/` for skill evidence.</action>
    <read path="<home>/.things/what-do-you-know/progress.json" output="progress" />
    <read path="<home>/.things/what-do-you-know/knowledge-map.json" output="knowledge-map" />
    <substep name="load-session-history">
      <command language="bash" tool="Bash">bash <plugin_root>/scripts/search-sessions.sh --recent 50</command>
      <action>Load all learning session history for score data.</action>
    </substep>
    <if condition="no-learning-sessions">
      <output>
      No learning sessions found. I'll analyze your arsenal for potential gaps, but your gap analysis will be more accurate after a few explore or quiz sessions.

      Try `/explore` first to establish baseline knowledge in your key areas.
      </output>
    </if>
  </step>

  <step id="determine-focus" number="3">
    <description>Determine Focus</description>
    <if condition="focus-provided">
      <action>Use the provided focus.</action>
    </if>
    <if condition="no-focus">
      <ask-user-question>
        <question>Which skills should I analyze?</question>
        <option>Building skills -- skills you're actively developing (Recommended)</option>
        <option>Aspirational skills -- skills you want to develop next</option>
        <option>All -- comprehensive analysis across both</option>
      </ask-user-question>
    </if>
  </step>

  <step id="analyze-skill-areas" number="4">
    <description>Analyze Each Skill Area</description>
    <action>For each skill in the selected focus set, evaluate across four dimensions:</action>

    <validate name="arsenal-evidence">
      Arsenal evidence:
      - How many index entries reference this skill?
      - What evidence types are present? (accomplishments only? or also lessons, decisions, expertise, insights?)
      - How recent is the evidence?
      - How diverse are the projects/contexts?
    </validate>

    <validate name="learning-session-data">
      Learning session data:
      - How many explore/quiz sessions cover this topic?
      - What are the average scores across learning dimensions?
      - Are scores trending up, stable, or down?
      - What concepts within this skill are strong vs. gap?
    </validate>

    <validate name="evidence-type-diversity">
      Evidence type diversity:
      - All accomplishments? --> You can do it but can you explain it?
      - No lessons? --> You may not recognize failure patterns
      - No decisions? --> You may not be able to articulate tradeoffs
      - No expertise? --> Surface-level understanding risk
    </validate>

    <validate name="goal-alignment">
      Goal alignment:
      - Is this skill critical for `target_roles`?
      - How does it relate to `career_direction`?
      - Is it a prerequisite for `aspirational_skills`?
    </validate>
  </step>

  <step id="classify-each-area" number="5">
    <description>Classify Each Area</description>
    <action>Based on the analysis, classify each skill:</action>
    - Strong -- Multiple diverse evidence types + high learning scores + recent activity. You can explain it, apply it, and teach it.
    - Building -- Some evidence and/or moderate learning scores. You're developing but have clear depth gaps.
    - Gap -- Little evidence despite relevance to goals. You know it exists but can't go deep.
    - Blind Spot -- Relevant to target roles but no evidence AND no learning sessions. You may not realize you need it.
  </step>

  <step id="present-gap-report" number="6">
    <description>Present Gap Report</description>

    <template name="gap-report">
      <output>
      Knowledge Gap Analysis

      Focus: `<building|aspirational|all>` skills for `<target_roles>`
      </output>

      <section name="strong">
        <output>
        Strong
        | Skill | Evidence | Types | Learning Score | Last Active |
        |-------|----------|-------|---------------|-------------|
        | skill | N entries | acc, les, dec | x.x/5 | date |
        </output>
      </section>

      <section name="building">
        <output>
        Building
        | Skill | Evidence | Missing Types | Learning Score | Priority |
        |-------|----------|--------------|---------------|----------|
        | skill | N entries | missing types | x.x/5 | why it matters |
        </output>
      </section>

      <section name="gap">
        <output>
        Gap
        | Skill | Evidence | Learning Score | Why It Matters |
        |-------|----------|---------------|----------------|
        | skill | N entries | x.x/5 or -- | relation to goals |
        </output>
      </section>

      <section name="blind-spot">
        <output>
        Blind Spot
        | Skill | Relevance | Suggested First Step |
        |-------|-----------|---------------------|
        | skill | why needed for target role | explore or bridge suggestion |
        </output>
      </section>
    </template>
  </step>

  <step id="prioritized-recommendations" number="7">
    <description>Prioritized Recommendations</description>
    <action>Generate a prioritized list of actions:</action>

    <template name="action-list">
      <output>
      Recommended Actions (highest impact first)

      1. [Gap/Blind Spot skill] -- `/explore <topic>` to establish baseline understanding
      2. [Building skill] -- `/quiz --topic <topic>` to test retention and find specific weak spots
      3. [Gap skill] -- `/bridge <topic> --from <related strong skill>` to build from existing knowledge
      4. [Evidence gap] -- `/thing-i-did` to log a `<missing evidence type>` entry for skill
      </output>
    </template>
  </step>

  <step id="offer-next-steps" number="8">
    <description>Offer Next Steps</description>
    <completion-message>
      <ask-user-question>
        <question>What would you like to do?</question>
        <option>Explore a gap topic -- deep-dive into an area I'm weak in</option>
        <option>Quiz a building area -- test what I'm developing</option>
        <option>Bridge a gap -- build a learning plan from existing knowledge</option>
        <option>Done for now -- I'll review the report</option>
      </ask-user-question>
    </completion-message>
  </step>

</steps>
