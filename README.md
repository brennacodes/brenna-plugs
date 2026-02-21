# brenna-plugs

![installs](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbrennacodes%2Fbrenna-plugs%2Fmain%2F.github%2Fdata%2Fclones.json&query=%24.total&label=installs&color=brightgreen)

This is where I plugin.

Forgive the cheezy names - we all have to get our kicks somewhere.

## 8 Plugins

| Plugin | What it does | Plugin-specific README |
|--------|-------------|------------------------|
| [**heres-the-thing**](#heres-the-thing) | Shared data layer for `~/.things/` — config, registry, migration, sync | [README](plugins/heres-the-thing/README.md) |
| [**i-did-a-thing**](#i-did-a-thing) | Log professionally-relevant experiences, build a searchable evidence arsenal, generate tailored resumes | [README](plugins/i-did-a-thing/README.md) |
| [**what-did-you-do**](#what-did-you-do) | Practice interviews with persona-driven coaching, powered by your logged evidence | [README](plugins/what-did-you-do/README.md) |
| [**what-do-you-know**](#what-do-you-know) | Deepen understanding through concept quizzing, gap analysis, and learning plans | [README](plugins/what-do-you-know/README.md) |
| [**mark-my-words**](#mark-my-words) | Write and publish blog posts across 7 static-site platforms — standalone or from your evidence logs | [README](plugins/mark-my-words/README.md) |
| [**think-like**](#think-like) | Expert thinking profiles for code review, architecture, security, and debugging | [README](plugins/think-like/README.md) |
| [**screenshotr**](#screenshotr) | Precise macOS screenshots with crop, resize, and format control | [README](plugins/screenshotr/README.md) |
| [**session-scout**](#session-scout) | Search, browse, and resume Claude Code sessions across all projects | |

## Overview

> [!WARNING]
> **Upgrading from v3?** Version 4 introduced breaking changes to the config and data layout. Your data is safe, but you'll need to migrate. See [Migrating from v3](#migrating-from-v3) for details.

Five career-focused plugins share a single config and data layer at `~/.things/`, powered by **heres-the-thing** (HTT). Log an experience once, then use that experience to for knowledge reinforcement through `what-do-you-know` or interview prep and resume building through `what-did-you-do`. Feed urls or reference material to `mark-my-words` and it creates a voice profile for you to use in blog posts. Feed those same urls or reference material to `think-like` and it creates expert-driven planning, reviews, and audits without re-telling the story. All git-tracked so you can take your things with you and never miss a beat.

**screenshotr** and **session-scout** are standalone utilities with no `.things/` dependency.

Set up the foundation first with:

```
/setup-htt
```

Then configure each plugin's specialties with its own setup skill (e.g. `/setup-idat`, `/setup-wdyd`, etc.). When HTT detects an existing `config.yml`, it migrates all plugin configs automatically.

| Log it | Practice it | Learn from it | Write about it | Think like an expert |
| --- | --- | --- | --- | --- |
| `/thing-i-did` | `/practice` | `/explore` | `/from-things` | `/profile` |
| **evidence arsenal**<br>**resume bullets**<br>**interview talking points** | **coached feedback**<br>**readiness scores**<br>**gap identification** | **concept maps**<br>**gap analysis**<br>**learning plans** | **published post**<br>**first-person story**<br>**blog with metrics** | **code review**<br>**architecture plans**<br>**security analysis** |

## Installation

### Add the marketplace
```bash
/plugin marketplace add brennacodes/brenna-plugs
```

### Install what you need
```
/plugin install heres-the-thing@brenna-plugs
```
```
/plugin install i-did-a-thing@brenna-plugs
```
```
/plugin install what-did-you-do@brenna-plugs
```
```
/plugin install what-do-you-know@brenna-plugs
```
```
/plugin install mark-my-words@brenna-plugs
```
```
/plugin install think-like@brenna-plugs
```
```
/plugin install screenshotr@brenna-plugs
```

---

### heres-the-thing

The shared data layer that powers the career plugin ecosystem. Creates and manages `~/.things/` — config, registry, professional profile, and cross-machine sync. Run this setup first; every other career plugin depends on it.

| Skill | Description |
|-------|-------------|
| `/setup-htt` | Initialize `~/.things/` with config.json, registry.json, and professional profile |
| `/status` | Show current config state, registered plugins, and sync status |
| `/search-things` | Search across all plugin data in `~/.things/` |
| `/validate` | Validate config integrity and plugin registrations |
| `/sync` | Git sync `~/.things/` across machines |
| `/register` | Register a plugin with the Things registry |
| `/migrate` | Migrate shared resources and clean up old layout artifacts |

[View the README](plugins/heres-the-thing/README.md)

---

### i-did-a-thing

Log professionally-relevant experiences — accomplishments, lessons, expertise, decisions, influence, and insights — through guided deep-dives. Every entry auto-generates resume bullets, interview talking points, and a blog seed. A PostToolUse hook rebuilds the JSON index and skill arsenal after every log.

| Skill | Description |
|-------|-------------|
| `/setup-idat` | Configure plugin-specific preferences for experience logging |
| `/thing-i-did` | Log an experience (context-aware — extracts from conversation or runs full interview) |
| `/construct-resume` | Match your evidence against a job listing and build a tailored resume |
| `/migrate-idat` | Migrate data files from old flat layout to per-plugin directories |

Six evidence types: accomplishment, lesson, expertise, decision, influence, insight. Each gets tailored interview questions, resume bullet formats, and body section structures.

[View the README](plugins/i-did-a-thing/README.md)

---

### what-did-you-do

Interview prep that knows what you've actually done. Cross-references your arsenal when coaching answers — matching question themes to evidence types (lessons for failure questions, decisions for tradeoff questions, expertise for depth questions). Spaced repetition targets weak areas over time.

| Skill | Description |
|-------|-------------|
| `/setup-wdyd` | Set follow-up depth, default stage, trusted question sources |
| `/practice` | Drill a single question with persona-driven feedback |
| `/mock` | Full interview round simulation (Amazon, Google, Meta, custom) |
| `/review` | Readiness assessment with trends, gaps, and anti-pattern tracking |
| `/prep-for` | Company-specific prep plan with value mapping and timeline |
| `/update-questions` | Add questions from trusted sources or manual entry |
| `/migrate-wdyd` | Migrate data files from old flat layout to per-plugin directories |

7 interviewer personas. 45 built-in questions. 5 scoring dimensions. Company profiles for Amazon (14 LPs), Google, and Meta.

[View the README](plugins/what-did-you-do/README.md)

---

### mark-my-words

Write, edit, and publish blog posts across 7 static-site platforms: Quartz, Hugo, Jekyll, Astro, Eleventy, Docusaurus, and Zola. Supports voice profiles (teach it how you write), Mermaid diagrams, images, and video embeds. The `from-things` skill finds high-potential evidence logs via the JSON index and transforms them into first-person stories.

| Skill | Description |
|-------|-------------|
| `/setup-mmw` | Configure blog source, content directory, media, git workflow |
| `/new-post` | Write a new post via guided interview |
| `/update-post` | Edit sections, append, rewrite, or update metadata |
| `/manage-post` | List posts, manage drafts, organize tags |
| `/from-things` | Turn evidence logs into blog posts |
| `/create-voice` | Build a voice profile from writing samples |
| `/update-voice` | Refine a voice profile |
| `/add-media` | Add images, diagrams, video embeds to a post |
| `/migrate-mmw` | Migrate data files from old flat layout to per-plugin directories |

[View the README](plugins/mark-my-words/README.md)

---

### what-do-you-know

Knowledge reinforcement that draws from your actual experience. Explore topics with probing dialogue grounded in your arsenal, quiz yourself with dynamically generated questions referencing your real projects, identify knowledge gaps by cross-referencing skills against evidence, and build personalized learning plans that bridge from what you know to what you need.

| Skill | Description |
|-------|-------------|
| `/setup-wdyk` | Set learning depth, session length, default persona, focus areas |
| `/explore` | Topic-driven deep dive with persona-driven probing and concept mapping |
| `/quiz` | Dynamic concept questions from your index.json with spaced repetition |
| `/gaps` | Knowledge gap analysis across building and aspirational skills |
| `/bridge` | Personalized learning plan from existing knowledge to gap topics |
| `/migrate-wdyk` | Migrate data files from old flat layout to per-plugin directories |

5 learning dimensions: Depth, Accuracy, Connections, Application, Articulation. Same 7 personas shared with what-did-you-do. Questions generated dynamically — no static question bank.

[View the README](plugins/what-do-you-know/README.md)

---

### think-like

Expert thinking profiles for code review, architecture, security, and debugging. Builder agents research a person's philosophy and produce self-contained action files that Claude follows directly. Ships with starter profiles for DHH, Sandi Metz, and a Strict Security Lead — or create your own from any public figure or archetype.

| Skill | Description |
|-------|-------------|
| `/setup-tl` | Configure think-like preferences and install shared context templates |
| `/profile` | Apply an expert profile to the current task |
| `/create-profile` | Build a new expert profile with builder agents |
| `/browse-profiles` | Browse and preview available profiles |
| `/manage-profiles` | Edit, delete, or reorganize existing profiles |

Built-in builder agents: code-review, security-analysis, architecture-plan, debug, agent-builder (meta). Profiles are stored as action files at `~/.things/think-like/profiles/`.

[View the README](plugins/think-like/README.md)

---

### screenshotr

Precise screenshot capabilities for macOS — capture screens, windows, regions, or URLs with resize, crop, delay, and format control. Built on macOS-native `screencapture` and `sips`. Independent of the `.things/` ecosystem.

| Skill | Description |
|-------|-------------|
| `/setup-ss` | Configure output directory, format, naming preferences |
| `/capture` | Full-control screenshot (fullscreen, window, region, URL, display) |
| `/list-windows` | List open windows with app names and IDs |

[View the README](plugins/screenshotr/README.md)

---

### session-scout

Search, browse, and resume Claude Code sessions across all projects. Grep session data by keyword, list active sessions, or pick up where you left off. Independent of the `.things/` ecosystem.

| Skill | Description |
|-------|-------------|
| `/active` | Show currently active Claude Code sessions |
| `/projects` | List projects with session history |
| `/resume` | Resume a previous session by search or selection |
| `/search` | Grep session data for keywords across all projects |

---

## Migrating from v3

### What changed and why - From Trio, to Quartet, to Quintet

I've expanded the ecosystem fairly rapidly over the last month, and I've found that the flat layout of v3 was a bit limiting and becoming increasingly complex.

Version 3 stored everything in a flat layout — a single `config.yml` at the root of `~/.things/`, with plugin data scattered across top-level directories. This worked fine with two or three plugins, but as the ecosystem grew it created problems:

- **Config collisions**: Every plugin wrote preferences into the same `config.yml`, making it fragile and hard to validate.
- **No registry**: There was no way to discover which plugins were installed, what data they owned, or how to rebuild indexes. Plugins couldn't coordinate.
- **Flat data directories**: Plugin data lived in top-level dirs like `~/.things/logs/` and `~/.things/sessions/` with no namespacing, making it unclear which plugin owned what.
- **No shared resources**: As an ecosystem, it made sense to have a shared place to store data like people, roles, companies, and contexts to avoid data duplication and to make it easier to coordinate between plugins.
- **Too many git repos**: This could be a good thing or a bad thing, depending on your perspective, but creating a single tracked repo for the entire ecosystem where possible was a goal.

Version 4 fixes this with a structured layout in `~/.things/`:

- **`config.json`** replaces `config.yml` — JSON for programmatic access, with a clear schema.
- **Per-plugin directories** — each plugin owns `~/.things/<plugin-name>/` (e.g., `~/.things/i-did-a-thing/logs/`).
- **Registry** — `~/.things/registry.json` tracks installed plugins, their data schemas, and rebuild commands.
- **Shared resources** — `~/.things/shared/` holds cross-plugin data (people, roles, companies, contexts).
- **Professional profile** — moved from a config.yml field to `~/.things/shared/professional-profile.json`.

### Is my data safe?

Yes. Migration reads from old locations and writes to new ones — nothing is deleted until you confirm. If anything goes wrong, your original files are still in place.

Every migration command supports `--dry-run`. Run it first to see exactly what data was found, what will move, and what will be created — without touching any files:

```
/setup-htt --dry-run
/migrate-htt --dry-run
/migrate-idat --dry-run
```

### Migration steps

Run these in order. Each command is idempotent — safe to re-run if interrupted.

**1. Migrate the foundation**

```
/setup-htt
```

This detects your existing `config.yml`, migrates settings to the new `config.json`, creates the registry, and sets up the directory structure. It will walk you through any decisions (like git workflow preferences that didn't exist in v3).

**2. Migrate shared resources**

```
/migrate-htt
```

Moves shared data (people, roles, companies) from old locations into `~/.things/shared/`. Registers collections in the registry.

**3. Migrate each plugin's data**

Run the migrate command for each plugin you have installed:

```
/migrate-idat
```
```
/migrate-wdyd
```
```
/migrate-wdyk
```
```
/migrate-mmw
```

Each moves that plugin's data files from the old flat layout into per-plugin directories under `~/.things/` and rebuilds indexes.

**4. Verify**

```
/validate
```

Checks config integrity, registry entries, and data consistency across all migrated plugins. Fix anything it flags before cleaning up old files.
