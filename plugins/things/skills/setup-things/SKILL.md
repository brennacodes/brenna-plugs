---
name: setup-things
description: "Initialize or reconfigure the .things/ directory - creates config, registry, shared resources, and git repository. Detects and migrates existing config.yml automatically. Required before any brenna-plugs career plugin can store data."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure] [--dry-run]"
---

<purpose>
Initialize the `~/.things/` data directory that all brenna-plugs career plugins depend on. This creates the config, collection registry, shared resource directories, and optional git remote.

When an existing `config.yml` is detected, this skill migrates ALL plugin configs to the new per-plugin format automatically - the user should NOT need to run individual plugin setup commands for config migration.

See `references/config-schema.md` for config schemas and `references/registry-schema.md` for registry schema.
</purpose>

<steps>

  <step id="check-existing" number="1">
    <description>Check for Existing Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    <constraint>The convention path is `<home>/.things/`. No bootstrap file is needed.</constraint>

    Check in this order:

    1. Check if `<home>/.things/config.json` exists
       <if condition="config-json-exists">Show current settings and ask (via AskUserQuestion) if they want to reconfigure.</if>

    2. Check if `<home>/.things/config.yml` exists
       <if condition="config-yml-exists">
       This is a legacy YAML config. Set `migrating_from_yaml = true`.
       Read config.yml and extract ALL data - this will be used to pre-populate everything.
       Skip to Step 2 (git sync check).
       </if>

    3. <if condition="directory-exists-but-no-config">Skip to Step 4 (directory init).</if>
    4. <if condition="neither-exists">Fresh setup (continue to Step 2).</if>

    <if condition="reconfiguring">Show current settings as defaults throughout.</if>
    </load-config>
  </step>

  <step id="check-git-sync" number="2">
    <description>Check Git Sync Status</description>

    <critical-safety-check>
    Before making any changes to `.things`, check if it's a git repository and verify sync status with remote.
    </critical-safety-check>

    Check if `.things` is a git repository:

    ```bash
    cd <home>/.things && git rev-parse --git-dir >/dev/null 2>&1 && echo "is-repo" || echo "not-repo"
    ```

    <if condition="is-git-repo">

    Run these checks and display results prominently in output:

    ```bash
    # Check for uncommitted changes
    cd <home>/.things && git status --porcelain

    # Fetch remote (if remote exists)
    cd <home>/.things && git fetch 2>/dev/null

    # Check local vs remote status
    cd <home>/.things && git status -sb
    ```

    <output>
    ```
    Git Sync Status for ~/.things/
    ├─ Repository: ✓ (git initialized)
    ├─ Remote: <remote_url or "none">
    ├─ Branch: <branch_name>
    ├─ Local commit: <short_sha> <commit_message>
    ├─ Remote commit: <short_sha> <commit_message>
    ├─ Sync status:
    │  └─ <one of:>
    │     • ✓ Up to date with remote
    │     • ⚠ Behind remote by N commits (PULL REQUIRED)
    │     • ⚠ Ahead of remote by N commits (PUSH PENDING)
    │     • ⚠ Diverged from remote (MERGE REQUIRED)
    │     • ℹ No remote configured
    └─ Uncommitted changes: <none or list of modified files>
    ```
    </output>

    <if condition="has-uncommitted-changes">
    WARNING: You have uncommitted changes in `.things`.
       - The migration will preserve your files but may conflict with uncommitted work
       - Recommendation: Commit or stash changes before proceeding
    </if>

    <if condition="behind-remote">
    WARNING: Your local `.things` is behind the remote by N commits.
       - Running migration without pulling could cause you to lose remote changes
       - Recommendation: Pull from remote first, then run migration
    </if>

    <if condition="diverged-from-remote">
    WARNING: Your local and remote `.things` have diverged.
       - This will require manual merge resolution
       - Recommendation: Resolve divergence before running migration
    </if>

    <if condition="ahead-of-remote">
    INFO: You have N unpushed commits locally.
       - These will be preserved during migration
       - Remember to push after migration completes
    </if>

    </if>

    <if condition="not-git-repo">
    <output>
    ```
    Git Sync Status for ~/.things/
    └─ Repository: ✗ (not initialized)
       └─ Git will be initialized during setup if you configure a remote
    ```
    </output>
    </if>
  </step>

  <step id="detect-username" number="3">
    <description>Detect GitHub Username</description>

    ```bash
    gh api user -q .login 2>/dev/null || git config user.name
    ```

    <if condition="migrating_from_yaml">Use the `github_username` from config.yml as the default.</if>

    Use AskUserQuestion to confirm the detected username with the user.
  </step>

  <step id="init-directory" number="4">
    <description>Initialize .things/ Directory</description>

    Create the directory structure:

    ```bash
    mkdir -p <home>/.things/shared/people
    mkdir -p <home>/.things/shared/roles
    mkdir -p <home>/.things/shared/contexts
    mkdir -p <home>/.things/shared/companies
    mkdir -p <home>/.things/tags
    ```

    <output-path>`<home>/.things/.gitignore`</output-path>

    <template name="gitignore">

    ```
    *.tmp
    .DS_Store
    local.json
    ```

    </template>

    <output-path>`<home>/.things/local.json`</output-path>

    <schema name="local-json">
    Machine-specific overrides, gitignored:

    ```json
    {}
    ```

    </schema>
  </step>

  <step id="gather-git-settings" number="5">
    <description>Gather Git Remote Settings</description>

    <if condition="migrating_from_yaml">
    Use values from config.yml: `things_repo` (remote), `things_branch` (branch), `git_workflow` (workflow).
    Show the extracted values to the user and use AskUserQuestion to confirm:
    - "I found these git settings in your existing config. Look correct?"
    - Options: "Yes, use these" / "No, let me change them"
    <if condition="user-wants-changes">Ask the individual questions below.</if>
    <if condition="user-confirms">Skip to git init phase.</if>
    </if>

    <if condition="fresh-setup">
    Use AskUserQuestion:

    Do you want to sync your .things directory to a git remote?
    <options>
    - Yes -- I have a repo ready
    - Yes -- create one for me (I'll give you the details)
    - No -- local only for now
    </options>

    <if condition="wants-git-remote">
    Use AskUserQuestion to ask for:
    - Remote URL (e.g., `git@github.com:username/my-things.git`)
    - Branch (default: `main`)
    </if>

    Use AskUserQuestion:

    How do you want to manage git for your things?
    <options>
    - `auto` -- automatically commit and push after changes
    - `ask` -- ask me each time whether to commit/push
    - `manual` -- I'll handle git myself
    </options>
    </if>

    <phase name="git-init" number="1">
    Initialize git (if not already a repo):

    ```bash
    cd <home>/.things
    git init
    git remote add origin <remote_url>  # if configured
    git checkout -b <branch>
    ```
    </phase>
  </step>

  <step id="gather-profile" number="6">
    <description>Gather Professional Profile</description>

    <if condition="migrating_from_yaml">
    Use values from config.yml: `author_name`, `current_role`, `target_roles`, `career_direction`, `building_skills`, `aspirational_skills`.
    Show extracted profile to user and use AskUserQuestion to confirm:
    - "I found this professional profile in your existing config. Look correct?"
    - Options: "Yes, use this" / "No, let me update it"
    <if condition="user-wants-changes">Ask the individual questions below.</if>
    <if condition="user-confirms">Skip to next step.</if>
    </if>

    <if condition="fresh-setup">
    Use AskUserQuestion for each:

    What's your name? (for blog posts, logs, and attribution)

    What's your current role/title?

    What are you targeting professionally? (Select all that apply)
    <options>
    - Promotion to a specific role
    - Lateral move to a new domain
    - Building expertise in current role
    - Career pivot
    - Leadership/management track
    - Individual contributor growth
    </options>

    Then use AskUserQuestion for free text:
    - Target role(s) -- What role(s) are you working toward?
    - Key skills you're building -- Comma-separated list of skills you're actively developing
    - Skills you want to develop -- Comma-separated list of aspirational skills
    </if>
  </step>

  <step id="detect-environment" number="7">
    <description>Detect Environment</description>

    Get the machine hostname for environment tracking:

    ```bash
    hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown"
    ```

    <rule>This is stored in `config.json` to track which machines use which plugins.</rule>
  </step>

  <step id="handle-dry-run" number="8">
    <description>Handle Dry Run</description>

    <if condition="--dry-run argument was passed">
    Show everything that WOULD happen (all files that would be created, all values that would be used) but do NOT write any files. Include the full migration plan if migrating from YAML.
    Stop here after showing the dry-run summary.
    </if>
  </step>

  <step id="write-configs" number="9">
    <description>Write Config Files</description>

    <output-path>`<home>/.things/config.json`</output-path>

    <schema name="config-json">

    ```json
    {
      "version": "1.0.0",
      "github_username": "<username>",
      "git": {
        "remote": "<remote_url or null>",
        "branch": "<branch>",
        "workflow": "<auto|ask|manual>"
      },
      "environments": {
        "<hostname>": {
          "first_seen": "<current_date>",
          "last_active": "<current_date>",
          "plugins": ["things"]
        }
      }
    }
    ```

    <if condition="migrating_from_yaml">
    Include ALL plugins found in config.yml in the `plugins` array. Check config.yml for these sections:
    - `logging` section → include `"i-did-a-thing"`
    - `interview_prep` section → include `"what-did-you-do"`
    - `learning` section → include `"what-do-you-know"`
    - `blog` section → include `"mark-my-words"`
    </if>

    </schema>

    <output-path>`<home>/.things/registry.json`</output-path>

    <schema name="registry-json">
    Pre-register the four shared collections:

    ```json
    {
      "version": "1.0.0",
      "collections": {
        "shared/people": {
          "plugin": "things",
          "description": "Shared people profiles accessible to all plugins",
          "tags_field": null,
          "item_structure": {
            "directory_per_item": true,
            "required_files": ["profile.md", "index.json"],
            "optional_file_patterns": ["*.md"],
            "index_file": "index.json"
          },
          "index_schema": {
            "required_fields": {
              "id": "string",
              "display_name": "string",
              "tags": "string[]",
              "created": "date"
            },
            "optional_fields": {
              "source_references": "string[]",
              "speculative": "boolean"
            }
          },
          "master_index": "shared/people/master-index.json",
          "rebuild_command": null
        },
        "shared/roles": {
          "plugin": "things",
          "description": "Shared role definitions accessible to all plugins",
          "tags_field": null,
          "item_structure": {
            "directory_per_item": false,
            "file_pattern": "*.md"
          },
          "index_schema": {},
          "master_index": null,
          "rebuild_command": null
        },
        "shared/contexts": {
          "plugin": "things",
          "description": "Shared activity context definitions",
          "tags_field": null,
          "item_structure": {
            "directory_per_item": false,
            "file_pattern": "*.md"
          },
          "index_schema": {},
          "master_index": null,
          "rebuild_command": null
        },
        "shared/companies": {
          "plugin": "things",
          "description": "Shared company profiles",
          "tags_field": null,
          "item_structure": {
            "directory_per_item": false,
            "file_pattern": "*.yaml"
          },
          "index_schema": {},
          "master_index": null,
          "rebuild_command": null
        }
      }
    }
    ```

    </schema>

    <output-path>`<home>/.things/shared/people/master-index.json`</output-path>

    <schema name="people-master-index">

    ```json
    {
      "version": 1,
      "last_updated": "<current_date>",
      "total_items": 0,
      "items": []
    }
    ```

    </schema>

    <output-path>`<home>/.things/shared/professional-profile.json`</output-path>

    <schema name="professional-profile">

    ```json
    {
      "author_name": "<name>",
      "current_role": "<role>",
      "target_roles": ["<target>"],
      "career_direction": ["<direction>"],
      "building_skills": ["<skill>"],
      "aspirational_skills": ["<skill>"]
    }
    ```

    </schema>
  </step>

  <step id="migrate-plugin-configs" number="10">

    <description>Migrate Plugin Configs from YAML</description>

    <constraint>Only run this step when `migrating_from_yaml` is true. Skip entirely for fresh setups.</constraint>

    For each plugin with data in config.yml, create the per-plugin directory, preferences.json, and basic operational files. This ensures plugins work out of the box without requiring individual setup commands.

    <phase name="i-did-a-thing" number="1">
      <description>i-did-a-thing config migration</description>

      <if condition="config.yml has logging section">

      Create directories:
      ```bash
      mkdir -p <home>/.things/i-did-a-thing/logs
      mkdir -p <home>/.things/i-did-a-thing/arsenal
      mkdir -p <home>/.things/i-did-a-thing/resumes
      ```

      <output-path>`<home>/.things/i-did-a-thing/preferences.json`</output-path>
      ```json
      {
        "default_tags": ["<from config.yml logging.default_tags>"]
      }
      ```

      <if condition="index.json missing">
      <output-path>`<home>/.things/i-did-a-thing/index.json`</output-path>
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_entries": 0,
        "entries": []
      }
      ```
      </if>

      <if condition="tags.json missing">
      <output-path>`<home>/.things/i-did-a-thing/tags.json`</output-path>
      ```json
      {
        "last_updated": "<current_date>",
        "tags": {}
      }
      ```
      </if>

      </if>
    </phase>

    <phase name="what-did-you-do" number="2">
      <description>what-did-you-do config migration</description>

      <if condition="config.yml has interview_prep section">

      Create directories:
      ```bash
      mkdir -p <home>/.things/what-did-you-do/sessions
      mkdir -p <home>/.things/what-did-you-do/questions
      ```

      <output-path>`<home>/.things/what-did-you-do/preferences.json`</output-path>
      ```json
      {
        "follow_up_depth": "<from config.yml interview_prep.follow_up_depth or 'detailed'>",
        "default_stage": "<from config.yml interview_prep.default_stage or 'no-default'>",
        "trusted_sources": {
          "domains": ["<from config.yml interview_prep.trusted_sources.domains or []>"],
          "urls": ["<from config.yml interview_prep.trusted_sources.urls or []>"]
        }
      }
      ```

      <if condition="progress.json missing">
      <output-path>`<home>/.things/what-did-you-do/progress.json`</output-path>
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_sessions": 0,
        "last_session": null,
        "dimensions": {
          "specificity": { "average": null, "trend": "stable" },
          "structure": { "average": null, "trend": "stable" },
          "impact": { "average": null, "trend": "stable" },
          "relevance": { "average": null, "trend": "stable" },
          "self_advocacy": { "average": null, "trend": "stable" }
        },
        "strongest_categories": [],
        "weakest_categories": [],
        "sessions": []
      }
      ```
      </if>

      </if>
    </phase>

    <phase name="what-do-you-know" number="3">
      <description>what-do-you-know config migration</description>

      <if condition="config.yml has learning section">

      Create directories:
      ```bash
      mkdir -p <home>/.things/what-do-you-know/sessions
      mkdir -p <home>/.things/what-do-you-know/study-plans
      ```

      <output-path>`<home>/.things/what-do-you-know/preferences.json`</output-path>
      ```json
      {
        "default_depth": "<from config.yml learning.default_depth or 'exploratory'>",
        "default_persona": "<from config.yml learning.default_persona or null>",
        "session_length": "<from config.yml learning.session_length or 'medium'>",
        "focus_areas": ["<from config.yml learning.focus_areas or []>"]
      }
      ```

      <if condition="progress.json missing">
      <output-path>`<home>/.things/what-do-you-know/progress.json`</output-path>
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_sessions": 0,
        "last_session": null,
        "dimensions": {
          "depth": { "average": null, "trend": "stable" },
          "accuracy": { "average": null, "trend": "stable" },
          "connections": { "average": null, "trend": "stable" },
          "application": { "average": null, "trend": "stable" },
          "articulation": { "average": null, "trend": "stable" }
        },
        "strongest_topics": [],
        "weakest_topics": [],
        "sessions": []
      }
      ```
      </if>

      <if condition="knowledge-map.json missing">
      <output-path>`<home>/.things/what-do-you-know/knowledge-map.json`</output-path>
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "strong": [],
        "building": [],
        "gap": [],
        "blind_spot": []
      }
      ```
      </if>

      </if>
    </phase>

    <phase name="mark-my-words" number="4">
      <description>mark-my-words config migration</description>

      <if condition="config.yml has blog section">

      Create directories:
      ```bash
      mkdir -p <home>/.things/mark-my-words/voices
      ```

      <output-path>`<home>/.things/mark-my-words/preferences.json`</output-path>
      ```json
      {
        "platform": "<from config.yml blog.platform or null>",
        "source_type": "<from config.yml blog.source_type or 'remote'>",
        "repo_url": "<from config.yml blog.repo_url or null>",
        "repo_branch": "<from config.yml blog.repo_branch or 'main'>",
        "content_dir": "<from config.yml blog.content_dir or null>",
        "default_subdirectory": "<from config.yml blog.default_subdirectory or null>",
        "default_tags": ["<from config.yml blog.default_tags or []>"],
        "git_workflow": "<from config.yml blog.git_workflow or 'ask'>",
        "workdir": "<home>/.mark-my-words",
        "default_voice": "<from config.yml blog.default_voice or null>",
        "media_dir": "<from config.yml blog.media_dir or null>",
        "auto_suggest_visuals": "<from config.yml blog.auto_suggest_visuals or true>",
        "ai_image_generation": "<from config.yml blog.ai_image_generation or false>"
      }
      ```

      </if>
    </phase>

    <phase name="think-like" number="5">
      <description>think-like defaults</description>

      Create directories:
      ```bash
      mkdir -p <home>/.things/think-like/profiles
      mkdir -p <home>/.things/think-like/sessions
      ```

      <if condition="preferences.json missing">
      <output-path>`<home>/.things/think-like/preferences.json`</output-path>
      ```json
      {
        "default_profile": null,
        "session_logging": true
      }
      ```
      </if>

      <if condition="master-index.json missing">
      <output-path>`<home>/.things/think-like/profiles/master-index.json`</output-path>
      ```json
      {
        "version": 1,
        "last_updated": "<current_date>",
        "total_profiles": 0,
        "profiles": []
      }
      ```
      </if>
    </phase>

    <phase name="show-migration-summary" number="6">
      <description>Show migration summary</description>

      Show the user a summary of what was migrated:

      <output>
      Plugin configs migrated from config.yml:
      - i-did-a-thing: preferences.json (default_tags: [...])
      - what-did-you-do: preferences.json (follow_up_depth: ..., default_stage: ...)
      - what-do-you-know: preferences.json (default_depth: ..., session_length: ...)
      - mark-my-words: preferences.json (platform: ..., repo_url: ...)
      - think-like: preferences.json (defaults)

      config.yml has been preserved (not deleted). It can be removed after verifying the migration.
      </output>
    </phase>
  </step>

  <step id="initial-commit" number="11">
    <description>Initial Commit</description>

    <git-workflow>
    <if condition="git-configured">

    ```bash
    cd <home>/.things
    git add -A
    git commit -m "Initialize .things directory"
    ```

    <if condition="migrating_from_yaml">Use commit message: "Migrate config.yml to v1.0.0 per-plugin structure"</if>

    <if condition="workflow-auto">

    ```bash
    git push -u origin <branch>
    ```

    </if>
    <if condition="workflow-ask">Use AskUserQuestion to ask the user whether to push.</if>
    <if condition="workflow-manual">Skip.</if>
    </if>
    </git-workflow>
  </step>

  <step id="confirm-setup" number="12">
    <description>Confirm Setup</description>

    <completion-message>

    <if condition="migrating_from_yaml">
    <output>
    Your .things directory has been migrated to v1.0.0!

    - Location: `<home>/.things`
    - Git: `<remote status>`
    - Config: `config.json` (migrated from config.yml)
    - Profile: `shared/professional-profile.json`
    - Registry: `registry.json` (4 shared collections)
    - Environment: `<hostname>` tracked

    Plugin configs migrated:
    - i-did-a-thing/preferences.json
    - what-did-you-do/preferences.json
    - what-do-you-know/preferences.json
    - mark-my-words/preferences.json
    - think-like/preferences.json

    Your existing data files (logs, sessions, voices, etc.) are still in their original locations.
    Run `/migrate` to relocate them to the new per-plugin directory structure.

    config.yml has been preserved as a backup.
    </output>
    </if>

    <if condition="fresh-setup">
    <output>
    Your .things directory is ready!

    - Location: `<home>/.things`
    - Git: `<remote status>`
    - Config: `<home>/.things/config.json`
    - Registry: `<home>/.things/registry.json` (4 shared collections registered)
    - Environment: `<hostname>` tracked

    Start using plugins:
    - `/thing-i-did` -- Log an accomplishment
    - `/profile dhh code-review` -- Run an expert code review
    - `/status` -- See what's in your .things directory

    Individual plugins will set up their directories on first use, or you can run their setup commands to pre-configure preferences.
    </output>
    </if>

    </completion-message>
  </step>

</steps>
