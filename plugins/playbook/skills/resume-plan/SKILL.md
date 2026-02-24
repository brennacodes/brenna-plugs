---
name: resume-plan
description: "Resume implementing a plan - Claude picks up where you left off by reading the plan, latest review, and current branch state, then works through the next actionable items."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, LSP, AskUserQuestion
argument-hint: "<plan>"
---

<purpose>
Resume implementing a plan from where you left off. Reads the plan, finds the most recent review (if any), analyzes the current branch state, determines what's been done vs. what's next, and begins working on the next actionable item.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.<exit /></if>

      <read path="<home>/.things/playbook/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-pb` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="find-plan" number="2">
    <description>Find Plan</description>

    <action>Search `<home>/.things/playbook/plans/` for a plan matching `$ARGUMENTS`.</action>
    - Try exact filename match
    - Then slug match
    - Then content search

    <if condition="not-found">
      <action>List available plans. Let user pick.</action>
    </if>

    <read path="<home>/.things/playbook/plans/<plan-slug>.md" output="plan" />
  </step>

  <step id="find-latest-review" number="3">
    <description>Find Latest Review</description>

    <action>Search `<home>/.things/playbook/reviews/` for reviews referencing this plan (check `plan_ref` in frontmatter). Sort by date, take the most recent.</action>

    <if condition="review-found">
      <read path="<home>/.things/playbook/reviews/<latest-review>.md" output="review" />
    </if>
  </step>

  <step id="analyze-branch" number="4">
    <description>Analyze Current Branch State</description>

    <command language="bash" tool="Bash">git rev-parse --abbrev-ref HEAD</command>
    <command language="bash" tool="Bash">git log --oneline main..HEAD 2>/dev/null | head -20</command>
    <command language="bash" tool="Bash">git diff main..HEAD --stat 2>/dev/null</command>
  </step>

  <step id="determine-progress" number="5">
    <description>Determine Progress</description>

    <if condition="review-exists">
      <action>Use the review's Done and Actionable sections to determine progress. Cross-reference with any new commits since the review date.</action>
    </if>

    <if condition="no-review">
      <action>Run a quick implicit review: compare plan items against branch changes. Classify as done or actionable without the full interview loop.</action>
    </if>
  </step>

  <step id="present-resumption" number="6">
    <description>Present Resumption Summary</description>

    <output>
    ## Resuming: <plan title>

    **Branch**: `<branch>` (<N commits ahead of main>)

    ### Done (<N>)
    <bulleted list of completed items>

    ### Next Up (<N remaining>)
    1. <first actionable item> -- <brief description of what's needed>
    2. <second actionable item>
    ...

    Starting with item 1.
    </output>
  </step>

  <step id="implement" number="7">
    <description>Begin Implementation</description>

    <action>Start working on the first actionable item. Use all available tools (Read, Write, Edit, Bash, Glob, Grep, LSP) to implement.</action>

    <constraint>After completing each item, briefly note what was done and move to the next actionable item. Offer to update the review doc as items are completed.</constraint>

    <constraint>If implementation is blocked (missing context, unclear requirements, dependency issues), stop and ask the user via AskUserQuestion rather than guessing.</constraint>
  </step>

  <step id="offer-review-update" number="8">
    <description>Offer Review Update</description>

    <ask-user-question>
      <question>Would you like me to update the review document with today's progress?</question>
      <option label="Yes">Update the review with items completed today</option>
      <option>No -- I'll run a fresh review later</option>
    </ask-user-question>

    <if condition="yes">
      <action>Update the review document: move completed items to Done, update counts, update status.</action>
    </if>
  </step>

</steps>
