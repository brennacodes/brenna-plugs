---
name: progress
description: "Show progress dashboard for a specific plan or all active plans - done/actionable counts, latest review dates, branch status, and quick action suggestions."
disable-model-invocation: false
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[plan]"
---

<purpose>
Show a progress dashboard for active plans. When given a specific plan, show detailed item-level progress. When run without arguments, show an overview of all non-completed plans with progress bars and status summaries.
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

      <read path="<home>/.things/playbook/index.json" output="index" />
    </load-config>
  </step>

  <step id="determine-scope" number="2">
    <description>Determine Scope</description>

    <if condition="plan-argument-provided">
      <action>Find the specific plan and show detailed view.</action>
    </if>

    <if condition="no-argument">
      <action>Show overview of all non-completed plans.</action>
    </if>
  </step>

  <step id="gather-progress-data" number="3">
    <description>Gather Progress Data</description>

    <action>For each plan in scope:</action>

    1. Read plan frontmatter (status, project, date)
    2. Find the most recent review from `playbook/reviews/` that references this plan (match on `plan_ref`)
    3. Extract `done_count` and `actionable_count` from the review
    4. If `project` field has a path, check branch status:
       <command language="bash" tool="Bash">git -C <project-path> rev-parse --abbrev-ref HEAD 2>/dev/null</command>
       <command language="bash" tool="Bash">git -C <project-path> log --oneline -1 2>/dev/null</command>
  </step>

  <step id="display-overview" number="4">
    <description>Display Overview (all plans)</description>

    <if condition="overview-mode">
      <output>
      Active Plans
      ─────────────────────────────────────────
      <plan-slug>              <status>    <progress-bar>  <done>/<total> done  (<actionable> actionable)
        └─ Last review: <date> | Branch: <branch or "none detected">

      <plan-slug>              <status>    <progress-bar>  Not reviewed yet
        └─ Imported: <date> | No branch detected
      ...
      </output>

      <constraint>
      Progress bar format: Use block characters to show proportion done.
      - `██████░░░░` for 6/10 done
      - `░░░░░░░░░░` for 0 done or not reviewed
      - `██████████` for all done
      </constraint>

      <if condition="no-active-plans">
        <action>Tell the user: "No active plans. Import one with `/capture-plan <thing>` or `/import-pb`."</action>
      </if>
    </if>
  </step>

  <step id="display-detail" number="5">
    <description>Display Detail (single plan)</description>

    <if condition="detail-mode">
      <action>Read the plan content. If a review exists, show each item with its done/actionable status.</action>

      <output>
      ## <plan title>
      Status: `<status>` | Last reviewed: <date or "never">
      Branch: `<branch>` | Project: `<project or "none">`

      ### Progress (<done>/<total>)
      <progress-bar>

      ### Items
      - [x] <done item 1>
      - [x] <done item 2>
      - [ ] <actionable item 1> -- <what's needed>
      - [ ] <actionable item 2> -- <what's needed>
      </output>
    </if>
  </step>

  <step id="offer-actions" number="6">
    <description>Offer Quick Actions</description>

    <if condition="has-actionable-items">
      <ask-user-question>
        <question>What would you like to do?</question>
        <option label="Resume implementation">Start working on the next actionable item</option>
        <option label="Run a fresh review">Review the current branch against the plan</option>
        <option label="Nothing">Just checking progress</option>
      </ask-user-question>
    </if>

    <if condition="all-done">
      <ask-user-question>
        <question>All items are done! What would you like to do?</question>
        <option label="Mark as completed">Update plan status to "completed"</option>
        <option label="Run a final review">Verify everything before closing</option>
        <option label="Nothing">Just checking</option>
      </ask-user-question>
    </if>
  </step>

</steps>
