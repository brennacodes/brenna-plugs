---
name: update
description: "Evolve a plan's content, status, or notes over time - update status, append implementation notes, rewrite sections, or supersede with a new version."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<plan> [--status <status>] [--notes]"
---

<purpose>
Update a plan's content, status, or notes. Plans evolve over time -- requirements change, scope shifts, and implementation reveals new information. This skill supports updating status, appending dated notes, rewriting sections based on new information, and superseding plans with new versions.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.<exit /></if>

      <read path="<home>/.things/playbook/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-pb` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="find-plan" number="2">
    <description>Find Plan</description>

    <action>Search `<home>/.things/playbook/plans/` for a plan matching `$ARGUMENTS` (excluding flags).</action>
    - Try exact filename match
    - Then slug match
    - Then content search

    <if condition="not-found">
      <action>List available plans. Let user pick.</action>
    </if>

    <read path="<home>/.things/playbook/plans/<plan-slug>.md" output="plan" />
  </step>

  <step id="determine-update-type" number="3">
    <description>Determine Update Type</description>

    <if condition="--status flag provided">
      <action>Validate the status value: `active`, `in-progress`, `completed`, `superseded`, `abandoned`.</action>
      <action>Update the plan's frontmatter `status` field.</action>
    </if>

    <if condition="--notes flag provided">
      <action>Append a dated notes section to the plan body.</action>
      <ask-user-question>
        <question>What notes would you like to add? (These will be appended as a dated section.)</question>
      </ask-user-question>
    </if>

    <if condition="no-flags">
      <ask-user-question>
        <question>What would you like to update?</question>
        <option label="Update content">Rewrite sections based on new information from this conversation</option>
        <option label="Add notes">Append a dated notes section (learnings, scope changes, decisions)</option>
        <option label="Change status">Update the plan's lifecycle status</option>
        <option label="Supersede">Create a new version and mark this plan as superseded</option>
      </ask-user-question>
    </if>
  </step>

  <step id="apply-update" number="4">
    <description>Apply the Update</description>

    <if condition="update-content">
      <action>Read conversation context and the current plan. Identify sections that have changed based on new information. Rewrite those sections while preserving unchanged content.</action>
      <action>Show a summary of changes to the user for approval before writing.</action>
    </if>

    <if condition="add-notes">
      <action>Append a dated notes section:</action>
      <template name="notes-section">
      ```markdown

      ## Notes (<YYYY-MM-DD>)

      <user's notes content>
      ```
      </template>
    </if>

    <if condition="change-status">
      <ask-user-question>
        <question>What status should this plan have?</question>
        <option>active -- imported but not yet being worked on</option>
        <option>in-progress -- actively being implemented</option>
        <option>completed -- all items done</option>
        <option>abandoned -- no longer relevant</option>
      </ask-user-question>
      <action>Update the frontmatter `status` field.</action>
    </if>

    <if condition="supersede">
      <action>Create a new plan file with updated content. Mark the old plan's `status` as `"superseded"` and add a `superseded_by` field pointing to the new plan's filename.</action>
    </if>
  </step>

  <step id="write-plan" number="5">
    <description>Write Updated Plan</description>

    <write path="<home>/.things/playbook/plans/<plan-slug>.md" content="updated-plan" />

    <if condition="supersede">
      <write path="<home>/.things/playbook/plans/<new-slug>.md" content="new-plan" />
    </if>
  </step>

  <step id="git-workflow" number="6">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "update: <plan-slug>"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push the updated plan?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the plan has been updated.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="7">
    <description>Confirm</description>

    <completion-message>
    Updated: **<plan title>**
    Change: <summary of what changed>
    Status: `<status>`

    <if condition="superseded">New version: `<new-slug>.md`</if>
    </completion-message>
  </step>

</steps>
