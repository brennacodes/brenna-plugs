---
name: review-against
description: "Review current branch work against a plan - classifies each plan item as done or actionable, resolves ambiguity through targeted questions, and writes a structured review with specific next steps. Optionally apply a think-like profile lens."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<plan> [as:<profile-name>] [--branch <name>]"
---

<purpose>
Review current branch work against a plan. Compare plan items against actual branch changes, classify each as done or actionable, resolve ambiguous items through an interview loop, and write a structured review document. Optionally apply a think-like profile's lens for expert-perspective reviews. See `references/review-format.md` for the document structure and classification rules.
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

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **plan**: Plan filename, slug, or search term
    - **as:<profile>**: Optional think-like profile to apply (e.g., `as:dhh`)
    - **--branch**: Override branch name (default: current branch)
  </step>

  <step id="find-plan" number="3">
    <description>Find Plan</description>

    <action>Search `<home>/.things/playbook/plans/` for a plan matching the argument.</action>
    - Try exact filename match first
    - Then try slug match (strip .md)
    - Then try content search (title, description)

    <if condition="not-found">
      <action>Check `<home>/.claude/plans/` as fallback.</action>
      <if condition="found-in-claude-plans">
        <ask-user-question>
          <question>Found a matching plan in ~/.claude/plans/ but it's not imported into playbook yet. Import it first?</question>
          <option label="Yes (Recommended)">Import the plan, then review</option>
          <option>No -- cancel the review</option>
        </ask-user-question>
        <if condition="yes">
          <action>Import via the same flow as `/capture-plan` -- generate frontmatter, write to playbook/plans/.</action>
        </if>
      </if>
      <if condition="not-found-anywhere">
        <action>List available plans from `playbook/plans/`. Let user pick.</action>
      </if>
    </if>

    <action>Read the full plan content.</action>
  </step>

  <step id="load-profile" number="4">
    <description>Load think-like Profile (if specified)</description>

    <if condition="as:<profile> specified">
      <action>Read the profile's code-review action file from `<home>/.things/think-like/profiles/<profile-id>/code-review.md`.</action>
      <if condition="action-file-missing">
        <action>Try the most relevant available action for this profile. If none suitable, warn: "Profile '<name>' doesn't have a code-review action. Proceeding without profile lens."</action>
      </if>
      <constraint>When a profile is loaded, adopt its voice, priorities, and evaluation criteria for the review. The Done/Actionable structure remains the same, but assessments reflect the profile's perspective.</constraint>
    </if>

    <if condition="no-profile-specified-and-preferences.default_review_profile-set">
      <action>Use the default profile from preferences.</action>
    </if>
  </step>

  <step id="gather-branch-work" number="5">
    <description>Gather Branch Work</description>

    <action>Determine the current branch:</action>
    <command language="bash" tool="Bash">git rev-parse --abbrev-ref HEAD</command>

    <if condition="--branch provided">Use the specified branch instead.</if>

    <action>Gather branch work:</action>
    <command language="bash" tool="Bash">git log --oneline main..HEAD</command>
    <command language="bash" tool="Bash">git diff main..HEAD --stat</command>

    <action>Read changed files to understand what was actually implemented.</action>
  </step>

  <step id="classify-items" number="6">
    <description>Classify Plan Items</description>

    <action>Extract individual items/tasks from the plan content. For each, compare against branch work and classify:</action>

    - **done**: Clear evidence in branch (files changed, tests added, code matches plan description)
    - **actionable**: Not done, clear what's needed next
    - **needs-more-information**: Ambiguous -- can't tell from code alone
  </step>

  <step id="present-initial-review" number="7">
    <description>Present Initial Review</description>

    <action>Show the initial classification to the user:</action>
    <output>
    ## Initial Review: <plan title> against <branch>

    Done: N | Actionable: N | Needs clarification: N

    <list of items with their classifications>
    </output>
  </step>

  <step id="interview-loop" number="8">
    <description>Interview Loop for Ambiguous Items</description>

    <constraint>For each "needs-more-information" item, ask a targeted question via AskUserQuestion. Reclassify based on the answer. Continue until none remain.</constraint>

    <action>For each ambiguous item:</action>

    <ask-user-question>
      <question><targeted question about the specific item, e.g.:>
      - "I see partial work on <X>. Is this complete, or is there more to do?"
      - "The plan mentions <Y> but I don't see it in the branch. Was this intentionally deferred?"
      - "There's code for <Z> but no tests. Should I mark this as done or actionable?"
      </question>
      <option>It's done</option>
      <option>It's actionable -- needs more work</option>
      <option-with-text-input>Let me explain</option-with-text-input>
    </ask-user-question>

    <action>Reclassify based on the answer. If the user provides explanation, use it as context for the actionable item's "What's needed" section.</action>
  </step>

  <step id="write-review" number="9">
    <description>Write Review Document</description>

    <write path="<home>/.things/playbook/reviews/<date>-<plan-slug>-review.md">

    <constraint>Use the review format from `references/review-format.md`. Only include "done" and "actionable" items (no "needs-more-information" should remain).</constraint>

    <template name="review">
    ```markdown
    ---
    title: "Review: <plan title> against <branch>"
    date: <YYYY-MM-DD>
    description: "<brief summary>"
    doc_type: "review"
    plan_ref: "plans/<plan-slug>/v<N>.md"
    branch: "<branch-name>"
    profile_used: "<profile-id or null>"
    status: "<all-addressed|has-open-items>"
    actionable_count: <N>
    done_count: <N>
    tags: [<tags>]
    ---

    ## Summary

    Done: <N> | Actionable: <N>

    <narrative summary>

    ## Done

    ### <Item title>
    - **Evidence**: <specific evidence>
    - **Notes**: <context>

    ...

    ## Actionable Items

    ### <Item title>
    - **What's needed**: <specific next step>
    - **Context**: <relevant context>
    - **Priority**: <high|medium|low>

    ...
    ```
    </template>

    </write>
  </step>

  <step id="suggest-plan-update" number="10">
    <description>Suggest Plan Status Update</description>

    <if condition="all-items-done">
      <ask-user-question>
        <question>All plan items are done! Mark the plan as completed?</question>
        <option label="Yes">Update plan status to "completed"</option>
        <option>No -- keep it active</option>
      </ask-user-question>
      <if condition="yes">
        <action>Update the plan's frontmatter `status` to `"completed"`.</action>
      </if>
    </if>

    <if condition="has-actionable-and-plan-status-is-active">
      <action>Suggest updating plan status to "in-progress".</action>
    </if>
  </step>

  <step id="git-workflow" number="11">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "review: <plan-slug>"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push this review?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the review has been saved.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="12">
    <description>Confirm</description>

    <completion-message>
    Review complete: **<plan title>** against `<branch>`
    Done: <done_count> | Actionable: <actionable_count>
    Profile: <profile name or "none">
    Location: `<home>/.things/playbook/reviews/<filename>`

    Next steps:
    - `/resume-plan <plan-slug>` -- Pick up implementation where you left off
    - `/implement <review-filename>` -- Implement specific actionable items
    - `/progress <plan-slug>` -- See full progress dashboard
    </completion-message>
  </step>

</steps>
