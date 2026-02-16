---
name: setup
description: Configure mark-my-words for your blog. Sets up platform, source location, and preferences.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# mark-my-words Setup

You are configuring the mark-my-words plugin for the user's blog. Your job is to gather their settings and update the shared config.

This setup uses the shared config used by all career plugins. See `references/things-setup.md` for the full config architecture.

## Steps

### 1. Check for Existing Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Follow the **Bootstrap Detection Flow** from `references/things-setup.md`:

1. Check if `<home>/.claude/things.local.md` exists
2. If yes, read `things_path` from it (if `things_path` starts with `~`, replace with `<home>`)
3. Check if `<things_path>/config.yml` exists

**If both exist**: Read `config.yml` and check the `blog:` section. If it has non-default values (e.g., `repo_url` is not empty), tell the user their current settings and ask if they want to reconfigure.

**If bootstrap exists but no config.yml**: Tell the user:

> Found your bootstrap config but no full config. Please run `/i-did-a-thing:setup` first to create the shared config.

Then stop.

**If neither exists**: Tell the user:

> No configuration found. Please run `/i-did-a-thing:setup` first to set up your shared config.

Then stop.

### 2. Select Platform

Use AskUserQuestion to ask which blogging platform they use:

- **Quartz** — Obsidian-compatible static site (wikilinks, callouts, Mermaid)
- **Hugo** — Popular Go-based static site generator
- **Jekyll** — Ruby-based, GitHub Pages default
- **Astro** — Modern web framework with content collections
- **Eleventy (11ty)** — Flexible JavaScript-based static site generator
- **Docusaurus** — React-based docs and blog platform (admonitions, MDX)
- **Zola** — Fast Rust-based static site generator (TOML frontmatter)

Store the selection as the `platform` value (lowercase: `quartz`, `hugo`, `jekyll`, `astro`, `eleventy`, `docusaurus`, `zola`).

Read the platform template from `<plugin_root>/platforms/<platform>.md` to get platform-specific defaults for the steps below. Use the "Platform Info" table and "Frontmatter" section to inform your suggestions.

### 3. Gather Blog Source Info

Use AskUserQuestion to ask where their blog content lives:

Ask about **source type**:
- "Remote git repo" — they'll provide a repo URL and branch
- "Local directory" — they'll provide a path to their content root

### 4. Source Details

**If remote**: Use AskUserQuestion to ask for:
- Repository URL (e.g., `git@github.com:user/blog.git` or HTTPS URL)
- Branch name (suggest `main` as default)

**If local**: Use AskUserQuestion to ask for the path to their content root directory.

### 5. Gather Content Preferences

Use the platform template's "Platform Info" table to suggest sensible defaults.

Use AskUserQuestion for each:

- **Content directory name**: The root content directory. Suggest the platform default:
  - Quartz: `content`
  - Hugo: `content`
  - Jekyll: `_posts` (note: Jekyll also uses `_drafts` for draft posts)
  - Astro: `src/content/blog`
  - Eleventy: varies — ask the user (common: `src/posts`, `content`, `posts`)
  - Docusaurus: `blog`
  - Zola: `content`

- **Default subdirectory**: Where new posts go within the content directory. Suggest the platform default:
  - Quartz: flexible (`blog/`, `notes/`, or empty)
  - Hugo: `posts/` or `blog/`
  - Jekyll: empty (posts go directly in `_posts/`)
  - Astro: empty (posts go directly in blog collection)
  - Eleventy: empty (posts go directly in posts directory)
  - Docusaurus: empty (posts go directly in `blog/`)
  - Zola: `blog/` (organized as sections)

- **Default tags**: Comma-separated list of tags they commonly use. These will be suggested when creating posts.

### 6. Git Workflow Preference

Use AskUserQuestion:
- "Always ask" — prompt before each commit/push
- "Auto-commit" — automatically commit and push after changes
- "Manual" — never auto-commit, user handles git themselves

### 7. Media Preferences

Use AskUserQuestion for each:

**Media directory**: "Where should images and media files be stored? This is a path relative to your content directory." Suggest the platform default:
  - Quartz: `assets/images`
  - Hugo: `static/images` (note: Hugo serves `static/` at site root)
  - Jekyll: `assets/images`
  - Astro: `public/images`
  - Eleventy: `img` or `images`
  - Docusaurus: `static/img`
  - Zola: `static/images`

Provide a "Skip" option — no local media management. If they skip, set `media_dir: null`.

**Auto-suggest visuals**: "Should mark-my-words proactively suggest diagrams and images as it writes?"
- Yes → `auto_suggest_visuals: true`
- No → `auto_suggest_visuals: false`

**AI image generation**: "Do you want the option to generate images with AI tools?"
- Yes → `ai_image_generation: true`
- No → `ai_image_generation: false`

### 8. Update Config

Read `<things_path>/config.yml` and update the `blog:` section with the user's preferences:

```yaml
blog:
  platform: <platform>
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

### 9. Voice Profile (optional)

Use AskUserQuestion:

> **Would you like to create a voice profile?** Voice profiles teach mark-my-words how you actually write, so posts sound like you instead of generic AI.
> - Yes — set one up now
> - Later — I'll run `/mark-my-words:create-voice` when I'm ready
> - No thanks — I'll skip voice profiles

If "Yes": Tell the user to run `/mark-my-words:create-voice` after setup completes — it needs writing samples and works best as its own step. Note that they can create multiple voice profiles and switch between them.

If "Later" or "No thanks": Move on.

### 10. Confirm

Tell the user their config has been saved and they can now use `/mark-my-words:new-post`, `/mark-my-words:update-post`, `/mark-my-words:manage-post`, and `/mark-my-words:add-media`.

If they said yes to voice profiles, remind them:

> Run `/mark-my-words:create-voice` to set up your writing voice. Voice profiles are stored in `<things_path>/voices/` for cross-machine sync.
