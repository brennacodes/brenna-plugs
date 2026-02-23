---
name: bridge
description: "Build a personalized learning plan that bridges from existing knowledge to a target topic, grounded in your actual experience"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<gap-topic> [--from <existing-strength>] [--timeline 1-week|2-weeks|1-month]"
---

<references>
  <reference path="references/learning-plan-framework.md" />
</references>

<purpose>
Build a concrete learning plan that bridges from what you already know to a gap topic. Plans are grounded in your arsenal evidence and include checkpoints using explore and quiz sessions.
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
    </load-config>
  </step>

  <step id="load-all-data" number="2">
    <description>Load All Data</description>
    <action>Read the following data files:</action>
    <read path="<home>/.things/i-did-a-thing/index.json" output="index" />
    <action>Read all files in `<home>/.things/i-did-a-thing/arsenal/` for skill evidence.</action>
    <read path="<home>/.things/what-do-you-know/knowledge-map.json" output="knowledge-map" />
    <read path="<home>/.things/what-do-you-know/progress.json" output="progress" />
    <substep name="load-recent-sessions">
      <command language="bash" tool="Bash">bash <plugin_root>/scripts/search-sessions.sh --recent 20</command>
    </substep>
  </step>

  <step id="identify-the-gap" number="3">
    <description>Identify the Gap</description>
    <if condition="gap-topic-provided">
      <action>Use the gap topic from the argument.</action>
    </if>
    <if condition="no-gap-topic">
      <ask-user-question>
        <question>What topic do you want to build a learning plan for?</question>
        <option-with-text-input>Free text -- e.g., "distributed consensus", "observability", "API design patterns"</option-with-text-input>
      </ask-user-question>
    </if>
    <if condition="recent-gaps-run">
      <action>Reference the gap report to suggest options.</action>
    </if>
  </step>

  <step id="find-the-bridge" number="4">
    <description>Find the Bridge</description>
    <if condition="from-provided">
      <action>Use that as the starting strength.</action>
    </if>
    <if condition="no-from-flag">
      <action>Search the arsenal and learning sessions for the closest existing knowledge:</action>
      <substep name="search-connections">
        <action>Search `<home>/.things/i-did-a-thing/index.json` for entries with skills that relate to the gap topic.</action>
        <action>Check `knowledge-map.json` for strong topics adjacent to the gap.</action>
        <action>Check learning session scores for related topics.</action>
      </substep>
    </if>

    <output>
    Bridging to: [gap topic]

    Starting from: [existing strength] -- based on [evidence]

    You understand [existing concept] from your experience with [project/entry from arsenal]. To get to [gap topic], you can build on that foundation:
    - [connection point 1]
    - [connection point 2]
    </output>

    <if condition="no-clear-connection">
      <output>
      I don't see a strong bridge from your existing knowledge. This is more of a greenfield learning area. The plan will start from fundamentals.
      </output>
    </if>
  </step>

  <step id="select-timeline" number="5">
    <description>Select Timeline</description>
    <if condition="timeline-provided">
      <action>Use the provided timeline.</action>
    </if>
    <if condition="no-timeline">
      <ask-user-question>
        <question>How much time do you want to invest?</question>
        <option>1 week -- focused sprint, ~30 min/day</option>
        <option>2 weeks -- steady pace, ~20 min/day (Recommended)</option>
        <option>1 month -- deep investment, ~15 min/day</option>
      </ask-user-question>
    </if>
  </step>

  <step id="build-the-plan" number="6">
    <description>Build the Plan</description>
    <action>Generate a structured learning plan with milestones and checkpoints. Reference `references/learning-plan-framework.md` for plan structure.</action>

    <constraint>
    Each plan section should:
    - Start from what the user already knows (grounded in arsenal)
    - Include exercises tied to actual projects where possible
    - Have checkpoints using quiz and explore skills
    - Build incrementally toward the target understanding
    </constraint>

    <template name="learning-plan">
      <output>
      Learning Plan: [Gap Topic]

      Starting from: [existing strength]
      Timeline: [duration]
      Goal: [what "understanding this topic" means concretely]
      </output>

      <phase name="foundation" number="1">
        <output>
        Phase 1: Foundation (Days 1-N)
        Objective: [what you'll understand after this phase]

        Building from: Your experience with [arsenal reference] gives you a foundation in [related concept].

        Activities:
        - [ ] Read/research: [specific resource or concept]
        - [ ] Reflect: How does [concept] relate to your [arsenal entry]?
        - [ ] Checkpoint: `/explore <sub-topic> --depth exploratory`
        </output>
      </phase>

      <phase name="depth" number="2">
        <output>
        Phase 2: Depth (Days N-M)
        Objective: [deeper understanding target]

        Activities:
        - [ ] Hands-on: [exercise tied to their projects]
        - [ ] Connect: [concept] <-> [related concept from their work]
        - [ ] Checkpoint: `/quiz --topic <topic> --count 5`
        </output>
      </phase>

      <phase name="integration" number="3">
        <output>
        Phase 3: Integration (Days M-End)
        Objective: [ability to apply and teach]

        Activities:
        - [ ] Apply: How would [concept] change your approach to [past project]?
        - [ ] Teach: Explain [concept] as if writing a blog post
        - [ ] Checkpoint: `/explore <topic> --depth deep`
        - [ ] Log it: `/thing-i-did` -- capture what you learned as an expertise entry
        </output>
      </phase>

      <section name="success-criteria">
        <output>
        Success Criteria
        - [ ] Can explain [topic] to a peer without notes
        - [ ] Can identify tradeoffs between [approach A] and [approach B]
        - [ ] Score >= 4/5 on quiz for [topic]
        </output>
      </section>
    </template>
  </step>

  <step id="write-the-plan" number="7">
    <description>Write the Plan</description>
    <write path="<home>/.things/what-do-you-know/study-plans/<topic-slug>.md">

      <schema name="study-plan-frontmatter">
      ```yaml
      ---
      topic: "<gap topic>"
      bridge_from: "<existing strength>"
      timeline: "<1-week|2-weeks|1-month>"
      created: <date>
      status: active
      phases:
        - name: "Foundation"
          target_date: "<date>"
          status: pending
        - name: "Depth"
          target_date: "<date>"
          status: pending
        - name: "Integration"
          target_date: "<date>"
          status: pending
      arsenal_references:
        - file: "<log filename>"
          relevance: "<bridge connection>"
      ---
      ```
      </schema>

      <constraint>Follow the frontmatter with the full plan content in markdown.</constraint>
    </write>
  </step>

  <step id="handle-git-workflow" number="8">
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
            <question>Would you like to commit and push this learning plan?</question>
            <option>Yes</option>
            <option>No</option>
          </ask-user-question>
        </if>
        <if condition="workflow-auto">
          <action>Automatically `git add` the study plan, `git commit -m "bridge: <topic>"`, and `git push`.</action>
        </if>
        <if condition="workflow-manual">
          <action>Tell the user the plan has been saved and they can commit when ready.</action>
        </if>
      </substep>
    </git-workflow>
  </step>

  <step id="offer-to-start" number="9">
    <description>Offer to Start</description>
    <completion-message>
      <ask-user-question>
        <question>Ready to start?</question>
        <option>Yes -- begin with an explore session on [topic]</option>
        <option>Not now -- I'll follow the plan on my own</option>
        <option>Adjust the plan -- I want to change something</option>
      </ask-user-question>
    </completion-message>
  </step>

</steps>
