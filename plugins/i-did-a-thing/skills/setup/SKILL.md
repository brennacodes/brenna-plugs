---
name: setup
description: "Configure i-did-a-thing plugin settings: .things directory, git remote, professional goals, and preferences"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

# Set Up i-did-a-thing

Configure the plugin so your accomplishments are tracked, searchable, and ready to fuel resumes, interviews, and blog posts.

This setup uses the shared config used by i-did-a-thing, what-did-you-do, mark-my-words, and what-do-you-know. See `references/things-setup.md` for the full config architecture.

## Steps

### 1. Check for Existing Configuration

Follow the **Bootstrap Detection Flow** from `references/things-setup.md`:

1. Check if `~/.claude/things.local.md` exists
2. If yes, read `things_path` from it
3. Check if `<things_path>/config.yml` exists
4. If both exist → show current settings and ask if they want to reconfigure
5. If bootstrap exists but no config.yml → need to create full config (skip to Step 4)
6. If neither exists → fresh setup (continue to Step 2)

If reconfiguring, show current settings as defaults throughout.

### 2. Gather Storage Settings

Use AskUserQuestion to ask:

**Where should your .things directory live?**
- `~/.things` (home directory — recommended, single source of truth across projects)
- `./things` (current project — good for project-specific logs)
- Custom path

### 3. Create Bootstrap Config

Detect GitHub username:
```bash
gh api user -q .login 2>/dev/null || git config user.name
```

Confirm with user via AskUserQuestion.

Write `~/.claude/things.local.md`:

```yaml
things_path: <chosen_path>
github_username: <username>
```

### 4. Gather Git Remote Settings

Use AskUserQuestion to ask:

**Do you want to sync your .things directory to a git remote?**
- Yes — I have a repo ready
- Yes — create one for me (I'll give you the details)
- No — local only for now

If yes, ask for:
- **Remote URL** (e.g., `git@github.com:username/my-things.git`)
- **Branch** (default: `main`)

**How do you want to manage git for your things?**
- `auto` — automatically commit and push after each log entry
- `ask` — ask me each time whether to commit/push
- `manual` — I'll handle git myself

### 5. Gather Professional Profile

Use AskUserQuestion to ask:

**What's your current role/title?**
(Free text input)

**What's your name?** (for blog posts and logs)
(Free text input)

**What are you targeting professionally?** (Select all that apply)
- Promotion to a specific role
- Lateral move to a new domain
- Building expertise in current role
- Career pivot
- Leadership/management track
- Individual contributor growth

Then ask as free text:
- **Target role(s)** — What role(s) are you working toward?
- **Key skills you're building** — Comma-separated list of skills you're actively developing
- **Skills you want to develop** — Comma-separated list of aspirational skills

### 6. Gather i-did-a-thing Preferences

Use AskUserQuestion to ask:

**Default tags for your logs?** (comma-separated, e.g., `engineering, python, leadership`)

### 7. Initialize the .things Directory

Based on the chosen path, create the directory structure:

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

Run via Bash:
```bash
mkdir -p <things_path>/logs
mkdir -p <things_path>/arsenal
mkdir -p <things_path>/voices
mkdir -p <things_path>/personas
mkdir -p <things_path>/companies
```

If git remote was configured, initialize git:
```bash
cd <things_path>
git init
git remote add origin <remote_url>
git checkout -b <branch>
```

### 8. Write Full Config

Write `<things_path>/config.yml` with all gathered fields. Use the schema from `references/things-setup.md`. Include sensible defaults for what-did-you-do and mark-my-words sections that the user hasn't configured yet:

```yaml
# Identity
github_username: <username>
author_name: <name>

# Git
things_repo: <remote_url or none>
things_branch: <branch>
git_workflow: <auto|ask|manual>

# Professional Profile
current_role: <role>
target_roles:
  - <target>
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

# what-did-you-do (defaults — configured by /what-did-you-do:setup)
interview_prep:
  follow_up_depth: coaching
  default_stage: no-default
  trusted_sources:
    domains: []
    urls: []

# mark-my-words (defaults — configured by /mark-my-words:setup)
blog:
  source_type: remote
  repo_url: ""
  repo_branch: main
  content_dir: content
  default_subdirectory: ""
  default_tags: []
  git_workflow: auto
  default_voice: null
  media_dir: null
  auto_suggest_visuals: false
  ai_image_generation: false

# what-do-you-know (defaults — configured by /what-do-you-know:setup)
learning:
  default_depth: exploratory
  default_persona: staff-engineer
  session_length: medium
  focus_areas: []
```

### 9. Create Initial Index Files

Write `<things_path>/index.json`:

```json
{
  "version": 1,
  "last_updated": "<current_date>",
  "total_entries": 0,
  "entries": []
}
```

Write `<things_path>/tags.json`:

```json
{
  "last_updated": "<current_date>",
  "tags": {}
}
```

### 10. Confirm Setup

Tell the user:

> Your i-did-a-thing setup is complete!
>
> - Things directory: `<path>`
> - Git: `<remote status>`
> - Config: `<things_path>/config.yml`
>
> **Quick start:**
> - `/i-did-a-thing:thing-i-did` — Log something you did
> - `/i-did-a-thing:construct-resume` — Build a resume for a job listing
> - `/what-did-you-do:setup` — Set up interview prep (uses your shared config)
> - `/what-do-you-know:setup` — Set up knowledge reinforcement (uses your shared config)
> - `/mark-my-words:setup` — Set up blogging (uses your shared config)
