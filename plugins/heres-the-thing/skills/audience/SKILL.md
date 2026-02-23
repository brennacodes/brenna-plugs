---
name: audience
description: "Create and manage reusable audience segment profiles. Use when user says 'create audience', 'define audience', 'manage audiences', 'who am I talking to'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<create|list|view|edit|delete> [slug]"
---

<purpose>
Manage reusable audience segment profiles in `~/.things/heres-the-thing/audiences/`. Audience segments describe groups of people with shared characteristics, concerns, and communication preferences. These profiles are referenced by campaigns to tailor positioning strategy.

For individual people, use `shared/people/` profiles instead. Audience segments describe archetypes, not individuals.
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
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    Parse `$ARGUMENTS` for subcommand and optional slug.

    <if condition="no-arguments">
    Use AskUserQuestion:
    <options>
    - Create a new audience segment
    - List existing audience segments
    - View an audience segment
    - Edit an audience segment
    - Delete an audience segment
    </options>
    </if>
  </step>

  <step id="create" number="3">
    <description>Create Audience Segment</description>

    <if condition="subcommand-is-create">

    Use AskUserQuestion to gather:

    1. **Name**: What do you call this audience? (e.g., "Engineering Leadership", "Product Managers", "Budget Approvers")

    2. **Description**: Brief description of who they are and what they do.

    3. **Tags**: Tags for this audience segment (comma-separated)

    4. **Typical concerns**: What do they typically worry about? (ask for 3-5 items)

    5. **Decision criteria**: What drives their decisions? (ask for 2-4 items)

    6. **Communication preferences**:
       - Format preference (e.g., "Bottom-line-up-front", "Narrative", "Data-driven")
       - Length preference (e.g., "Concise -- 1 page max", "Detailed -- full proposal OK")
       - Language preference (e.g., "Business impact over technical details", "Technical depth expected")

    7. **Receptiveness baseline**: How does this audience segment typically respond to new ideas?
       <options>
       - champion -- They actively advocate for change
       - enthusiastic -- Open and supportive
       - neutral -- Will evaluate on merits
       - skeptical -- Needs strong evidence
       - hostile -- Actively resistant
       </options>

    Generate a slug from the name (lowercase, hyphens, no special characters).

    <output-path>`<home>/.things/heres-the-thing/audiences/<slug>.json`</output-path>

    ```json
    {
      "id": "<slug>",
      "name": "<name>",
      "description": "<description>",
      "tags": ["<tags>"],
      "typical_concerns": ["<concerns>"],
      "decision_criteria": ["<criteria>"],
      "communication_preferences": {
        "format": "<format>",
        "length": "<length>",
        "language": "<language>"
      },
      "receptiveness_baseline": "<baseline>",
      "known_objections": [],
      "created": "<current_date>",
      "updated": "<current_date>"
    }
    ```

    </if>
  </step>

  <step id="list" number="4">
    <description>List Audience Segments</description>

    <if condition="subcommand-is-list">
    Scan `<home>/.things/heres-the-thing/audiences/*.json`.

    For each file, read and extract: `id`, `name`, `receptiveness_baseline`, `tags`.

    Present as a table:
    ```
    Audience Segments:
      engineering-leadership    Engineering Leadership       neutral     [leadership, executive]
      individual-contributors   Individual Contributors      enthusiastic [engineering, ic]
      budget-approvers         Budget Approvers              skeptical   [finance, approval]
    ```
    </if>
  </step>

  <step id="view" number="5">
    <description>View Audience Segment</description>

    <if condition="subcommand-is-view">
    <if condition="no-slug">Ask the user which segment to view (list available options via AskUserQuestion).</if>

    Read `<home>/.things/heres-the-thing/audiences/<slug>.json`.

    Present the full profile in a readable format:
    ```
    Audience: Engineering Leadership
    Receptiveness: neutral
    Tags: leadership, executive, technical-strategy

    Description: Directors and VPs of engineering, responsible for org-wide technical decisions

    Typical Concerns:
    - Reliability and stability
    - Team productivity impact
    - Maintenance burden

    Decision Criteria:
    - ROI with clear timeline
    - Risk mitigation story
    - Team consensus signals

    Communication Preferences:
    - Format: Bottom-line-up-front, then supporting evidence
    - Length: Concise -- 1 page max for initial pitch
    - Language: Business impact over technical details

    Known Objections: (none yet)
    ```
    </if>
  </step>

  <step id="edit" number="6">
    <description>Edit Audience Segment</description>

    <if condition="subcommand-is-edit">
    <if condition="no-slug">Ask the user which segment to edit.</if>

    Read the existing segment. Show current values.

    Use AskUserQuestion to ask what to change:
    <options>
    - Name and description
    - Tags
    - Typical concerns
    - Decision criteria
    - Communication preferences
    - Receptiveness baseline
    - Known objections (add or remove)
    </options>

    Update the specified fields. Set `updated` to current date. Write the file.
    </if>
  </step>

  <step id="delete" number="7">
    <description>Delete Audience Segment</description>

    <if condition="subcommand-is-delete">
    <if condition="no-slug">Ask the user which segment to delete.</if>

    <ask-user>
    Confirm: "Delete audience segment '<name>'? This cannot be undone. Campaigns that reference this segment will keep their inline audience data."
    </ask-user>

    ```bash
    rm <home>/.things/heres-the-thing/audiences/<slug>.json
    ```
    </if>
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
    Show the action taken and current segment count.
    </completion-message>
  </step>

</steps>
