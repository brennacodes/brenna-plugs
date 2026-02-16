---
name: setup
description: Configure mark-my-words for your Quartz blog. Sets up source location, author info, and preferences.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# mark-my-words Setup

You are configuring the mark-my-words plugin for the user's Quartz blog. Your job is to gather their settings and update the shared trio config.

This setup uses the centralized trio config shared by all trio plugins. See `references/trio-setup.md` for the full config architecture.

## Steps

### 1. Check for Existing Configuration

Follow the **Bootstrap Detection Flow** from `references/trio-setup.md`:

1. Check if `.claude/trio.local.md` exists
2. If yes, read `things_path` from it
3. Check if `<things_path>/config.yml` exists

**If both exist**: Read `config.yml` and check the `blog:` section. If it has non-default values (e.g., `repo_url` is not empty), tell the user their current settings and ask if they want to reconfigure.

**If bootstrap exists but no config.yml**: Tell the user:

> Found your bootstrap config but no full config. Please run `/i-did-a-thing:setup` first to create the shared config.

Then stop.

**If neither exists**: Tell the user:

> No configuration found. Please run `/i-did-a-thing:setup` first to set up your shared config.

Then stop.

### 2. Gather Blog Source Info

Use AskUserQuestion to ask where their Quartz blog content lives:

Ask about **source type**:
- "Remote git repo" — they'll provide a repo URL and branch
- "Local directory" — they'll provide a path to their Quartz content root

### 3. Source Details

**If remote**: Use AskUserQuestion to ask for:
- Repository URL (e.g., `git@github.com:user/blog.git` or HTTPS URL)
- Branch name (suggest `main` as default)

**If local**: Use AskUserQuestion to ask for the path to their Quartz content root directory.

### 4. Gather Content Preferences

Use AskUserQuestion for each:
- **Content directory name**: The root content directory (e.g., `content`). This is the top-level folder Quartz reads from.
- **Default subdirectory**: Where new posts go within the content directory (e.g., `blog`, `notes`, or empty for root). Suggest common options.
- **Default tags**: Comma-separated list of tags they commonly use. These will be suggested when creating posts.

### 5. Git Workflow Preference

Use AskUserQuestion:
- "Always ask" — prompt before each commit/push
- "Auto-commit" — automatically commit and push after changes
- "Manual" — never auto-commit, user handles git themselves

### 6. Media Preferences

Use AskUserQuestion for each:

**Media directory**: "Where should images and media files be stored? This is a path relative to your content directory (e.g., `assets/images`). If you skip this, media features will be limited to inline content like Mermaid diagrams."
- Provide a path (e.g., `assets/images`, `media`, `img`)
- Skip — no local media management

If they provide a path, set `media_dir` to it. If they skip, set `media_dir: null`.

**Auto-suggest visuals**: "Should mark-my-words proactively suggest diagrams and images as it writes?"
- Yes → `auto_suggest_visuals: true`
- No → `auto_suggest_visuals: false`

**AI image generation**: "Do you want the option to generate images with AI tools?"
- Yes → `ai_image_generation: true`
- No → `ai_image_generation: false`

### 7. Update Config

Read `<things_path>/config.yml` and update the `blog:` section with the user's preferences:

```yaml
blog:
  source_type: <remote|local>
  repo_url: <url>
  repo_branch: <branch>
  content_dir: <dir>
  default_subdirectory: <subdir>
  default_tags:
    - <tag>
  git_workflow: <ask|auto|manual>
  default_voice: null
  media_dir: <path or null>
  auto_suggest_visuals: <true|false>
  ai_image_generation: <true|false>
```

Use Edit to update only the `blog:` section, preserving all other config.

### 8. Voice Profile (optional)

Use AskUserQuestion:

> **Would you like to create a voice profile?** Voice profiles teach mark-my-words how you actually write, so posts sound like you instead of generic AI.
> - Yes — set one up now
> - Later — I'll run `/mark-my-words:create-voice` when I'm ready
> - No thanks — I'll skip voice profiles

If "Yes": Tell the user to run `/mark-my-words:create-voice` after setup completes — it needs writing samples and works best as its own step. Note that they can create multiple voice profiles and switch between them.

If "Later" or "No thanks": Move on.

### 9. Confirm

Tell the user their config has been saved and they can now use `/mark-my-words:new-post`, `/mark-my-words:update-post`, `/mark-my-words:manage-post`, and `/mark-my-words:add-media`.

If they said yes to voice profiles, remind them:

> Run `/mark-my-words:create-voice` to set up your writing voice. Voice profiles are stored in `<things_path>/voices/` for cross-machine sync.
