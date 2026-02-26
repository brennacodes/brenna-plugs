---
name: migrate-wdyd
description: "Migrate what-did-you-do data files from the old flat .things/ layout to the per-plugin directory structure. Moves sessions, questions, company prep plans, and converts progress.md to JSON."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<purpose>
Migrate what-did-you-do data files from the old `~/.things/interview-prep/` layout to the per-plugin `~/.things/what-did-you-do/` directory structure. This moves session files, question overrides, company prep plans, and converts the markdown progress dashboard to JSON.

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
      <command language="bash" tool="Bash">ls -d <home>/.things/interview-prep 2>/dev/null</command>

      <if condition="no-old-data-found">
        Tell the user: "No old what-did-you-do data found to migrate. Your data is already in the new location or hasn't been created yet." Then stop.
      </if>
    </load-config>
  </step>

  <step id="show-plan" number="2">
    <description>Show Migration Plan</description>

    <action>Inventory old data.</action>

    <command language="bash" tool="Bash">
echo "sessions: $(ls <home>/.things/interview-prep/sessions/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "question-overrides: $(ls -d <home>/.things/interview-prep/question-overrides 2>/dev/null && echo 'yes' || echo 'no')"
echo "company prep plans: $(ls <home>/.things/interview-prep/companies/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "progress.md: $([ -f <home>/.things/interview-prep/progress.md ] && echo 'yes' || echo 'no')"
    </command>

    <output>
    what-did-you-do migration plan:

    Data moves:
    - `interview-prep/sessions/` (<n> files) -> `what-did-you-do/sessions/`
    - `interview-prep/question-overrides/` -> `what-did-you-do/questions/`
    - `interview-prep/companies/` (<n> files) -> `what-did-you-do/` (company prep plans)

    Format conversions:
    - `interview-prep/progress.md` -> `what-did-you-do/progress.json`
    </output>

    <if condition="dry-run-flag">Show the plan and stop. Do not move any files.</if>

    <ask-user>
      Use AskUserQuestion: "Proceed with what-did-you-do data migration?"
      - Yes -- move files now
      - No -- cancel
    </ask-user>
  </step>

  <step id="create-directories" number="3">
    <description>Create Target Directories</description>

    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-did-you-do/sessions</command>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/what-did-you-do/questions</command>
  </step>

  <step id="move-data" number="4">
    <description>Move Data Files</description>

    <constraint>Use `mv` (not `cp`) to avoid duplicates. Skip items that don't exist.</constraint>

    <command language="bash" tool="Bash">mv <home>/.things/interview-prep/sessions/* <home>/.things/what-did-you-do/sessions/ 2>/dev/null || true</command>

    <phase name="question-overrides" number="1">
      <action>Move question overrides, renaming the directory.</action>
      <command language="bash" tool="Bash">mv <home>/.things/interview-prep/question-overrides/* <home>/.things/what-did-you-do/questions/ 2>/dev/null || true</command>
    </phase>

    <phase name="company-prep-plans" number="2">
      <action>Move company prep plan files (these sit directly in the plugin directory).</action>
      <command language="bash" tool="Bash">mv <home>/.things/interview-prep/companies/*.md <home>/.things/what-did-you-do/ 2>/dev/null || true</command>
    </phase>
  </step>

  <step id="convert-progress" number="5">
    <description>Convert progress.md to progress.json</description>

    <if condition="progress-md-exists">
      <read path="<home>/.things/interview-prep/progress.md" output="progress" />
      <action>Parse the markdown: extract dimension scores (Specificity, Structure, Impact, Relevance, Self-Advocacy), category breakdown if present, and session history entries.</action>

      <write path="<home>/.things/what-did-you-do/progress.json">
        <schema name="progress-json">
        ```json
        {
          "version": 1,
          "last_updated": "<current_date>",
          "dimensions": {
            "specificity": { "average": 0, "trend": "stable" },
            "structure": { "average": 0, "trend": "stable" },
            "impact": { "average": 0, "trend": "stable" },
            "relevance": { "average": 0, "trend": "stable" },
            "self_advocacy": { "average": 0, "trend": "stable" }
          },
          "sessions": []
        }
        ```
        </schema>
      </write>

      <constraint>Populate actual values from the parsed markdown. Use the schema above as the structure, filling in real data.</constraint>
    </if>

    <if condition="no-progress-md">Skip this step.</if>
  </step>

  <step id="cleanup" number="6">
    <description>Clean Up Empty Old Directories</description>

    <command language="bash" tool="Bash">
rmdir <home>/.things/interview-prep/sessions 2>/dev/null || true
rmdir <home>/.things/interview-prep/question-overrides 2>/dev/null || true
rmdir <home>/.things/interview-prep/companies 2>/dev/null || true
rmdir <home>/.things/interview-prep 2>/dev/null || true
    </command>

    <constraint>Only `rmdir` (not `rm -rf`) -- this safely fails if directories aren't empty. If progress.md is the only remaining file, leave it as a backup until the user removes it manually.</constraint>
  </step>

  <step id="verify" number="7">
    <description>Verify Migration</description>

    <command language="bash" tool="Bash">
echo "sessions: $(ls <home>/.things/what-did-you-do/sessions/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "questions: $(ls <home>/.things/what-did-you-do/questions/ 2>/dev/null | wc -l | tr -d ' ') files"
echo "progress.json: $([ -f <home>/.things/what-did-you-do/progress.json ] && echo 'yes' || echo 'no')"
    </command>
  </step>

  <step id="git-workflow" number="8">
    <description>Handle Git</description>

    <git-workflow>
      <action>Read git workflow from `<home>/.things/config.json`.</action>

      <if condition="workflow-auto">
        <command language="bash" tool="Bash">git -C <home>/.things add -A && git -C <home>/.things commit -m "migrate: what-did-you-do data to per-plugin directory" && git -C <home>/.things push</command>
      </if>
      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion: "Commit migrated files to .things repo?"
          - Yes -- commit and push
          - Commit only -- commit without pushing
          - No -- I'll handle git myself
        </ask-user>
      </if>
      <if condition="workflow-manual">Tell the user their files have been moved and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="9">
    <description>Confirm</description>

    <completion-message>
    what-did-you-do data migration complete!

    - <n> session files -> `~/.things/what-did-you-do/sessions/`
    - Question overrides -> `~/.things/what-did-you-do/questions/`
    - Company prep plans -> `~/.things/what-did-you-do/`
    - progress.md converted to `~/.things/what-did-you-do/progress.json`

    Your data is now in the per-plugin directory structure. Use `/practice` to start drilling.
    </completion-message>
  </step>

</steps>
