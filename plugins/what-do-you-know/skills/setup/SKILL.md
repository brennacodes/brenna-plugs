---
name: setup
description: "Configure what-do-you-know plugin: link to shared config, set learning preferences, seed personas, and initialize learning session tracking"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

# Set Up what-do-you-know

Configure the plugin to use your i-did-a-thing arsenal for knowledge reinforcement, concept quizzing, gap analysis, and personalized learning plans.

This setup uses the shared config used by all career plugins. See `references/things-setup.md` for the full config architecture.

## Steps

### 1. Check for Existing Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Follow the **Bootstrap Detection Flow** from `references/things-setup.md`:

1. Check if `<home>/.claude/things.local.md` exists
2. If yes, read `things_path` from it (if `things_path` starts with `~`, replace with `<home>`)
3. Check if `<things_path>/config.yml` exists

**If both exist**: Read `config.yml` and check the `learning:` section. If it has non-default values, tell the user:

> Found existing configuration. I'll walk you through updating it — your current settings will be shown as defaults.

**If bootstrap exists but no config.yml**: Tell the user:

> Found your bootstrap config but no full config. Please run `/i-did-a-thing:setup` first to create the shared config.

Then stop.

**If neither exists**: Tell the user:

> No configuration found. Please run `/i-did-a-thing:setup` first to set up your shared config and accomplishment tracking.
>
> You can still use what-do-you-know without it, but you won't get arsenal-powered feedback.

Then stop.

### 2. Verify Arsenal

Read `<things_path>/config.yml` to confirm the shared profile:

> Found your shared config. Your arsenal at `<things_path>` will power your learning sessions.
>
> - Current role: `<current_role>`
> - Target roles: `<target_roles>`
> - Building skills: `<building_skills>`
> - Aspirational skills: `<aspirational_skills>`

Check that `<things_path>/arsenal/` exists and has files. If not:

> No arsenal files found. Run `/i-did-a-thing:thing-i-did` to log some experiences first — your learning sessions will be much richer with evidence to draw from.

### 3. Gather Learning Preferences

Use AskUserQuestion to ask:

**What depth level for learning sessions by default?**
- `exploratory` — broad topic overview, identify what you know and don't (Recommended)
- `focused` — targeted deep-dive into specific concepts
- `deep` — intensive probing with detailed technical questions

Then ask:

**Default session length?**
- `short` — ~15 minutes, quick knowledge check
- `medium` — ~30 minutes, balanced exploration (Recommended)
- `deep` — ~60 minutes, comprehensive deep-dive

Then ask:

**Default persona for learning sessions?**
- Staff Engineer — technical depth, architecture, tradeoffs (Recommended)
- Engineering Manager — collaboration, communication, growth
- Principal Engineer — system thinking, organizational impact
- Bar Raiser — cross-functional depth, judgment

Then ask:

**Any specific focus areas?** (comma-separated topics, or leave empty to follow your building_skills + aspirational_skills from config)

### 4. Seed Shared Personas and Companies

Seed persona and company files to the things repo. For each file in `<plugin_root>/personas/`, copy to `<things_path>/personas/` if not already present. For each file in `<plugin_root>/companies/`, copy to `<things_path>/companies/` if not already present. Never overwrite existing files.

```bash
mkdir -p <things_path>/personas
mkdir -p <things_path>/companies
for f in <plugin_root>/personas/*.md; do
  dest="<things_path>/personas/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
for f in <plugin_root>/companies/*.yaml; do
  dest="<things_path>/companies/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
```

Tell the user how many personas and companies were seeded (or "all already present").

### 5. Initialize Learning Directory

Create the directory structure at `<things_path>/learning/`:

```
<things_path>/learning/
├── sessions/
├── progress.md
├── knowledge-map.md
└── study-plans/
```

Run via Bash:
```bash
mkdir -p <things_path>/learning/sessions
mkdir -p <things_path>/learning/study-plans
```

### 6. Create Progress Dashboard

Write `<things_path>/learning/progress.md`:

```markdown
---
title: "Learning Progress Dashboard"
total_sessions: 0
last_session: null
dimensions:
  depth: null
  accuracy: null
  connections: null
  application: null
  articulation: null
strongest_topics: []
weakest_topics: []
last_updated: <current_date>
---

# Learning Progress

This dashboard is automatically maintained by what-do-you-know.

## Overall Progress

_No sessions yet. Run `/what-do-you-know:explore` to start._

## Dimension Scores

| Dimension | Average | Trend | Last Session |
|-----------|---------|-------|-------------|
| Depth | — | — | — |
| Accuracy | — | — | — |
| Connections | — | — | — |
| Application | — | — | — |
| Articulation | — | — | — |

## Topic Breakdown

_Topics will appear as you explore and quiz._

## Recent Sessions

_Sessions will be listed here._
```

### 7. Create Knowledge Map

Write `<things_path>/learning/knowledge-map.md`:

```markdown
---
title: "Knowledge Map"
last_updated: <current_date>
---

# Knowledge Map

A living map of your knowledge areas, updated after each learning session.

## Strong

_Topics where you demonstrate consistent depth and accuracy._

## Building

_Topics where you show partial understanding — some depth but gaps remain._

## Gap

_Topics where you have limited knowledge despite relevance to your goals._

## Blind Spot

_Topics relevant to your target roles that haven't been explored yet._
```

### 8. Update Config

Read `<things_path>/config.yml` and update the `learning:` section with the user's preferences:

```yaml
learning:
  default_depth: <exploratory|focused|deep>
  default_persona: <persona>
  session_length: <short|medium|deep>
  focus_areas:
    - <area>
```

Use Edit to update only the `learning:` section, preserving all other config.

### 9. Confirm Setup

Tell the user:

> Your what-do-you-know setup is complete!
>
> - Arsenal: `<things_path>`
> - Default depth: `<depth>`
> - Session length: `<length>`
> - Default persona: `<persona>`
> - Focus areas: `<areas or "following building_skills + aspirational_skills">`
>
> **Quick start:**
> - `/what-do-you-know:explore` — Deep-dive into a topic from your experience
> - `/what-do-you-know:quiz` — Test your knowledge with concept questions
> - `/what-do-you-know:gaps` — Analyze knowledge gaps across your skill areas
> - `/what-do-you-know:bridge` — Build a learning plan for a specific gap
