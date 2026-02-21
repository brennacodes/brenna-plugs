---
name: migrate-mmw
description: "Migrate mark-my-words data files from the old flat .things/ layout to the per-plugin directory structure. Moves voice profiles and renames the blog working directory."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<purpose>
Migrate mark-my-words data files from the old flat `~/.things/` layout to the per-plugin `~/.things/mark-my-words/` directory structure. This moves voice profiles and renames the blog working directory.

This skill handles **data file relocation only**. Config migration (config.yml -> config.json + preferences.json) is handled by `/setup-htt`. Run `/setup-htt` first if config.json doesn't exist yet.
</purpose>

<steps>

  <step id="check-prerequisites" number="1">
    <description>Check Prerequisites</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/setup-htt` first to initialize your .things directory." Then stop.</if>
    </load-config>

    <action>Check for old data.</action>
    <command language="bash" tool="Bash">ls -d <home>/.things/voices 2>/dev/null; ls -d <home>/.mark-my-words-workdir 2>/dev/null</command>
    <if condition="no-old-data-found">Tell the user: "No old mark-my-words data found to migrate. Your data is already in the new location or hasn't been created yet." Then stop.</if>
  </step>

  <step id="show-plan" number="2">
    <description>Show Migration Plan</description>

    <action>Inventory old data.</action>
    <command language="bash" tool="Bash">echo "voices: $(ls <home>/.things/voices/*.md 2>/dev/null | wc -l | tr -d ' ') files"; echo "workdir: $([ -d <home>/.mark-my-words-workdir ] && echo 'yes' || echo 'no')"</command>

    <output-format>
    mark-my-words migration plan:

    Data moves:
    - `~/.things/voices/` (<n> files) -> `~/.things/mark-my-words/voices/`

    Renames:
    - `~/.mark-my-words-workdir` -> `~/.mark-my-words` (if present)
    </output-format>

    <if condition="dry-run-flag">Show the plan and stop. Do not move any files.</if>

    <ask-user-question>
      <question>Proceed with mark-my-words data migration?</question>
      <option>Yes -- move files now</option>
      <option>No -- cancel</option>
    </ask-user-question>
  </step>

  <step id="create-directories" number="3">
    <description>Create Target Directories</description>

    <command language="bash" tool="Bash">mkdir -p <home>/.things/mark-my-words/voices</command>
  </step>

  <step id="move-voices" number="4">
    <description>Move Voice Profiles</description>

    <constraint>Use `mv` (not `cp`) to avoid duplicates. Skip items that don't exist.</constraint>
    <command language="bash" tool="Bash">mv <home>/.things/voices/* <home>/.things/mark-my-words/voices/ 2>/dev/null || true</command>
  </step>

  <step id="rename-workdir" number="5">
    <description>Rename Blog Working Directory</description>

    <if condition="old-workdir-exists">
      <command language="bash" tool="Bash">mv <home>/.mark-my-words-workdir <home>/.mark-my-words</command>

      <if condition="preferences-exist">
        <action>Read `<home>/.things/mark-my-words/preferences.json` and update `workdir` to `<home>/.mark-my-words` using Edit.</action>
      </if>
    </if>

    <action>Scan for stray copies in common locations.</action>
    <command language="bash" tool="Bash">ls -d <home>/Documents/.mark-my-words-workdir <home>/Documents/personal/.mark-my-words-workdir 2>/dev/null</command>

    <if condition="stray-copies-found">
      <output>
      Warning: Found additional `.mark-my-words-workdir` copies:
      - `<path>`

      These may have uncommitted changes. Review and remove them manually if no longer needed.
      </output>
    </if>
  </step>

  <step id="cleanup" number="6">
    <description>Clean Up Empty Old Directories</description>

    <command language="bash" tool="Bash">rmdir <home>/.things/voices 2>/dev/null || true</command>
    <constraint>Only `rmdir` (not `rm -rf`) -- this safely fails if the directory isn't empty.</constraint>
  </step>

  <step id="verify" number="7">
    <description>Verify Migration</description>

    <command language="bash" tool="Bash">echo "voices: $(ls <home>/.things/mark-my-words/voices/*.md 2>/dev/null | wc -l | tr -d ' ') files"; echo "workdir: $([ -d <home>/.mark-my-words ] && echo '<home>/.mark-my-words' || echo 'not found')"</command>
  </step>

  <step id="git-workflow" number="8">
    <description>Handle Git</description>

    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>

      <if condition="workflow-auto">
        <command language="bash" tool="Bash">git -C <home>/.things add -A && git -C <home>/.things commit -m "migrate: mark-my-words data to per-plugin directory" && git -C <home>/.things push</command>
      </if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit migrated files to .things repo?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only -- commit without pushing</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user their files have been moved and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="9">
    <description>Confirm</description>

    <completion-message>
    mark-my-words data migration complete!

    - <n> voice profiles -> `~/.things/mark-my-words/voices/`
    - Blog working directory: `~/.mark-my-words`

    Your data is now in the per-plugin directory structure. Use `/new-post` to write a post.
    </completion-message>
  </step>

</steps>
