---
name: migrate-htt
description: "Migrate heres-the-thing data between versions. Stub for future migration support."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<purpose>
Migrate heres-the-thing data between versions. Currently a stub -- v1.0.0 is the initial release with no prior data to migrate. Future versions will add migration logic here.
</purpose>

<steps>

  <step id="check-version" number="1">
    <description>Check Current Version</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.</if>

    2. Read `<home>/.things/heres-the-thing/preferences.json`
       <if condition="prefs-missing">Tell the user: "No heres-the-thing installation found. Run `/heres-the-thing:setup-htt` first." Then stop.</if>
    </load-config>
  </step>

  <step id="report" number="2">
    <description>Report Status</description>

    <completion-message>
    heres-the-thing v1.0.0 -- no migrations needed.

    This is the initial release. Future versions will add migration logic as the data schema evolves.

    Current data location: `~/.things/heres-the-thing/`
    </completion-message>
  </step>

</steps>
