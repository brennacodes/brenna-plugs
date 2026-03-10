---
name: migrate-things
description: "Migrate shared resources and infrastructure from the old flat .things/ layout. Handles directory relocation, shared data (personas, companies), bootstrap cleanup, and config.yml archival. Per-plugin data migration is handled by each plugin's own migrate command."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

<references>
  <reference name="migration-guide" path="references/migration-guide.md" />
</references>

<purpose>
Migrate shared resources and infrastructure from the old flat `.things/` layout to the new per-plugin directory structure. This handles directory relocation, shared data (personas, companies), bootstrap cleanup, and config.yml archival.

**Config migration** (config.yml -> config.json + per-plugin preferences.json) is handled by `/things:setup-things`. Run `/things:setup-things` first if config.json doesn't exist yet.

**Per-plugin data migration** is handled by each plugin's own migrate command:
- `/migrate-idat` -- logs, arsenal, resumes, index files
- `/migrate-wdyd` -- sessions, questions, progress conversion
- `/migrate-wdyk` -- sessions, study plans, progress + knowledge map conversion
- `/migrate-mmw` -- voice profiles, blog working directory
</purpose>

<steps>

  <step id="detect-state" number="1">
    <description>Detect Current State</description>

    <load-config>
      Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

      <phase name="check-config">
        1. Check if `<home>/.things/config.json` exists.
           <if condition="config-json-missing">Tell the user: "Run `/things:setup-things` first - it handles config migration and directory setup." Then stop.</if>

        2. Read `<home>/.things/config.json` for git workflow settings.
      </phase>

      <phase name="check-old-layout">
        Check for old layout artifacts:

        ```bash
        echo "bootstrap: $([ -f <home>/.claude/things.local.md ] && echo 'yes' || echo 'no')"
        echo "config.yml: $([ -f <home>/.things/config.yml ] && echo 'yes' || echo 'no')"
        echo "personas: $([ -d <home>/.things/personas ] && echo 'yes' || echo 'no')"
        echo "companies-flat: $([ -d <home>/.things/companies ] && ls <home>/.things/companies/ 2>/dev/null | head -1 || echo 'no')"
        echo "old-logs: $([ -d <home>/.things/logs ] && echo 'yes' || echo 'no')"
        echo "old-interview-prep: $([ -d <home>/.things/interview-prep ] && echo 'yes' || echo 'no')"
        echo "old-learning: $([ -d <home>/.things/learning ] && echo 'yes' || echo 'no')"
        echo "old-voices: $([ -d <home>/.things/voices ] && echo 'yes' || echo 'no')"
        ```
      </phase>

      <phase name="check-non-convention-path">
        3. Check if `<home>/.claude/things.local.md` exists (legacy bootstrap).
           <if condition="bootstrap-exists">Read `things_path` from it (expand `~` to `<home>`). This tells us the old `.things/` location.</if>
      </phase>

      <if condition="no-old-artifacts">
        Tell the user: "No old layout artifacts found. Your .things directory is already migrated." Then check if per-plugin data still needs moving (show which per-plugin migrate commands to run if old data directories exist). Then stop.
      </if>
    </load-config>
  </step>

  <step id="check-git-sync" number="2">
    <description>Check Git Sync Status</description>

    <critical-safety-check>
    Before migrating, verify git sync status to prevent data loss.
    </critical-safety-check>

    Check if `.things` is a git repository:

    ```bash
    cd <home>/.things && git rev-parse --git-dir >/dev/null 2>&1 && echo "is-repo" || echo "not-repo"
    ```

    <if condition="is-git-repo">
      ```bash
      cd <home>/.things && git status --porcelain && git status -sb && git log -1 --oneline
      ```

      <if condition="has-uncommitted-changes">
        <output>
        Warning: You have uncommitted changes in `.things`.
        Recommendation: Commit or stash changes before proceeding.
        </output>

        <if condition="not-dry-run">
          <ask-user>Use AskUserQuestion: "You have uncommitted changes. How do you want to proceed?"
            - Continue anyway -- changes will be preserved but uncommitted
            - Abort -- I'll commit first
          </ask-user>
        </if>
      </if>

      <if condition="behind-remote">
        <output>
        Warning: Your local `.things` is behind the remote. Pull before migrating to avoid losing remote changes.
        </output>

        <if condition="not-dry-run">
          <ask-user>Use AskUserQuestion: "Your local .things is behind remote. How do you want to proceed?"
            - Pull and continue -- pull from remote, then migrate
            - Abort -- I'll pull manually
          </ask-user>
        </if>
      </if>
    </if>
  </step>

  <step id="show-plan" number="3">
    <description>Show Migration Plan</description>

    Present the plan based on detected artifacts:

    <output>
    things migration plan:

    <if condition="non-convention-path">Directory relocation:
    - `<old_path>` -> `~/.things/` (convention path)
    </if>

    <if condition="personas-exist">Shared resources:
    - `~/.things/personas/` -> `~/.things/shared/roles/`
    </if>
    <if condition="companies-flat-exist">
    - `~/.things/companies/` -> `~/.things/shared/companies/`
    </if>

    <if condition="config-yml-exists">Cleanup:
    - `config.yml` -> `config.yml.bak` (archived)
    </if>
    <if condition="bootstrap-exists">
    - `~/.claude/things.local.md` removed (legacy bootstrap)
    </if>

    <if condition="old-plugin-data-exists">
    Per-plugin data migration (run separately after this completes):
    <if condition="old-logs">  - `/migrate-idat`</if>
    <if condition="old-interview-prep">  - `/migrate-wdyd`</if>
    <if condition="old-learning">  - `/migrate-wdyk`</if>
    <if condition="old-voices">  - `/migrate-mmw`</if>
    </if>
    </output>

    <if condition="dry-run-flag">Show the plan and stop. Do not modify any files.</if>

    <ask-user>
      Use AskUserQuestion: "Proceed with shared migration?"
      - Yes -- migrate now
      - No -- cancel
    </ask-user>
  </step>

  <step id="relocate-directory" number="4">
    <description>Relocate to Convention Path</description>

    <if condition="non-convention-path">
      ```bash
      mv <old_things_path> <home>/.things
      ```

      <if condition="old-path-different-location">
        Create a symlink for backwards compatibility:

        ```bash
        ln -s <home>/.things <old_things_path>
        ```
      </if>
    </if>

    <if condition="already-at-convention-path">Skip this step.</if>
  </step>

  <step id="create-shared-directories" number="5">
    <description>Create Shared Directories</description>

    ```bash
    mkdir -p <home>/.things/shared/roles
    mkdir -p <home>/.things/shared/companies
    mkdir -p <home>/.things/shared/people
    mkdir -p <home>/.things/shared/contexts
    ```
  </step>

  <step id="move-shared-resources" number="6">
    <description>Move Shared Resources</description>

    <constraint>Use `mv` (not `cp`) to avoid duplicates. Skip items that don't exist.</constraint>

    <phase name="personas-to-roles">
      ```bash
      mv <home>/.things/personas/* <home>/.things/shared/roles/ 2>/dev/null || true
      ```
    </phase>

    <phase name="companies">
      ```bash
      mv <home>/.things/companies/* <home>/.things/shared/companies/ 2>/dev/null || true
      ```
    </phase>
  </step>

  <step id="cleanup" number="7">
    <description>Clean Up Old Artifacts</description>

    <phase name="archive-config-yml">
      <if condition="config-yml-exists">
        ```bash
        mv <home>/.things/config.yml <home>/.things/config.yml.bak
        ```
      </if>
    </phase>

    <phase name="remove-bootstrap">
      <if condition="bootstrap-exists">
        ```bash
        rm <home>/.claude/things.local.md
        ```
      </if>
    </phase>

    <phase name="clean-empty-dirs">
      ```bash
      rmdir <home>/.things/personas 2>/dev/null || true
      rmdir <home>/.things/companies 2>/dev/null || true
      ```
    </phase>

    <phase name="create-local-json">
      <if condition="local-json-missing">
        Write `<home>/.things/local.json`:

        ```json
        {}
        ```

        Ensure `local.json` is in `<home>/.things/.gitignore`.
      </if>
    </phase>
  </step>

  <step id="git-commit" number="8">
    <description>Handle Git</description>

    <git-workflow>
      Read git workflow from `<home>/.things/config.json`.

      <if condition="workflow-auto">
        ```bash
        cd <home>/.things && git add -A && git commit -m "migrate: shared resources to per-plugin structure" && git push
        ```
      </if>
      <if condition="workflow-ask">
        <ask-user>Use AskUserQuestion: "Commit migration changes to .things repo?"
          - Yes -- commit and push
          - Commit only -- commit without pushing
          - No -- I'll handle git myself
        </ask-user>
      </if>
      <if condition="workflow-manual">Tell the user their files have been moved and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="9">
    <description>Confirm and Direct to Per-Plugin Migration</description>

    <completion-message>
    Shared migration complete!

    <if condition="non-convention-path">- Directory relocated to `~/.things/`</if>
    <if condition="personas-moved">- Personas moved to `~/.things/shared/roles/`</if>
    <if condition="companies-moved">- Companies moved to `~/.things/shared/companies/`</if>
    <if condition="config-yml-archived">- config.yml archived as config.yml.bak</if>
    <if condition="bootstrap-removed">- Legacy bootstrap removed</if>

    <if condition="old-plugin-data-exists">
    Next, run per-plugin migrate commands to move your data:

    <if condition="old-logs">
    ```
    /migrate-idat
    ```
    </if>

    <if condition="old-interview-prep">
    ```
    /migrate-wdyd
    ```
    </if>

    <if condition="old-learning">
    ```
    /migrate-wdyk
    ```
    </if>

    <if condition="old-voices">
    ```
    /migrate-mmw
    ```
    </if>
    </if>

    <if condition="no-old-plugin-data">
    No per-plugin data migration needed - all data is already in the right place.
    </if>
    </completion-message>
  </step>

</steps>
