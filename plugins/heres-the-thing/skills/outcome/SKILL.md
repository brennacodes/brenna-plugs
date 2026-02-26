---
name: outcome
description: "Log what happened after delivering a pitch -- capture results, reflections, and push learnings back to audience profiles and professional profile. Use when user says 'log outcome', 'how did it go', 'it went well/badly'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<campaign-id> [goal-id]"
---

<purpose>
Log the outcome of a delivered pitch. Captures what happened, what resonated, what didn't, user reflections, and next steps. Pushes learnings back to audience profiles (in shared/people/) and the professional profile. Updates goal status.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>
    </load-config>
  </step>

  <step id="select-campaign" number="2">
    <description>Select Campaign and Goal</description>

    <if condition="campaign-id-in-arguments">
    Read `<home>/.things/heres-the-thing/campaigns/<campaign-id>/campaign.json`.
    </if>

    <if condition="no-campaign-id">
    Scan `<home>/.things/heres-the-thing/campaigns/*/campaign.json`. List active campaigns with goals that have status `active` or `delivered`.
    Use AskUserQuestion to select one.
    </if>

    <if condition="goal-id-in-arguments">
    Select the matching goal.
    </if>

    <if condition="no-goal-id-and-multiple-goals">
    Use AskUserQuestion to select a goal.
    </if>

    <if condition="single-active-goal">
    Auto-select it.
    </if>

    Show the goal summary: description, audience, medium, target date, current status.
  </step>

  <step id="gather-outcome" number="3">
    <description>Gather Outcome</description>

    <phase name="result" number="1">
    Use AskUserQuestion:

    How did it go?
    <options>
    - Succeeded -- got what I wanted
    - Approved with conditions -- partial success
    - Deferred -- they want to think about it / come back later
    - Pivoted -- conversation went a different direction
    - Failed -- didn't land
    </options>
    </phase>

    <phase name="narrative" number="2">
    Use AskUserQuestion (free text):

    What happened? Give me the story. (Brief narrative of what occurred)
    </phase>

    <phase name="what-landed" number="3">
    Use AskUserQuestion (free text):

    What resonated? What points or framings landed well? (List the things that worked)
    </phase>

    <phase name="what-didnt" number="4">
    Use AskUserQuestion (free text):

    What didn't work? What fell flat or backfired? (List the things that didn't land)
    </phase>

    <phase name="reflections" number="5">
    Use AskUserQuestion (free text):

    Any personal reflections? ("I fumbled when...", "I nailed the...", "Next time I would...")
    </phase>

    <phase name="next-steps" number="6">
    Use AskUserQuestion (free text):

    What are the next steps? (Action items coming out of this)
    </phase>

    <phase name="goal-status" number="7">
    Use AskUserQuestion:

    Update goal status?
    <options>
    - active -- still in progress
    - delivered -- pitch delivered, waiting for result
    - succeeded -- achieved the goal
    - failed -- goal not achieved
    - pivoted -- goal changed direction
    </options>
    </phase>

    <phase name="tags" number="8">
    Auto-suggest outcome tags from: result type, audience names, medium, what_landed keywords.
    Ask user to confirm/edit.
    </phase>
  </step>

  <step id="write-outcome" number="4">
    <description>Write Outcome</description>

    <output-path>`<home>/.things/heres-the-thing/campaigns/<campaign-id>/outcomes/<goal-id>-<timestamp>.json`</output-path>

    ```json
    {
      "goal_id": "<goal-id>",
      "date": "<current_date>",
      "tags": ["<outcome-tags>"],
      "result": "<result>",
      "goal_status_update": "<new-status>",
      "narrative": "<narrative>",
      "what_landed": ["<items>"],
      "what_didnt": ["<items>"],
      "user_reflections": "<reflections>",
      "feedback_to_system": {
        "audience_updates": {},
        "user_skill_updates": {
          "strengths": [],
          "weaknesses": []
        }
      },
      "next_steps": ["<items>"]
    }
    ```
  </step>

  <step id="update-goal-status" number="5">
    <description>Update Goal Status</description>

    Read campaign.json. Update the goal's `status` field. Write the updated campaign.json.
  </step>

  <step id="feedback-loop" number="6">
    <description>Push Feedback to System</description>

    <phase name="audience-updates" number="1">
    For each person in the goal's audience:

    <if condition="person-has-shared-profile">
    Read `<home>/.things/shared/people/<person-ref>/profile.md`.

    Extract audience-specific learnings from `what_landed`, `what_didnt`, and `user_reflections`:
    - Communication style preferences observed
    - Decision-making patterns observed
    - Concerns that proved important
    - Effective/ineffective framings

    Append a new section to the person's profile.md:

    ```markdown
    ## Insights from <campaign-id> (<date>)
    - <learnings>
    ```

    Store in `feedback_to_system.audience_updates`:
    ```json
    {
      "<person-ref>": "<summary of learnings>"
    }
    ```
    </if>
    </phase>

    <phase name="user-skill-updates" number="2">
    Read `<home>/.things/shared/professional-profile.json`.

    Extract self-learnings from `what_landed` (→ strengths) and `what_didnt` + `user_reflections` (→ weaknesses).

    <if condition="new-strengths-identified">
    Add to `building_skills` if not already present. Store in `feedback_to_system.user_skill_updates.strengths`.
    </if>

    <if condition="new-weaknesses-identified">
    Store in `feedback_to_system.user_skill_updates.weaknesses` for reference by future strategy briefs.
    </if>

    <constraint>Only update professional-profile.json if there are clear, concrete skill insights. Don't add vague entries.</constraint>
    </phase>

    <phase name="update-outcome-feedback" number="3">
    Read the outcome file written in step 4. Update `feedback_to_system` with the actual updates made. Write the updated outcome file.
    </phase>
  </step>

  <step id="confirm" number="7">
    <description>Confirm</description>

    <completion-message>
    Outcome logged for `<campaign-id>` / `<goal-id>`.

    Result: <result>
    Goal status: <old> → <new>

    Feedback pushed:
    <if condition="audience-updated">- Audience insights added to <person-ref>'s profile</if>
    <if condition="skills-updated">- Professional profile updated with new skill insights</if>
    <if condition="no-feedback">- No system feedback pushed (no clear insights to record)</if>

    <if condition="has-next-steps">
    Next steps recorded:
    <list next_steps>
    </if>

    <if condition="parent-goal-exists">
    Parent goal `<parent-id>` has <n> of <total> sub-goals completed.
    </if>
    </completion-message>
  </step>

</steps>
