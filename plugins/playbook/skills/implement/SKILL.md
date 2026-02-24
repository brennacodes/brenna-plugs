---
name: implement
description: "Implement actionable items from a review - pick items by number, implement them, and mark them as resolved in the review document."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, LSP, AskUserQuestion
argument-hint: "<item-or-review>"
---

<purpose>
Implement specific actionable items from a review document. Load the review, show remaining items, let the user pick which to implement, do the work, and update the review doc as items are resolved.
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

  <step id="find-review" number="2">
    <description>Find Review</description>

    <if condition="argument-is-review-filename-or-slug">
      <read path="<home>/.things/playbook/reviews/<review>.md" output="review" />
    </if>

    <if condition="argument-not-a-review">
      <action>List recent reviews from `<home>/.things/playbook/reviews/` (sorted by date, most recent first).</action>
      <ask-user-question>
        <question>Which review would you like to implement items from?</question>
      </ask-user-question>
      <read path="<home>/.things/playbook/reviews/<selected>.md" output="review" />
    </if>
  </step>

  <step id="show-actionable-items" number="3">
    <description>Show Remaining Actionable Items</description>

    <action>Parse the review's "Actionable Items" section. Show a numbered list:</action>

    <output>
    Actionable items from: <review title>

    1. <item title> -- <what's needed> (priority: <priority>)
    2. <item title> -- <what's needed> (priority: <priority>)
    ...
    </output>

    <if condition="no-actionable-items">
      <action>Tell the user: "All items in this review have been addressed!" Then stop.</action>
    </if>

    <ask-user-question>
      <question>Which items would you like to implement? Enter numbers (e.g., "1", "1,3", "1-3"), or "all".</question>
    </ask-user-question>
  </step>

  <step id="implement-items" number="4">
    <description>Implement Selected Items</description>

    <action>For each selected item:</action>

    1. Read the item's context (what's needed, relevant context from the review)
    2. Implement the action using available tools
    3. Mark the item as resolved in the review document

    <constraint>After completing each item, briefly confirm what was done before moving to the next.</constraint>

    <constraint>If an item can't be fully implemented (blocked, needs external input), explain why and leave it as actionable.</constraint>
  </step>

  <step id="update-review" number="5">
    <description>Update Review Document</description>

    <action>For each completed item:</action>
    - Move it from "Actionable Items" to "Done" section with evidence of completion
    - Decrement `actionable_count` in frontmatter
    - Increment `done_count` in frontmatter
    - If all items resolved, update `status` to `"all-addressed"`

    <write path="<home>/.things/playbook/reviews/<review>.md" content="updated-review" />
  </step>

  <step id="git-workflow" number="6">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "implement: <N> items from <review>"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the updated review?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the review has been updated.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="7">
    <description>Confirm</description>

    <completion-message>
    Implemented <N> items from: **<review title>**
    Remaining actionable: <actionable_count>

    <if condition="all-implemented">All items resolved! Consider running `/playbook:update <plan> --status completed`.</if>
    <if condition="has-remaining">Run `/implement <review>` again to continue.</if>
    </completion-message>
  </step>

</steps>
