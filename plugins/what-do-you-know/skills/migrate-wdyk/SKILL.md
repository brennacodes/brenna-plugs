---
name: migrate-wdyk
description: "Migrate what-do-you-know data files from the old flat .things/ layout to the per-plugin directory structure. Moves sessions, study plans, and converts progress.md and knowledge-map.md to JSON."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<purpose>
Migrate what-do-you-know data files from the old `~/.things/learning/` layout to the per-plugin `~/.things/what-do-you-know/` directory structure. This moves session files and study plans, and converts the markdown progress dashboard and knowledge map to JSON.

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
      <action>Check for old data.</action>
      <command language="bash" tool="Bash">ls -d <home>/.things/learning 2>/dev/null</command>
      <if condition="no-old-data-found">Tell the user: "No old what-do-you-know data found to migrate. Your data is already in the new location or hasn't been created yet." Then stop.</if>
    </load-config>
  </step>

  <step id="show-plan" number="2">
    <description>Show Migration Plan</description>
    <action>Inventory old data.</action>
    <command language="bash" tool="Bash">
echo "sessions: $(ls <home>/.things/learning/sessions/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "study-plans: $(ls <home>/.things/learning/study-plans/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "progress.md: $([ -f <home>/.things/learning/progress.md ] && echo 'yes' || echo 'no')"
echo "knowledge-map.md: $([ -f <home>/.things/learning/knowledge-map.md ] && echo 'yes' || echo 'no')"
    </command>

    <output>
    what-do-you-know migration plan:

    Data moves:
    - `learning/sessions/` (<n> files) -> `what-do-you-know/sessions/`
    - `learning/study-plans/` (<n> files) -> `what-do-you-know/study-plans/`

    Format conversions:
    - `learning/progress.md` -> `what-do-you-know/progress.json`
    - `learning/knowledge-map.md` -> `what-do-you-know/knowledge-map.json`
    </output>

    <if condition="dry-run-flag">
      <action>Show the plan and stop. Do not move any files.</action>
      <exit />
    </if>

    <ask-user-question>
      <question>Proceed with what-do-you-know data migration?</question>
      <option>Yes -- move files now</option>
      <option>No -- cancel</option>
    </ask-user-question>
  </step>

  <step id="create-directories" number="3">
    <description>Create Target Directories</description>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-do-you-know/sessions</command>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-do-you-know/study-plans</command>
  </step>

  <step id="move-data" number="4">
    <description>Move Data Files</description>
    <constraint>Use `mv` (not `cp`) to avoid duplicates. Skip items that don't exist.</constraint>
    <command language="bash" tool="Bash">mv <home>/.things/learning/sessions/* <home>/.things/what-do-you-know/sessions/ 2>/dev/null || true</command>
    <command language="bash" tool="Bash">mv <home>/.things/learning/study-plans/* <home>/.things/what-do-you-know/study-plans/ 2>/dev/null || true</command>
  </step>

  <step id="convert-progress" number="5">
    <description>Convert progress.md to progress.json</description>
    <if condition="progress-md-exists">
      <action>Read `<home>/.things/learning/progress.md`. Parse the markdown to extract dimension scores (Depth, Accuracy, Connections, Application, Articulation) and session history entries.</action>

      <write path="<home>/.things/what-do-you-know/progress.json">
        <schema name="progress-json">
        ```json
        {
          "version": 1,
          "last_updated": "<current_date>",
          "dimensions": {
            "depth": { "average": 0, "trend": "stable" },
            "accuracy": { "average": 0, "trend": "stable" },
            "connections": { "average": 0, "trend": "stable" },
            "application": { "average": 0, "trend": "stable" },
            "articulation": { "average": 0, "trend": "stable" }
          },
          "sessions": []
        }
        ```
        </schema>
        <constraint>Populate actual values from the parsed markdown. Use the schema above as the structure, filling in real data.</constraint>
      </write>
    </if>
    <if condition="no-progress-md">
      <action>Skip this step.</action>
    </if>
  </step>

  <step id="convert-knowledge-map" number="6">
    <description>Convert knowledge-map.md to knowledge-map.json</description>
    <if condition="knowledge-map-md-exists">
      <action>Read `<home>/.things/learning/knowledge-map.md`. Parse the markdown to extract topic classifications by category heading (Strong, Building, Gap, Blind Spot) and map each topic to its level.</action>

      <write path="<home>/.things/what-do-you-know/knowledge-map.json">
        <schema name="knowledge-map-json">
        ```json
        {
          "version": 1,
          "last_updated": "<current_date>",
          "topics": {
            "<topic>": {
              "level": "strong|building|gap|blind_spot",
              "last_assessed": "<date or null>",
              "related_skills": []
            }
          }
        }
        ```
        </schema>
        <constraint>Populate actual values from the parsed markdown. Use the schema above as the structure, filling in real data.</constraint>
      </write>
    </if>
    <if condition="no-knowledge-map-md">
      <action>Skip this step.</action>
    </if>
  </step>

  <step id="cleanup" number="7">
    <description>Clean Up Empty Old Directories</description>
    <command language="bash" tool="Bash">
rmdir <home>/.things/learning/sessions 2>/dev/null || true
rmdir <home>/.things/learning/study-plans 2>/dev/null || true
rmdir <home>/.things/learning 2>/dev/null || true
    </command>
    <constraint>Only `rmdir` (not `rm -rf`) -- this safely fails if directories aren't empty. If progress.md or knowledge-map.md are the only remaining files, leave them as backups until the user removes them manually.</constraint>
  </step>

  <step id="verify" number="8">
    <description>Verify Migration</description>
    <command language="bash" tool="Bash">
echo "sessions: $(ls <home>/.things/what-do-you-know/sessions/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "study-plans: $(ls <home>/.things/what-do-you-know/study-plans/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "progress.json: $([ -f <home>/.things/what-do-you-know/progress.json ] && echo 'yes' || echo 'no')"
echo "knowledge-map.json: $([ -f <home>/.things/what-do-you-know/knowledge-map.json ] && echo 'yes' || echo 'no')"
    </command>
  </step>

  <step id="git-workflow" number="9">
    <description>Handle Git</description>
    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>
      <if condition="workflow-auto">
        <command language="bash" tool="Bash">git -C <home>/.things add -A && git -C <home>/.things commit -m "migrate: what-do-you-know data to per-plugin directory" && git -C <home>/.things push</command>
      </if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit migrated files to .things repo?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only -- commit without pushing</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">
        <action>Tell the user their files have been moved and they can commit when ready.</action>
      </if>
    </git-workflow>
  </step>

  <step id="confirm" number="10">
    <description>Confirm</description>
    <completion-message>
    what-do-you-know data migration complete!

    - <n> session files -> `~/.things/what-do-you-know/sessions/`
    - <n> study plans -> `~/.things/what-do-you-know/study-plans/`
    - progress.md converted to `~/.things/what-do-you-know/progress.json`
    - knowledge-map.md converted to `~/.things/what-do-you-know/knowledge-map.json`

    Your data is now in the per-plugin directory structure. Use `/explore-wdyk` to start learning.
    </completion-message>
  </step>

</steps>
