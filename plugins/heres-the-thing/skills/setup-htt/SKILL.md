---
name: setup-htt
description: "Initialize heres-the-thing -- create campaign directories, preferences, deliverable type registry, notification system, and register collections with things. Use when user first uses heres-the-thing or says 'set up heres-the-thing'."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

<purpose>
Configure heres-the-thing and register its collections with things. Creates the `~/.things/heres-the-thing/` directory structure, initializes the deliverable type registry with builtin types, sets notification preferences, and optionally installs the macOS launchd notification agent.
</purpose>

<steps>

  <step id="check-prerequisites" number="1">
    <description>Check Prerequisites</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup-things` first to initialize your .things directory." Then stop.</if>

    2. Read `<home>/.things/registry.json`
       <if condition="registry-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>

    3. Check if `<home>/.things/heres-the-thing/preferences.json` exists
       <if condition="preferences-exist">Show current settings and ask (via AskUserQuestion) if they want to reconfigure.</if>
    </load-config>
  </step>

  <step id="create-directories" number="2">
    <description>Create Directory Structure</description>

    ```bash
    mkdir -p <home>/.things/heres-the-thing/campaigns
    mkdir -p <home>/.things/heres-the-thing/audiences
    mkdir -p <home>/.things/heres-the-thing/deliverable-types
    mkdir -p <home>/.things/heres-the-thing/scripts
    ```
  </step>

  <step id="gather-preferences" number="3">
    <description>Gather Preferences</description>

    Use AskUserQuestion:

    Do you want to enable scheduled notifications for campaign check-ins?
    <options>
    - Yes -- remind me about upcoming target dates and post-delivery check-ins
    - No -- I'll check manually
    </options>

    <if condition="notifications-enabled">
    Use AskUserQuestion:

    When should notifications be quiet?
    <options>
    - Default (9pm - 8am)
    - Custom (I'll specify)
    </options>

    <if condition="custom-quiet-hours">Ask for start and end times.</if>
    </if>
  </step>

  <step id="write-preferences" number="4">
    <description>Write Preferences</description>

    <output-path>`<home>/.things/heres-the-thing/preferences.json`</output-path>

    ```json
    {
      "notifications": {
        "enabled": true,
        "check_interval_minutes": 60,
        "reminder_windows": ["7d", "2d", "1d", "3h", "1h"],
        "post_delivery_checkin_days": [1, 3, 7],
        "quiet_hours": { "start": "21:00", "end": "08:00" }
      }
    }
    ```

    <rule>Adjust `enabled` and `quiet_hours` based on user answers.</rule>
  </step>

  <step id="write-deliverable-types" number="5">
    <description>Initialize Deliverable Type Registry</description>

    <output-path>`<home>/.things/heres-the-thing/deliverable-types/index.json`</output-path>

    ```json
    {
      "version": "1.0.0",
      "types": {
        "strategy_brief": {
          "id": "strategy_brief",
          "name": "Strategy Brief",
          "description": "Full 5-page positioning strategy document",
          "builtin": true,
          "template": null,
          "output_format": "md",
          "requires": { "tools": ["Write"], "mcp_servers": [], "external": [] }
        },
        "meeting_prep_doc": {
          "id": "meeting_prep_doc",
          "name": "Meeting Prep Doc",
          "description": "Printable reference document with talking points, key phrases, and traps to avoid",
          "builtin": true,
          "template": null,
          "output_format": "md",
          "requires": { "tools": ["Write"], "mcp_servers": [], "external": [] }
        },
        "objection_map": {
          "id": "objection_map",
          "name": "Objection Map",
          "description": "Anticipated pushback with prepared responses, ordered by likelihood",
          "builtin": true,
          "template": null,
          "output_format": "md",
          "requires": { "tools": ["Write"], "mcp_servers": [], "external": [] }
        },
        "artifact_draft": {
          "id": "artifact_draft",
          "name": "Artifact Draft",
          "description": "The actual deliverable -- email, proposal, document, slide outline",
          "builtin": true,
          "template": null,
          "output_format": "md",
          "requires": { "tools": ["Write"], "mcp_servers": [], "external": [] }
        },
        "prep_plan": {
          "id": "prep_plan",
          "name": "Prep Plan",
          "description": "Time-boxed preparation schedule with milestones and checkpoints",
          "builtin": true,
          "template": null,
          "output_format": "md",
          "requires": { "tools": ["Write"], "mcp_servers": [], "external": [] }
        },
        "follow_up_template": {
          "id": "follow_up_template",
          "name": "Follow-Up Template",
          "description": "Post-delivery follow-up draft based on goals and anticipated outcomes",
          "builtin": true,
          "template": null,
          "output_format": "md",
          "requires": { "tools": ["Write"], "mcp_servers": [], "external": [] }
        }
      }
    }
    ```
  </step>

  <step id="install-notify-script" number="6">
    <description>Install Notification Script</description>

    <if condition="notifications-enabled">
    Copy the notification script to the data directory:

    Read the notify.sh script from the plugin source (use Glob to find it under the plugin's `scripts/` directory).
    Write it to `<home>/.things/heres-the-thing/scripts/notify.sh`.

    ```bash
    chmod +x <home>/.things/heres-the-thing/scripts/notify.sh
    ```

    Use AskUserQuestion:

    Install macOS launchd agent for scheduled notifications?
    <options>
    - Yes -- run every hour (Recommended)
    - No -- I'll run the script manually
    </options>

    <if condition="install-launchd">
    Read the install-launchd.sh script from the plugin source.
    Run it:

    ```bash
    bash <plugin-source>/scripts/install-launchd.sh <home>/.things/heres-the-thing/scripts/notify.sh <check_interval_minutes>
    ```
    </if>
    </if>
  </step>

  <step id="register-collections" number="7">
    <description>Register Collections with things</description>

    Read `<home>/.things/registry.json`. Add the following collection definitions:

    ```json
    {
      "heres-the-thing/campaigns": {
        "plugin": "heres-the-thing",
        "description": "Positioning campaigns with goals, audience, and tracked outcomes",
        "tags_field": "json.tags",
        "item_structure": {
          "type": "directory_per_item",
          "required_files": ["campaign.json"],
          "optional_file_patterns": ["strategy/*.md", "artifacts/*", "outcomes/*.json"]
        },
        "index_schema": {
          "required_fields": {
            "id": "string",
            "status": "string",
            "created": "date",
            "tags": "string[]"
          },
          "optional_fields": {
            "subject": "object",
            "goals": "object[]"
          }
        },
        "master_index": null,
        "rebuild_command": null
      },
      "heres-the-thing/audiences": {
        "plugin": "heres-the-thing",
        "description": "Reusable audience segment profiles",
        "tags_field": "json.tags",
        "item_structure": {
          "type": "flat_files",
          "file_pattern": "*.json"
        },
        "index_schema": {},
        "master_index": null,
        "rebuild_command": null
      },
      "heres-the-thing/outcomes": {
        "plugin": "heres-the-thing",
        "description": "Outcome logs across all campaigns",
        "tags_field": "json.tags",
        "item_structure": {
          "type": "flat_files",
          "file_pattern": "campaigns/*/outcomes/*.json"
        },
        "index_schema": {},
        "master_index": null,
        "rebuild_command": null
      }
    }
    ```

    Write the updated registry.json.

    <constraint>Do not overwrite existing collections. Only add the new ones. If they already exist, skip them (or update if reconfiguring).</constraint>
  </step>

  <step id="update-environment" number="8">
    <description>Update Environment Tracking</description>

    Read `<home>/.things/config.json`. Add `"heres-the-thing"` to the current environment's `plugins` array if not already present. Update `last_active`. Write the updated config.
  </step>

  <step id="confirm" number="9">
    <description>Confirm Setup</description>

    <completion-message>
    heres-the-thing is ready!

    - Campaigns: `<home>/.things/heres-the-thing/campaigns/`
    - Audiences: `<home>/.things/heres-the-thing/audiences/`
    - Deliverable types: 6 builtin types registered
    - Notifications: <enabled|disabled>
    <if condition="launchd-installed">- launchd: running every <interval> minutes</if>

    Collections registered with things:
    - heres-the-thing/campaigns
    - heres-the-thing/audiences
    - heres-the-thing/outcomes

    Start using it:
    - `/heres-the-thing:pitch` -- Create a campaign with strategy brief
    - `/heres-the-thing:audience` -- Define a reusable audience segment
    </completion-message>
  </step>

</steps>
