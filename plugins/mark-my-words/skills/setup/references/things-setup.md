# Things Shared Setup Reference

All four career plugins (i-did-a-thing, what-did-you-do, mark-my-words, what-do-you-know) share a centralized config system. This document defines the bootstrap and config flows used by all setup skills.

## Config Architecture

### Bootstrap Config (machine-local)

File: `~/.claude/things.local.md`

Contains only machine-specific settings. Not committed to git.

```yaml
things_path: ~/.things
github_username: brennacodes
```

### Full Config (in things repo, git-tracked)

File: `<things_path>/config.yml`

Contains all settings for all four plugins. Committed to the things repo for cross-machine sync.

```yaml
# Identity
github_username: <username>
author_name: <name>

# Git
things_repo: <remote_url>
things_branch: main
git_workflow: auto

# Professional Profile (shared by all career plugins)
current_role: <role>
target_roles:
  - <role>
career_direction:
  - <direction>
building_skills:
  - <skill>
aspirational_skills:
  - <skill>

# i-did-a-thing
logging:
  default_tags:
    - <tag>

# what-did-you-do
interview_prep:
  follow_up_depth: coaching
  default_stage: no-default
  trusted_sources:
    domains: []
    urls: []

# mark-my-words
blog:
  source_type: remote
  repo_url: <url>
  repo_branch: main
  content_dir: content
  default_subdirectory: ""
  default_tags:
    - <tag>
  git_workflow: auto
  default_voice: null
  media_dir: null
  auto_suggest_visuals: false
  ai_image_generation: false

# what-do-you-know
learning:
  default_depth: exploratory
  default_persona: staff-engineer
  session_length: medium
  focus_areas: []
```

### Voices (in things repo)

Directory: `<things_path>/voices/`

Voice profiles are stored in the things repo for cross-machine sync, not in `.claude/voices/`.

### Personas (shared)

Directory: `<things_path>/personas/`

Seven coaching personas (staff-engineer, engineering-manager, principal-engineer, vp-engineering, cto, recruiter, bar-raiser) shared by what-did-you-do and what-do-you-know. Each plugin bundles seed defaults; setup skills copy them to the things repo if not already present. User customizations are never overwritten.

### Companies (shared)

Directory: `<things_path>/companies/`

Company profiles (amazon.yaml, google.yaml, meta.yaml + user-created) shared across plugins. Users add custom companies here. Setup skills seed defaults from bundled copies if not already present.

## Bootstrap Detection Flow

Used by all setup skills to determine current state:

1. Check if `~/.claude/things.local.md` exists
2. If yes, read `things_path` from it
3. Check if `<things_path>/config.yml` exists
4. If both exist → config is complete, show current settings and offer reconfigure
5. If bootstrap exists but no config.yml → need to create full config
6. If neither exists → fresh setup

## Bootstrap Creation Flow

When no `~/.claude/things.local.md` exists:

1. **Detect GitHub username**: Try `gh api user -q .login`, fall back to `git config user.name`
2. **Confirm username** with user via AskUserQuestion
3. **Ask for things_path**: Where should the .things directory live?
   - `~/.things` (home directory — recommended, single source of truth)
   - `./things` (project-local)
   - Custom path
4. **Write `~/.claude/things.local.md`**:
   ```yaml
   things_path: <chosen_path>
   github_username: <username>
   ```

## Full Config Creation Flow

When `config.yml` doesn't exist yet:

1. **Initialize directory structure**:
   ```
   <things_path>/
   ├── logs/
   ├── arsenal/
   ├── voices/
   ├── personas/
   ├── companies/
   ├── index.json
   ├── tags.json
   └── config.yml
   ```

2. **Gather professional profile** (shared by all plugins):
   - Current role/title (free text)
   - Target roles (free text)
   - Career direction (multi-select):
     - Building expertise in current role
     - Promotion to a specific role
     - Lateral move to a new domain
     - Career pivot
     - Leadership/management track
     - Individual contributor growth
   - Skills building (comma-separated)
   - Aspirational skills (comma-separated)
   - Author name for blog posts

3. **Gather git settings**:
   - Remote URL (or none)
   - Branch (default: main)
   - Git workflow: auto / ask / manual

4. **Write `config.yml`** with shared fields + plugin-specific defaults

## Config Schema Reference

### Shared Fields

| Field | Type | Description |
|-------|------|-------------|
| `github_username` | string | GitHub username |
| `author_name` | string | Display name for blog posts and logs |
| `things_repo` | string | Git remote URL for things directory |
| `things_branch` | string | Git branch (default: main) |
| `git_workflow` | string | auto, ask, or manual |
| `current_role` | string | Current job title |
| `target_roles` | list | Roles being targeted |
| `career_direction` | list | Professional growth directions |
| `building_skills` | list | Skills actively being developed |
| `aspirational_skills` | list | Skills to develop next |

### i-did-a-thing Fields (`logging:`)

| Field | Type | Description |
|-------|------|-------------|
| `default_tags` | list | Default tags for new log entries |

### what-did-you-do Fields (`interview_prep:`)

| Field | Type | Description |
|-------|------|-------------|
| `follow_up_depth` | string | concise, detailed, or coaching |
| `default_stage` | string | Interview stage or no-default |
| `trusted_sources.domains` | list | Trusted domains for question updates |
| `trusted_sources.urls` | list | Trusted URLs for question updates |

### mark-my-words Fields (`blog:`)

| Field | Type | Description |
|-------|------|-------------|
| `source_type` | string | remote or local |
| `repo_url` | string | Blog git remote URL |
| `repo_branch` | string | Blog git branch |
| `content_dir` | string | Root content directory name |
| `default_subdirectory` | string | Subdirectory for new posts |
| `default_tags` | list | Default blog tags |
| `git_workflow` | string | Blog-specific git workflow |
| `default_voice` | string/null | Default voice profile name |
| `media_dir` | string/null | Media directory relative to content |
| `auto_suggest_visuals` | bool | Auto-suggest diagrams/images |
| `ai_image_generation` | bool | Enable AI image generation option |

### what-do-you-know Fields (`learning:`)

| Field | Type | Description |
|-------|------|-------------|
| `default_depth` | string | exploratory, focused, or deep |
| `default_persona` | string | Default persona for learning sessions |
| `session_length` | string | short (15 min), medium (30 min), or deep (60 min) |
| `focus_areas` | list | Topics to focus on (empty = follow building_skills + aspirational_skills) |
