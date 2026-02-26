---
name: migrate-idat
description: "Migrate i-did-a-thing data files from the old flat .things/ layout to the per-plugin directory structure. Moves logs, arsenal, resumes, index.json, and tags.json."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<purpose>
Migrate i-did-a-thing data files from the old flat `~/.things/` layout to the per-plugin `~/.things/i-did-a-thing/` directory structure. This moves logs, arsenal files, resumes, and index files.

This skill handles **data file relocation only**. Config migration (config.yml -> config.json + preferences.json) is handled by `/things:setup-things`. Run `/things:setup-things` first if config.json doesn't exist yet.
</purpose>

<steps>

  <step id="check-prerequisites" number="1">
    <description>Check Prerequisites</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>
      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first to initialize your .things directory." Then stop.</if>

      <action>Check for old data in flat locations.</action>
      <command language="bash" tool="Bash">ls -d <home>/.things/logs <home>/.things/arsenal <home>/.things/resumes 2>/dev/null
ls <home>/.things/index.json <home>/.things/tags.json 2>/dev/null</command>

      <if condition="no-old-data-found">
        Tell the user: "No old i-did-a-thing data found to migrate. Your data is already in the new location or hasn't been created yet." Then stop.
        <exit />
      </if>
    </load-config>
  </step>

  <step id="show-plan" number="2">
    <description>Show Migration Plan</description>

    <action>Count files in each old location and present the plan.</action>
    <command language="bash" tool="Bash">echo "logs: $(ls <home>/.things/logs/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "arsenal: $(ls <home>/.things/arsenal/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "resumes: $(ls <home>/.things/resumes/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "index.json: $([ -f <home>/.things/index.json ] && echo 'yes' || echo 'no')"
echo "tags.json: $([ -f <home>/.things/tags.json ] && echo 'yes' || echo 'no')"</command>

    <output>
    i-did-a-thing migration plan:

    - `~/.things/logs/` (<n> files) -> `~/.things/i-did-a-thing/logs/`
    - `~/.things/arsenal/` (<n> files) -> `~/.things/i-did-a-thing/arsenal/`
    - `~/.things/resumes/` (<n> files) -> `~/.things/i-did-a-thing/resumes/`
    - `~/.things/index.json` -> `~/.things/i-did-a-thing/index.json`
    - `~/.things/tags.json` -> `~/.things/i-did-a-thing/tags.json`
    </output>

    <if condition="dry-run-flag">Show the plan and stop. Do not move any files.<exit /></if>

    <ask-user-question>
      <question>Proceed with i-did-a-thing data migration?</question>
      <option>Yes -- move files now</option>
      <option>No -- cancel</option>
    </ask-user-question>
  </step>

  <step id="create-directories" number="3">
    <description>Create Target Directories</description>

    <command language="bash" tool="Bash">mkdir -p <home>/.things/i-did-a-thing/logs
mkdir -p <home>/.things/i-did-a-thing/arsenal
mkdir -p <home>/.things/i-did-a-thing/resumes</command>
  </step>

  <step id="move-data" number="4">
    <description>Move Data Files</description>

    <constraint>Use `mv` (not `cp`) to avoid duplicates. Skip items that don't exist.</constraint>

    <command language="bash" tool="Bash">mv <home>/.things/logs/* <home>/.things/i-did-a-thing/logs/ 2>/dev/null || true
mv <home>/.things/arsenal/* <home>/.things/i-did-a-thing/arsenal/ 2>/dev/null || true
mv <home>/.things/resumes/* <home>/.things/i-did-a-thing/resumes/ 2>/dev/null || true
mv <home>/.things/index.json <home>/.things/i-did-a-thing/index.json 2>/dev/null || true
mv <home>/.things/tags.json <home>/.things/i-did-a-thing/tags.json 2>/dev/null || true</command>
  </step>

  <step id="cleanup" number="5">
    <description>Clean Up Empty Old Directories</description>

    <command language="bash" tool="Bash">rmdir <home>/.things/logs 2>/dev/null || true
rmdir <home>/.things/arsenal 2>/dev/null || true
rmdir <home>/.things/resumes 2>/dev/null || true</command>

    <constraint>Only `rmdir` (not `rm -rf`) -- this safely fails if directories aren't empty.</constraint>
  </step>

  <step id="verify" number="6">
    <description>Verify Migration</description>

    <action>Count files in new locations.</action>
    <command language="bash" tool="Bash">echo "logs: $(ls <home>/.things/i-did-a-thing/logs/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "arsenal: $(ls <home>/.things/i-did-a-thing/arsenal/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "resumes: $(ls <home>/.things/i-did-a-thing/resumes/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "index.json: $([ -f <home>/.things/i-did-a-thing/index.json ] && echo 'yes' || echo 'no')"
echo "tags.json: $([ -f <home>/.things/i-did-a-thing/tags.json ] && echo 'yes' || echo 'no')"</command>
  </step>

  <step id="git-workflow" number="7">
    <description>Handle Git</description>

    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>

      <if condition="workflow-auto">
        <command language="bash" tool="Bash">git -C <home>/.things add -A && git -C <home>/.things commit -m "migrate: i-did-a-thing data to per-plugin directory" && git -C <home>/.things push</command>
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

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
    i-did-a-thing data migration complete!

    - <n> log files -> `~/.things/i-did-a-thing/logs/`
    - <n> arsenal files -> `~/.things/i-did-a-thing/arsenal/`
    - <n> resume files -> `~/.things/i-did-a-thing/resumes/`
    - index.json and tags.json moved

    Your data is now in the per-plugin directory structure. Use `/thing-i-did` to log new experiences.
    </completion-message>
  </step>

</steps>
