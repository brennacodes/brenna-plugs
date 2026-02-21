---
name: thing-i-did
description: "Log a professional experience - accomplishments, lessons, expertise, decisions, influence, or insights. Extracts context from arguments or conversation history for fast capture, or runs a full guided interview when context is sparse."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[description, pasted context, or --interview]"
---

<purpose>
Walk the user through capturing a professional experience with enough depth and structure to be useful for resumes, interviews, and blog posts later. When the user provides rich context (pasted transcript, decision summary, or detailed description), extract fields automatically and confirm before writing. When context is sparse, fall back to a full guided interview that adapts based on the evidence type.
</purpose>

<steps>

  <step id="load-configuration" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/setup-htt` first." Then stop.<exit /></if>

      <read path="<home>/.things/shared/professional-profile.json" output="profile" />

      <read path="<home>/.things/i-did-a-thing/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-idat` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="load-professional-context" number="2">
    <description>Load Professional Context</description>

    <action>Read the professional profile from `<home>/.things/shared/professional-profile.json` -- the `current_role`, `target_roles`, `career_direction`, `building_skills`, and `aspirational_skills` fields. This context shapes which follow-up questions to ask and how to tag the entry.</action>

    <action>Read default tags from `<home>/.things/i-did-a-thing/preferences.json`.</action>
  </step>

  <step id="assess-available-context" number="3">
    <description>Assess Available Context</description>

    Determine whether there is enough context to take a fast path (extract and confirm) or whether a full interview is needed.

    <substep name="check-interview-flag">
      <description>Check for Interview Flag</description>
      <if condition="interview-flag-set">Strip the flag and jump to Step 4 (full interview). Use any remaining text after the flag as the brief description / starting point.</if>
    </substep>

    <substep name="gather-context">
      <description>Gather Context</description>

      <action>Collect context from two sources:</action>
      - `$ARGUMENTS`: The text the user passed directly to the skill
      - Conversation history: Prior messages in the current session that describe a professional experience

      <if condition="no-relevant-context">Jump to Step 4 (full interview).</if>

      <constraint>
      What counts as relevant context:
      - Descriptions of work done, decisions made, problems solved, lessons learned, expertise applied, influence exercised, or patterns observed
      - Project/task specifics -- codebase names, team context, stakeholder interactions, timelines, outcomes
      </constraint>

      <constraint>
      What does NOT count:
      - Code debugging sessions or casual chat that isn't about a professional experience
      - Prior skill runs (like `/practice`) -- these are not themselves loggable events
      - Generic greetings or unrelated conversation
      </constraint>
    </substep>

    <substep name="extract-log-fields">
      <description>Extract Log Fields</description>

      <action>Attempt to extract all log fields from the combined context.</action>

      Required fields -- must be present or inferrable for the fast path:
      - `title` -- descriptive title for the entry
      - `evidence_type` -- accomplishment, lesson, expertise, decision, influence, or insight
      - `impact` -- major, notable, solid, or learning
      - `category` -- technical, leadership, communication, problem-solving, process, growth, expertise, decision-making, or influence
      - `skills_used` -- cross-reference against the user's `building_skills` and `aspirational_skills` from profile
      - Body section content -- the narrative sections for this evidence type (see the table in Step 9)

      Optional fields -- extract if present, skip if not:
      - `description` -- 1-2 sentence summary
      - `tags` -- searchable tags
      - `skills_developed` -- new skills learned or grown
      - `target_alignment` -- which professional targets this supports (from profile)
      - `role_at_time` -- the user's role when this happened
      - `team_or_org` -- team or organization context
      - `duration` -- how long this took
      - `metrics` -- quantifiable outcomes

      <constraint>Project/task context preservation: When the context references a specific project, codebase, tool, or task, capture that specificity in the body sections, in `team_or_org`, and in tags. Don't generalize away the details -- "redesigned bivvy's prompt routing system" is better than "improved a system."</constraint>

      <action>Classify each field as:</action>
      - **confident** -- clearly stated or directly quotable from the context
      - **inferrable** -- reasonably derivable from the context
      - **missing** -- not enough information to determine
    </substep>

    <substep name="decision-gate">
      <description>Decision Gate</description>

      <if condition="fast-path-eligible">
      Take the fast path (continue to "Present Summary"). Requires:
      - `evidence_type` is confident or inferrable, AND
      - At least 3 of the evidence type's body sections have confident content
      </if>

      <if condition="fast-path-not-eligible">Jump to Step 4 (full interview), carrying whatever was extracted as a head start so the user doesn't repeat themselves.</if>
    </substep>

    <substep name="present-summary">
      <description>Present Summary for Confirmation</description>

      <ask-user-question>
        <question>Show everything extracted as a structured summary:
        - Title, evidence type, impact, category
        - Each body section with a preview (first 1-2 sentences)
        - Skills used/developed
        - Tags (auto-generated)
        - Any optional fields that were extracted</question>
        <option>Looks good -- proceed to fill gaps (if any) or directly to tag review (Step 8)</option>
        <option-with-text-input>Some changes needed -- provide corrections</option-with-text-input>
        <option>Full interview instead -- jump to Step 4 with the extracted title as starting point</option>
      </ask-user-question>
    </substep>

    <substep name="fill-gaps">
      <description>Fill Genuine Gaps</description>

      <action>For each required field or body section still classified as missing, ask ONE focused question -- reuse the question text from the evidence-type interview in Step 6. Do not ask situational follow-ups on the fast path. After gaps are filled, proceed to Step 8 (tag review).</action>
    </substep>

    <if condition="multiple-loggable-events">Identify the primary one and mention the others. Offer to log the rest afterward (by running the skill again).</if>
  </step>

  <step id="start-interview" number="4">
    <description>Start the Interview</description>

    This is the full interview path -- used when context is sparse, when the user passes `--interview`, or when the user opts out of the fast path at the summary step.

    <if condition="partial-extraction-available">Use it as the starting point. Acknowledge what you already know: "I have some context already -- let me fill in the details." Skip questions whose answers are already confident.</if>

    <if condition="no-context-extracted">Ask the opening question:</if>

    <ask-user-question>
      <question>What's on your mind? Could be something you built, a lesson you learned, a topic you went deep on, a decision you shaped -- anything worth remembering.</question>
    </ask-user-question>
  </step>

  <step id="classify-evidence-type" number="5">
    <description>Classify the Evidence Type</description>

    <if condition="evidence-type-already-determined">Skip this step.</if>

    <action>After the user describes the headline, determine the type.</action>

    <ask-user-question>
      <question>What kind of thing is this?</question>
      <option>Something I accomplished -- built, shipped, fixed, improved, delivered</option>
      <option>A lesson I learned -- failure, surprise, mistake, hard-won insight</option>
      <option>Expertise I developed -- went deep on a topic, became the go-to person</option>
      <option>A decision I made -- weighed options, chose an approach, can explain why</option>
      <option>Something I influenced -- changed someone's mind, drove adoption, mentored</option>
      <option>A pattern or insight I noticed -- observation, thesis, perspective</option>
    </ask-user-question>

    <action>Map the selection to an `evidence_type` value: `accomplishment`, `lesson`, `expertise`, `decision`, `influence`, or `insight`.</action>
  </step>

  <step id="deep-dive-interview" number="6">
    <description>Conduct the Deep-Dive Interview</description>

    <constraint>Ask follow-up questions one at a time using AskUserQuestion. Adapt questions based on previous answers and the evidence type. The goal is to extract a rich, specific log entry. Skip any questions whose answers are already known from context assessment.</constraint>

    <phase name="accomplishment-interview" number="1">
    Accomplishment

    1. Context: "What was the situation or problem that led to this?"
    2. Action: "What specifically did you do? Walk me through your approach."
    3. Result: "What was the outcome? Be as specific as possible -- numbers, feedback, changes."
    4. Skills Used: Present a multi-select based on their `building_skills` + `aspirational_skills` from profile, plus an "Other" option: "Which skills did you use or develop?"

    Situational follow-ups (ask only when relevant):
    - If result mentions team: "What was your specific role vs. the team's contribution?"
    - If first time: "Was this the first time you did something like this? What did you learn?"
    - If involved decision: "What alternatives did you consider? Why did you choose this approach?"
    - If measurable impact: "Can you quantify the impact? (time saved, revenue, users affected, etc.)"
    - If involved leadership: "Who did you influence or lead? How?"
    - If involved technical work: "What was the technical approach? Any interesting challenges?"
    </phase>

    <phase name="lesson-interview" number="2">
    Lesson

    1. Situation: "What was the situation? Set the scene."
    2. Attempt: "What did you try? What was the plan or approach?"
    3. What went wrong: "What went wrong, or what surprised you?"
    4. What you'd do differently: "Knowing what you know now, what would you do differently?"
    5. Takeaway: "What did you take from this? How has it changed how you work?"
    6. Skills: Present skill multi-select: "Which skills does this lesson touch?"

    Situational follow-ups (ask only when relevant):
    - If sounds costly: "How costly was the mistake? Time, money, trust, momentum?"
    - If lesson applied: "Where have you applied this lesson since?"
    - If lesson is technical: "What was the technical root cause?"
    - If involved others: "How did the team handle it? Was there a post-mortem?"
    </phase>

    <phase name="expertise-interview" number="3">
    Expertise

    1. Domain: "What's the topic or domain?"
    2. How developed: "How did you develop this expertise? What was the journey?"
    3. Application: "How do you apply this knowledge day-to-day?"
    4. Teaching: "How have you shared or taught this to others?"
    5. Non-obvious: "What's something non-obvious about this area that most people get wrong?"
    6. Skills: Present skill multi-select: "Which skills are central to this expertise?"

    Situational follow-ups (ask only when relevant):
    - If teaches others: "What questions do people most often come to you with?"
    - If deep expertise: "What resources or experiences were most valuable in building this?"
    - If evolving area: "How is this area changing? What's your current edge?"
    </phase>

    <phase name="decision-interview" number="4">
    Decision

    1. Problem: "What was the problem or question you needed to resolve?"
    2. Options: "What options did you consider?"
    3. Evaluation: "How did you evaluate them? What were the tradeoffs, constraints, and priorities?"
    4. Choice: "What did you choose and why?"
    5. Outcome: "How did it play out? Would you make the same call again?"
    6. Skills: Present skill multi-select: "Which skills did this decision exercise?"

    Situational follow-ups (ask only when relevant):
    - If high stakes: "What was the blast radius if you got it wrong?"
    - If others disagreed: "Was there pushback? How did you handle it?"
    - If reversible decision: "Did you build in a way to reverse course if needed?"
    - If data involved: "What data or evidence informed your choice?"
    </phase>

    <phase name="influence-interview" number="5">
    Influence

    1. Status quo: "What was the existing state or direction before you got involved?"
    2. Your position: "What was your position or what change were you advocating for?"
    3. Advocacy: "How did you make your case? What tactics or approach did you use?"
    4. Outcome: "What happened? Did the change stick?"
    5. Reflection: "What would you do differently if you had to advocate for this again?"
    6. Skills: Present skill multi-select: "Which skills did you draw on?"

    Situational follow-ups (ask only when relevant):
    - If no formal authority: "Did you have formal authority here, or was this influence without authority?"
    - If data used for advocacy: "Did you use data, a prototype, or a pilot to make your case?"
    - If change took time: "How long did the change take to land? Was it gradual or a single moment?"
    - If involved mentoring: "How did the person or team grow from this?"
    </phase>

    <phase name="insight-interview" number="6">
    Insight

    1. Observation: "What did you observe or notice?"
    2. Where and how often: "Where did you see this? Was it a one-off or a pattern?"
    3. Thesis: "What's your thesis? What do you think is going on?"
    4. Evidence: "What evidence supports your thinking?"
    5. Recommendation: "What do you recommend based on this? Have you acted on it?"
    6. Skills: Present skill multi-select: "Which skills does this insight draw on?"

    Situational follow-ups (ask only when relevant):
    - If actionable insight: "Has anyone acted on this yet? What happened?"
    - If contrarian view: "Do others see this differently? What's the conventional view?"
    - If spans systems: "Does this pattern show up in other contexts too?"
    </phase>
  </step>

  <step id="classify-entry" number="7">
    <description>Classify the Entry</description>

    <if condition="from-fast-path">Impact and category are already set -- skip this step.</if>

    <ask-user-question>
      <question>What's the impact level?</question>
      <option>`major` -- significant outcome, career-defining, or organization-wide impact</option>
      <option>`notable` -- meaningful result, team-level impact, or skill breakthrough</option>
      <option>`solid` -- good work, worth remembering, builds on a pattern</option>
      <option>`learning` -- didn't go perfectly but taught you something valuable</option>
    </ask-user-question>

    <ask-user-question>
      <question>Category?</question>
      <option>`technical` -- built, fixed, or improved something technical</option>
      <option>`leadership` -- led, mentored, influenced, or organized people</option>
      <option>`communication` -- presented, wrote, advocated, or facilitated</option>
      <option>`problem-solving` -- diagnosed, analyzed, or resolved a complex issue</option>
      <option>`process` -- improved workflow, created standards, or drove efficiency</option>
      <option>`growth` -- learned something new, stretched into unfamiliar territory</option>
      <option>`expertise` -- built deep domain knowledge, became a resource</option>
      <option>`decision-making` -- evaluated tradeoffs, made judgment calls</option>
      <option>`influence` -- shaped others' decisions, advocated for change</option>
    </ask-user-question>
  </step>

  <step id="generate-tags" number="8">
    <description>Generate Tags</description>

    <if condition="from-fast-path">Tags are already generated -- present them for review rather than generating from scratch.</if>

    <action>
    Otherwise, auto-generate tags by combining:
    - User's `default_tags` from config
    - Skills mentioned in the interview
    - Category from classification
    - Evidence type
    - Any technologies or tools mentioned
    - Professional target alignment (from profile)
    </action>

    <ask-user-question>
      <question>Here are the generated tags. Add, remove, or modify them.</question>
      <option>Looks good</option>
      <option-with-text-input>Make changes</option-with-text-input>
    </ask-user-question>
  </step>

  <step id="compose-log-entry" number="9">
    <description>Compose the Log Entry</description>

    <write path="<home>/.things/i-did-a-thing/logs/<date>-<slugified-title>.md">

    <constraint>Use the format defined in `references/log-format.md`.</constraint>

    <constraint>
    The log must include:
    - Complete YAML frontmatter with all metadata (including `evidence_type`)
    - Structured body sections adapted to the evidence type (see below)
    - A "Resume Bullets" section with 2-3 pre-written bullet points in the type-appropriate format
    - An "Interview Talking Points" section with key points structured for the type
    - A "Blog Seed" section with a 1-2 sentence hook tailored to the type
    </constraint>

    <template name="body-sections">
    Body sections by evidence type:

    | Type | Sections |
    |------|----------|
    | Accomplishment | Context, Action, Result, Reflection |
    | Lesson | Situation, What I Tried, What Went Wrong, What I'd Do Differently, What I Took From It |
    | Expertise | The Domain, How I Developed It, How I Apply It, How I've Shared It, What's Non-Obvious |
    | Decision | The Problem, Options Considered, How I Evaluated Them, What I Chose and Why, How It Played Out |
    | Influence | The Status Quo, My Position, How I Advocated, What Happened, What I'd Do Differently |
    | Insight | What I Observed, Where and How Often, My Thesis, The Evidence, My Recommendation |
    </template>

    <template name="resume-bullets">
    Resume bullets by evidence type:

    | Type | Format |
    |------|--------|
    | Accomplishment | `ACTION VERB <what you did> by <how>, resulting in <measurable outcome>` |
    | Lesson | `Learned <X> from <Y>, now apply <Z> to <outcome>` |
    | Expertise | `Deep expertise in <X>, demonstrated through <Y>, enabling <Z>` |
    | Decision | `Evaluated <X, Y, Z>; chose <Z> based on <A, B, C>, resulting in <outcome>` |
    | Influence | `Drove adoption of <X> by <method>, resulting in <Y>` |
    | Insight | `Identified <pattern X>, proposed <Y>, leading to <Z>` |
    </template>

    <template name="interview-talking-points">
    Interview talking points by evidence type:

    | Type | Structure |
    |------|-----------|
    | Accomplishment | Situation - Task - Action - Result - Lessons |
    | Lesson | Situation - Mistake/Surprise - Learning - Application |
    | Expertise | Domain - Depth - Application - Teaching |
    | Decision | Problem - Options - Tradeoffs - Choice - Outcome |
    | Influence | Status Quo - Position - Advocacy - Outcome |
    | Insight | Observation - Evidence - Thesis - Recommendation |
    </template>

    <template name="blog-seed-hooks">
    Blog seed hooks by evidence type:

    | Type | Hook style |
    |------|-----------|
    | Accomplishment | Current engaging hook style |
    | Lesson | "The time I learned..." hook |
    | Expertise | "Everything I know about..." hook |
    | Decision | "Why I chose X over Y..." hook |
    | Influence | "How I convinced my team to..." hook |
    | Insight | "A pattern I keep seeing..." hook |
    </template>

    </write>
  </step>

  <step id="update-index-arsenal" number="10">
    <description>Update Index and Arsenal</description>

    <constraint>The heres-the-thing PostToolUse hook automatically dispatches `rebuild-data.py` via the registry after writing a log file, which regenerates `i-did-a-thing/index.json`, `i-did-a-thing/tags.json`, and all arsenal files from scratch. No manual index or arsenal updates are needed.</constraint>

    <if condition="hook-did-not-fire">The rebuild can be run manually:
      <command language="bash" tool="Bash">python3 <plugin_root>/scripts/rebuild-data.py $HOME/.things</command>
    </if>
  </step>

  <step id="handle-git-workflow" number="11">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Before committing, pull latest changes from the remote (if one exists) to avoid conflicts.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `<home>/.things/config.json` (`git.workflow`).</action>

      <if condition="workflow-ask">
        <ask-user-question>
          <question>Would you like to commit and push this log entry?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only -- commit without pushing</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-auto">Automatically `git add`, `git commit -m "log: <title>"`, and `git push`.</if>
      <if condition="workflow-manual">Tell the user the file has been saved and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="celebrate" number="12">
    <description>Celebrate</description>

    <completion-message>
    Logged! Here's what you captured:

    (Title) (`impact`, `evidence_type`)
    Tags: `tags`
    Skills: `skills`

    This is your Nth logged entry. (encouraging message based on count/streak)

    Resume bullets are ready in the log. Run `/practice` to practice talking about it in an interview.
    </completion-message>
  </step>

</steps>
