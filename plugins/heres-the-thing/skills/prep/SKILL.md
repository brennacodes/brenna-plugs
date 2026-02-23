---
name: prep
description: "Generate or refine deliverables for an existing campaign goal, run Q&A prep sessions, and advance prep level. Use when user says 'prep for', 'practice my pitch', 'refine my strategy', 'run me through it'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Task
argument-hint: "<campaign-id> [goal-id] [--qa]"
---

<purpose>
Generate or refine deliverables for a specific goal in an existing campaign. Computes prep level from current state, diffs against what should exist, and recommends next actions. Includes interactive Q&A prep sessions where the system plays devil's advocate.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.</if>

    2. Read `<home>/.things/heres-the-thing/deliverable-types/index.json`
    </load-config>
  </step>

  <step id="select-campaign" number="2">
    <description>Select Campaign and Goal</description>

    <if condition="campaign-id-in-arguments">
    Read `<home>/.things/heres-the-thing/campaigns/<campaign-id>/campaign.json`.
    </if>

    <if condition="no-campaign-id">
    Scan `<home>/.things/heres-the-thing/campaigns/*/campaign.json`. List active campaigns.
    Use AskUserQuestion to select one.
    </if>

    <if condition="goal-id-in-arguments">
    Select the matching goal from campaign.goals.
    </if>

    <if condition="no-goal-id-and-multiple-goals">
    Use AskUserQuestion to select a goal.
    </if>

    <if condition="single-goal">
    Auto-select the only goal.
    </if>
  </step>

  <step id="compute-prep-level" number="3">
    <description>Compute Prep Level</description>

    Scan the campaign directory to determine current state:

    <phase name="check-strategy" number="1">
    Check `campaigns/<id>/strategy/` for strategy briefs matching `<goal-id>-*.md`.
    </phase>

    <phase name="check-artifacts" number="2">
    Check `campaigns/<id>/artifacts/` for deliverables matching `<goal-id>-*.md`.
    </phase>

    <phase name="check-qa" number="3">
    Check `campaigns/<id>/artifacts/` for Q&A session results matching `<goal-id>-qa-session-*.md`.
    </phase>

    <phase name="determine-level" number="4">
    Compute prep level:

    | State | Prep Level |
    |---|---|
    | No strategy brief exists | `zero` |
    | Strategy brief exists | `strategized` |
    | Some deliverables generated | `drafted` |
    | Q&A prep session completed | `rehearsed` |
    </phase>
  </step>

  <step id="diff-state" number="4">
    <description>Diff Against Expected State</description>

    <phase name="expected-deliverables" number="1">
    Walk the decision tree from `/pitch` to determine what deliverables SHOULD exist for this goal based on current campaign state (stakes, medium, audience, time).
    </phase>

    <phase name="compare" number="2">
    Compare expected vs. actual:
    - Which deliverables are missing?
    - Has the strategy brief's inputs changed? (new outcomes logged, audience data updated from other plugins, precedent added)
    - Has target_date shifted? (recalculate time available)
    </phase>

    <phase name="check-updates" number="3">
    Check for external updates:
    - Read `<home>/.things/shared/people/` profiles referenced in audience -- any updates since last strategy brief?
    - Check for new outcomes in this campaign since last brief
    - Check professional-profile.json for updated strengths/weaknesses
    </phase>
  </step>

  <step id="recommend-actions" number="5">
    <description>Recommend Actions</description>

    Present the current state and recommendations:

    ```
    Campaign: <id>
    Goal: <goal-id> -- <description>
    Target: <date> (<time remaining>)
    Prep level: <level>

    Current state:
      Strategy brief: <exists/missing> (last version: <date>)
      Deliverables: <n> of <expected> generated
      Q&A sessions: <n> completed

    Recommendations:
    <list of recommended actions based on diff>
    ```

    <if condition="missing-deliverables">
    - Generate missing deliverables: <list>
    </if>

    <if condition="stale-brief">
    - Regenerate strategy brief (inputs have changed: <what changed>)
    </if>

    <if condition="all-current">
    - Run Q&A prep session to advance to `rehearsed`
    - Refine existing materials
    </if>

    Use AskUserQuestion:
    <options>
    - Generate missing deliverables
    - Regenerate strategy brief with updated inputs
    - Run Q&A prep session
    - Refine a specific deliverable
    - View current materials
    </options>
  </step>

  <step id="generate-missing" number="6">
    <description>Generate Missing Deliverables</description>

    <if condition="user-chose-generate">
    For each missing deliverable, follow the same generation logic as `/pitch` Step 8.
    Read the most recent strategy brief as input. Generate and write to the artifacts directory.
    </if>

    <if condition="user-chose-regenerate-brief">
    Generate a new timestamped strategy brief incorporating updated inputs.
    Include a `## Changes from previous` section at the top listing what changed.
    </if>
  </step>

  <step id="qa-session" number="7">
    <description>Q&A Prep Session</description>

    <if condition="user-chose-qa-or-qa-flag">

    <phase name="setup-session" number="1">
    Read the most recent strategy brief and all deliverables for this goal.
    Read audience data (person profiles, segment profiles).
    Check if a think-like profile exists for anyone in the audience.

    Determine session depth from time available:
    | Time | Format |
    |---|---|
    | ≤5 min | 3 rapid-fire objections, brief feedback, results summary |
    | ~15 min | 5-7 questions with follow-ups, detailed feedback per response |
    | Full session | Comprehensive simulation including opening, Q&A, and closing |
    | Extended | Multiple rounds with different audience perspectives |
    </phase>

    <phase name="run-session" number="2">
    **Play devil's advocate from the audience's perspective.**

    <if condition="think-like-profile-exists">
    Read the think-like profile to model audience perspective more deeply.
    </if>

    For each round:

    1. Present a pointed question or objection based on:
       - Audience's typical concerns and decision criteria
       - Known objections from audience profile
       - Weak points identified in the strategy brief
       - Gaps in the user's self-assessment (known weaknesses)

    2. Wait for user's response.

    3. Provide feedback:
       - Did the response address the concern?
       - Was the framing effective for this audience?
       - Suggested improvements or alternative phrasings
       - Rate: strong / adequate / needs work

    4. Continue to next question.

    <constraint>Ask questions one at a time. Wait for the user's response before providing feedback and moving to the next question. This is interactive, not batch.</constraint>
    </phase>

    <phase name="session-results" number="3">
    After all rounds, produce a results overview:

    <output-path>`<home>/.things/heres-the-thing/campaigns/<campaign-id>/artifacts/<goal-id>-qa-session-<timestamp>.md`</output-path>

    ```markdown
    # Q&A Prep Session Results
    ## Goal: <goal-id>
    ## Date: <timestamp>
    ## Depth: <session depth>

    ## Summary
    - Questions asked: <n>
    - Strong responses: <n>
    - Adequate responses: <n>
    - Needs work: <n>

    ## Points That Are Solid
    - <point>: <why it's strong>

    ## Points That Need Work
    - <point>: <what was weak, suggested improvement>

    ## Objections Handled Well
    - <objection>: <user's effective response>

    ## Objections Fumbled
    - <objection>: <what happened, better approach>

    ## Recommended Updates
    - [Strategy brief]: <suggested changes>
    - [Meeting prep doc]: <suggested additions>
    - [Objection map]: <new entries to add>
    ```

    <rule>Offer to apply recommended updates to existing deliverables.</rule>
    </phase>
    </if>
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
    Prep session complete for `<campaign-id>` / `<goal-id>`.

    Prep level: <previous> → <new>
    Materials updated:
    <list of files written or updated>

    Next steps:
    <if condition="not-rehearsed">- `/heres-the-thing:prep <campaign-id> --qa` -- run a Q&A prep session</if>
    - `/heres-the-thing:outcome <campaign-id>` -- log what happened after delivery
    </completion-message>
  </step>

</steps>
