---
name: pitch
description: "Create a positioning campaign -- guided interview builds campaign.json, strategy brief, and deliverables tailored to your audience, medium, and stakes. Use when user says 'pitch', 'I need to convince', 'position this', 'make them care'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Task
argument-hint: "[campaign-id] [--resume]"
---

<purpose>
Main workflow for heres-the-thing. Guided interview that builds a campaign: gathers subject, audience, goals, context, and precedent, then generates a strategy brief and deliverables based on the decision framework.

If `--resume` or an existing campaign-id is passed, loads the existing campaign and skips to prep level assessment (delegates to `/heres-the-thing:prep` logic).
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.</if>

    2. Check that `<home>/.things/heres-the-thing/` exists
       <if condition="htt-missing">Tell the user: "Run `/heres-the-thing:setup-htt` first." Then stop.</if>

    3. Read `<home>/.things/heres-the-thing/deliverable-types/index.json`

    4. Read `<home>/.things/shared/professional-profile.json` (for self-assessment defaults)

    5. <if condition="resume-flag-or-campaign-id">
       Read the existing campaign.json and skip to Step 8 (Generate).
       </if>
    </load-config>
  </step>

  <step id="gather-subject" number="2">
    <description>Step 1: What Are You Positioning?</description>

    Use AskUserQuestion:

    What are you positioning? This can be anything -- a tool you built, someone else's idea, a proposal, a promotion, a policy change, a request for resources, or something that doesn't exist yet.

    <phase name="subject-source" number="1">
    How do you want to describe it?
    <options>
    - Describe it now (free text)
    - Pull from an i-did-a-thing log
    - Reference a URL, file, or existing campaign
    - Describe something that doesn't exist yet (idea, aspiration)
    </options>

    <if condition="pull-from-idat">
    Search `<home>/.things/i-did-a-thing/index.json` for recent entries. Present top 10 by date. Let user select one.
    Extract title, description, tags, and store as `source_refs` entry with type `idat_log`.
    </if>

    <if condition="reference-url">
    Ask for the URL or file path. Store as `source_refs` entry with type `url`.
    </if>
    </phase>

    <phase name="subject-type" number="2">
    What kind of thing is this?

    Use AskUserQuestion (free text accepted):
    <options>
    - project -- Something you built or are building
    - idea -- A concept or proposal
    - request -- Asking for resources, approval, or support
    - tool -- A specific tool, library, or system
    </options>

    <rule>Accept any string -- these are suggestions, not an enum.</rule>
    </phase>

    <phase name="subject-familiarity" number="3">
    How well do you understand what you'll be communicating about?

    Use AskUserQuestion:
    <options>
    - expert -- I know this deeply, could answer any question
    - i_built_it -- I created it and know it well
    - familiar -- I understand the basics but may have gaps
    - new_to_me -- I'm still learning about this
    </options>

    <if condition="new_to_me-or-familiar">
    Flag: Subject research tasks will be included in the strategy brief. Confidence flags will mark assumptions that need verification.
    </if>
    </phase>
  </step>

  <step id="gather-goals" number="3">
    <description>Step 2: Who / Why / Where / When (Per Goal)</description>

    <constraint>A campaign can have multiple goals. Start with the first one, then ask if they want to add more.</constraint>

    For each goal, use AskUserQuestion to gather:

    <phase name="goal-basics" number="1">
    1. **Goal description**: What outcome are you trying to achieve?
    2. **Goal type**:
       <options>
       - short_term -- A specific near-term outcome
       - long_term -- A broader objective that may require multiple steps
       </options>
    3. **Target date**: When does this need to happen? (date or relative like "next Friday", "end of Q2")
    4. **Stakes**:
       <options>
       - low -- Nice to have, won't hurt if it doesn't land
       - medium -- Important but recoverable
       - high -- Critical outcome, significant consequences
       </options>
    </phase>

    <phase name="goal-audience" number="2">
    **Audience**: Who are you trying to reach?

    Use AskUserQuestion:
    <options>
    - A specific person (I'll name them)
    - An audience segment I've already defined
    - A new audience I'll describe now
    </options>

    <if condition="specific-person">
    Ask for their name. Check `<home>/.things/shared/people/` for an existing profile.
    <if condition="person-exists">Load their profile.</if>
    <if condition="person-not-found">
    Ask the user: "No profile found for <name>. I'll create one. What's their role/title?"
    Create a minimal profile in `<home>/.things/shared/people/<slug>/profile.md` and `index.json`.
    </if>

    Then ask:
    - **Receptiveness**: How receptive is this person to what you're proposing?
      <options>
      - champion -- They're already on your side
      - enthusiastic -- Open and supportive
      - neutral -- Will evaluate on merits
      - skeptical -- Needs convincing
      - hostile -- Actively against it
      </options>
    - **Familiarity**: How well do you know this person?
      <options>
      - well_known -- Worked together extensively
      - moderate -- Some interaction
      - low -- Barely know them
      - unknown -- Never met
      </options>
    - **Familiarity notes** (free text, optional): Anything else about your relationship or their preferences?
    </if>

    <if condition="existing-segment">
    List available segments from `<home>/.things/heres-the-thing/audiences/`. Let user select.
    Ask for receptiveness override (or use baseline).
    </if>

    <if condition="new-audience">
    Gather basic audience info inline (name, key concerns, decision criteria). Store in campaign only (not as a reusable segment).
    </if>

    <rule>A goal can have multiple audience entries (e.g., presenting to a group).</rule>
    Ask: "Is there anyone else in this audience for this goal?"
    </phase>

    <phase name="goal-medium" number="3">
    **Medium**: How will you deliver this?

    Use AskUserQuestion (free text accepted):
    <options>
    - meeting_1on1 -- One-on-one meeting
    - meeting_group -- Group meeting or presentation
    - email -- Written email
    - proposal -- Formal written proposal
    - talk -- Presentation or talk
    - cold_outreach -- Cold email or message
    - slack -- Slack message or thread
    </options>

    <rule>Accept any string -- these are suggestions, not an enum.</rule>

    **Delivery length** (if applicable): How long do you have? (e.g., "30 min", "1 page", "5 min lightning talk")
    </phase>

    <phase name="goal-deliverables" number="4">
    Based on the decision framework (see Step 7), the system will auto-select deliverables. But ask:

    Are there specific deliverables you want for this goal beyond the auto-selected ones?

    Show available types from the deliverable type registry.
    </phase>

    <phase name="more-goals" number="5">
    Use AskUserQuestion:
    Do you want to add another goal for this campaign?
    <options>
    - Yes -- add another goal
    - No -- that's all
    </options>

    <if condition="add-another">Loop back to the start of this step.</if>

    <rule>If a user defines both short-term and long-term goals, prompt them to link them: "Does <short-term-goal> roll up to <long-term-goal>?" Set `parent_goal` accordingly.</rule>
    </phase>
  </step>

  <step id="gather-context" number="4">
    <description>Step 3: Context</description>

    Use AskUserQuestion:

    1. **Situational context**: What's the landscape? What's happening that makes this timely? (free text)

    2. **Precedent**: Is there anything relevant from your past that informs this?
       <options>
       - Yes -- a previous campaign
       - Yes -- an i-did-a-thing log entry
       - Yes -- a URL, PR comment, or document
       - Yes -- multiple things (I'll list them)
       - No precedent
       </options>

       <if condition="has-precedent">
       For each precedent item:
       - Ask for the type and reference
       - Ask for a relevance note: "Why does this matter for this campaign?"
       Store as structured `precedent` array entries.
       </if>
  </step>

  <step id="self-assessment" number="5">
    <description>Step 4: Self-Assessment</description>

    Read `<home>/.things/shared/professional-profile.json`.

    <if condition="profile-has-strengths">
    Show the user their known strengths and ask:
    "These are the communication strengths I know about. Any to add or highlight for this campaign?"
    </if>

    <if condition="profile-missing-or-empty">
    Use AskUserQuestion:
    - What are you good at when communicating? (e.g., concrete examples, data-driven arguments, storytelling)
    - What do you tend to struggle with? (e.g., handling curveball questions, staying concise, reading the room)
    </if>
  </step>

  <step id="auto-tags" number="6">
    <description>Step 5: Tags</description>

    Auto-suggest tags from:
    - Subject type and description keywords
    - Goal descriptions
    - Audience names/segments
    - Medium types

    Present suggested tags and ask user to confirm/edit/add.
  </step>

  <step id="write-campaign" number="7">
    <description>Write Campaign</description>

    Generate a campaign ID from the subject title (lowercase, hyphens).

    ```bash
    mkdir -p <home>/.things/heres-the-thing/campaigns/<campaign-id>/strategy
    mkdir -p <home>/.things/heres-the-thing/campaigns/<campaign-id>/artifacts
    mkdir -p <home>/.things/heres-the-thing/campaigns/<campaign-id>/outcomes
    ```

    <output-path>`<home>/.things/heres-the-thing/campaigns/<campaign-id>/campaign.json`</output-path>

    Write the full campaign JSON following the schema from the design:

    ```json
    {
      "id": "<campaign-id>",
      "status": "active",
      "created": "<current_date>",
      "tags": ["<tags>"],
      "subject": {
        "title": "<title>",
        "type": "<type>",
        "familiarity": "<familiarity>",
        "description": "<description>",
        "source_refs": [<refs>]
      },
      "context": "<context>",
      "precedent": [<precedent_entries>],
      "goals": [
        {
          "id": "<goal-id>",
          "type": "<short_term|long_term>",
          "description": "<description>",
          "parent_goal": "<parent-id or null>",
          "target_date": "<date>",
          "status": "active",
          "stakes": "<low|medium|high>",
          "tags": ["<goal-tags>"],
          "audience": [<audience_entries>],
          "medium": "<medium>",
          "delivery_length": "<length or null>",
          "deliverables": ["<type_ids>"]
        }
      ]
    }
    ```
  </step>

  <step id="generate-deliverables" number="8">
    <description>Step 6: Generate Strategy Brief + Deliverables</description>

    For each goal in the campaign:

    <phase name="time-assessment" number="1">
    Calculate time available from `target_date` minus current date:
    - ≤15 min or same day: **urgent**
    - Hours to end of day: **short**
    - Days: **moderate**
    - Weeks+: **extended**
    </phase>

    <phase name="strategy-brief" number="2">
    **Always generate a strategy brief.**

    <output-path>`<home>/.things/heres-the-thing/campaigns/<campaign-id>/strategy/<goal-id>-<timestamp>.md`</output-path>

    Write the full 5-section strategy brief:

    ```markdown
    # Strategy Brief: <goal-id>
    ## Campaign: <campaign-id>
    ## Version: <timestamp>

    ---

    ## 1. Situation Analysis
    [Current landscape, timing, why now, relevant precedent from campaign.precedent]

    ## 2. Audience Profile
    [Who they are (from audience data), what they care about, known objections, decision criteria, receptiveness assessment]
    [If audience familiarity is low/unknown: include research tasks -- "Find out X about Y before proceeding"]

    ## 3. Subject Positioning
    [What you're pitching, key value props framed for THIS audience, differentiators vs. alternatives]
    [If subject.familiarity is new_to_me or familiar: add confidence flags -- "This framing assumes X -- verify before delivery"]
    [If audience is champion: frame as ammo they can use to advocate on your behalf]

    ## 4. Communication Strategy
    [Medium rationale, framing approach, opening hook, key messages in priority order]
    [Language to use, language to avoid]
    [If audience is skeptical/hostile: defensive framing, objection-first approach]

    ## 5. Execution Plan
    [Prep timeline based on time available, delivery approach, contingencies, follow-up plan, success metrics]

    ---

    ### Appendix A: Source Materials
    [Links to IDAT logs, URLs, reference docs from subject.source_refs]

    ### Appendix B: Precedent
    [Referenced precedent with relevance notes and lessons applied]
    ```

    <rule>Time modulates depth, not type. Urgent = concise sections. Extended = deep research and multiple iterations.</rule>
    </phase>

    <phase name="decision-tree" number="3">
    **Walk the additive decision tree for each goal.**

    Check each branch independently:

    1. **Medium branch**:
       - Sync medium (meeting, talk, presentation) → generate `meeting_prep_doc`
       - Async medium (email, proposal, document) → generate `artifact_draft` + any custom types in `deliverables`

    2. **Stakes branch**:
       - stakes >= high → generate `objection_map`, offer Q&A prep session

    3. **Audience receptiveness branch**:
       - skeptical/hostile → generate `objection_map` (if not already), reframe strategy defensively
       - champion → add "equip mode" section to strategy brief (ammo they can use to advocate)

    4. **Subject familiarity branch**:
       - new_to_me or familiar → add subject research tasks and confidence flags to brief

    5. **Audience familiarity branch**:
       - unknown or low → add audience research tasks to brief

    6. **Time branch**:
       - Days+ to prepare → generate `prep_plan`
       - If extended time + high stakes → offer rehearsal plan
    </phase>

    <phase name="medium-modifiers" number="4">
    **Apply medium-specific additions:**

    | Medium contains | Additional content |
    |---|---|
    | `talk` or `presentation` | Add slide outline, timing breakdown, transition phrases to artifacts |
    | `proposal` | Add executive summary section, decision framework for reader |
    | `cold_outreach` or `cold_email` | Add subject line options, follow-up sequence (day 3, day 7) |
    | `meeting_group` | Add role-specific talking points per audience member |
    </phase>

    <phase name="write-deliverables" number="5">
    For each deliverable determined by the tree walk:

    <if condition="builtin-type">
    Generate the deliverable directly based on the strategy brief and campaign context.
    Write to `<home>/.things/heres-the-thing/campaigns/<campaign-id>/artifacts/<goal-id>-<type-id>-<timestamp>.md`
    </if>

    <if condition="custom-type">
    Use the Task tool to launch the deliverable-agent subagent with:
    - campaign_path
    - goal_id
    - type_id
    - strategy_brief_path
    </if>
    </phase>

    <phase name="always-offer" number="6">
    After generating deliverables, always offer:
    - `follow_up_template` (if the goal has next_steps potential)
    - Any registered custom deliverable types not already generated
    - Q&A prep session (via `/heres-the-thing:prep`)
    </phase>
  </step>

  <step id="summary" number="9">
    <description>Summary</description>

    <completion-message>
    Campaign created: `<campaign-id>`

    Subject: <title>
    Status: active
    Tags: <tags>

    Goals:
    <for each goal>
      <goal-id> (<type>) -- <description>
        Target: <date> (<time_available>)
        Audience: <audience summary>
        Medium: <medium>
        Stakes: <stakes>
        Deliverables generated:
          - strategy/<goal-id>-<timestamp>.md (strategy brief)
          - artifacts/<goal-id>-<type>-<timestamp>.md (for each)

    </for>

    Next steps:
    - `/heres-the-thing:prep <campaign-id>` -- refine deliverables or run Q&A prep
    - `/heres-the-thing:outcome <campaign-id>` -- log what happened after delivery
    - `/heres-the-thing:review` -- analyze patterns across campaigns
    </completion-message>
  </step>

</steps>
