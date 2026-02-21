---
name: prep-for
description: "Build a company-specific interview preparation plan with value mapping, stage walkthroughs, and targeted practice recommendations"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
argument-hint: "<company: amazon|google|meta|custom> [--role <target role>] [--level <level>]"
---

<references>
  - references/prep-strategy.md
</references>

<purpose>
Generate a tailored preparation plan for a specific company's interview process, mapping the user's arsenal to company values and identifying gaps.
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

  <step id="load-company-profile" number="2">
    <description>Load Company Profile</description>

    <if condition="company-provided">
      <read path="<home>/.things/shared/companies/<company>.yaml" output="company-profile" />
    </if>

    <if condition="no-company-specified">
      <ask-user>
      Which company are you preparing for?

      <options>
      - Amazon
      - Google
      - Meta
      - Custom -- I have a job listing or company info to share
      </options>
      </ask-user>
    </if>

    <if condition="custom-selected">
      <action>Ask the user to paste a job listing or company information. Use it to build an ad-hoc company profile, referencing `references/prep-strategy.md` for structure.</action>
    </if>
  </step>

  <step id="determine-role-and-level" number="3">
    <description>Determine Target Role and Level</description>

    <if condition="role-and-level-provided">
      <action>Use the provided `--role` and `--level`.</action>
    </if>

    <if condition="no-role-or-level">
      <action>Check the user's profile for `target_roles`.</action>
    </if>

    <if condition="role-still-unclear">
      <ask-user>
      What role and level are you targeting?
      (Free text -- e.g., "Senior Software Engineer" or "Staff Engineer, L6")
      </ask-user>
    </if>

    <action>Map the stated level to the company's `level_expectations` if available.</action>
  </step>

  <step id="load-arsenal-and-sessions" number="4">
    <description>Load Arsenal and Session History</description>

    <action>Read all arsenal files and session history. This powers the gap analysis.</action>
  </step>

  <step id="map-arsenal-to-values" number="5">
    <description>Map Arsenal to Company Values</description>

    <for-each item="value" source="company-values">

      <substep name="identify-signals">
        <description>Identify the value's `interview_signals` and `question_themes`.</description>
      </substep>

      <substep name="search-arsenal">
        <description>Search arsenal files for entries that demonstrate these signals, considering all evidence types.</description>
      </substep>

      <substep name="search-sessions">
        <description>Search session history for relevant question answers.</description>
      </substep>

      <substep name="classify-coverage">
        <description>Classify each value's coverage.</description>

        <rubric>
        - Strong: Multiple arsenal entries with high relevance + strong session scores, with diverse evidence types
        - Partial: Some evidence but gaps in depth, variety, or evidence type diversity
        - Gap: Little or no evidence in arsenal or sessions
        </rubric>
      </substep>

    </for-each>

    <constraint>When matching, consider which evidence types are most relevant to each value:
    - Values about learning, adaptability, resilience -> `lesson` entries
    - Values about technical depth, expertise -> `expertise` entries
    - Values about judgment, ownership -> `decision` entries
    - Values about influence, leadership, mentorship -> `influence` entries
    - Values about vision, innovation, curiosity -> `insight` entries
    - Values about delivery, results, bias for action -> `accomplishment` entries
    </constraint>

    <template name="value-alignment-table">

    > **[Company] Values Alignment**
    >
    > | Value | Status | Evidence | Types | Gap |
    > |-------|--------|----------|-------|-----|
    > | <value> | Strong/Partial/Gap | <best arsenal entry> | <evidence types present> | <what's missing> |

    </template>
  </step>

  <step id="stage-preparation-guide" number="6">
    <description>Stage-by-Stage Preparation Guide</description>

    <for-each item="stage" source="company-interview-process">

      <template name="stage-guide">

      > **Stage: [Stage Name]** ([format], [duration] min)
      >
      > What they're evaluating: <evaluation_focus>
      > Your interviewer type: <persona role>
      >
      > Your readiness: <based on mock/practice session scores for this stage>
      >
      > Preparation checklist:
      > - [ ] Prepare [N] stories that demonstrate <values tested in this stage>
      > - [ ] Practice with [persona] persona: `/practice --persona <persona>`
      > - [ ] Run a mock for this stage: `/mock <company> --stage <stage>`
      >
      > Key stories to prepare: (from arsenal)
      > - <story from arsenal that maps to this stage's focus>
      >
      > Anti-patterns to avoid: (from company values)
      > - <anti-pattern from company profile>

      </template>

    </for-each>
  </step>

  <step id="question-prediction" number="7">
    <description>Question Prediction</description>

    <action>Based on company values and target level, predict likely questions.</action>

    <template name="predicted-questions">

    > Questions to Expect
    >
    > High probability (directly maps to company values):
    > - "<question>" -- tests <value>
    > - "<question>" -- tests <value>
    >
    > Medium probability (common at this level):
    > - "<question>" -- tests <skill>
    >
    > Curveball potential (bar raiser / unique to this company):
    > - "<question>" -- tests <unusual skill or value>

    </template>
  </step>

  <step id="build-timeline" number="8">
    <description>Build Preparation Timeline</description>

    <ask-user>
    When is your interview?

    <options>
    - This week
    - Next week
    - 2-4 weeks out
    - 1+ month out
    - Not scheduled yet
    </options>
    </ask-user>

    <template name="preparation-plan">

    > Preparation Plan: [Company] [Role] -- [Timeline]
    >
    > Week 1:
    > - Day 1-2: Log any unlogged entries that map to [company] values -- consider what evidence types you're missing (e.g., "For 'Learn and Be Curious,' log an expertise or lesson entry, not just an accomplishment")
    > - Day 3-4: Practice [weakest category] with [persona] (2-3 questions/day)
    > - Day 5: Mock [first stage] round
    >
    > Week 2: (if applicable)
    > - Continue practice focus areas
    > - Mock [next stage] round
    > - Review progress and adjust
    >
    > [etc.]

    </template>
  </step>

  <step id="write-prep-plan" number="9">
    <description>Write Preparation Plan</description>

    <write path="<home>/.things/what-did-you-do/<company>-prep-plan.md">
      <schema name="prep-plan-frontmatter">
      ```yaml
      ---
      company: "<company>"
      target_role: "<role>"
      target_level: "<level>"
      interview_date: "<date or null>"
      created: <today>
      values_coverage: <strong>/<total>
      stage_readiness:
        <stage>: <ready|developing|gap>
      arsenal_gaps:
        - "<skill or value>"
      ---
      ```
      </schema>
    </write>
  </step>

  <step id="git-workflow" number="10">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Based on the `git_workflow` setting (from config.json):</action>

      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion -- "Would you like to commit and push this prep plan?"</ask-user>
      </if>
      <if condition="workflow-auto">
        <action>Automatically `git add` the prep plan, `git commit -m "prep: <company>"`, and `git push`.</action>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user the prep plan has been saved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="offer-next-steps" number="11">
    <description>Offer Next Steps</description>

    <ask-user>
    Where do you want to start?

    <options>
    - Log entries for my biggest gaps
    - Practice my weakest value area
    - Run a mock for the first stage
    - Review my full readiness
    - Done for now -- I'll follow the plan
    </options>
    </ask-user>
  </step>

</steps>
