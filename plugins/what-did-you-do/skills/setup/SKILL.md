---
name: setup
description: "Configure what-did-you-do plugin: link to shared config, set interview preferences, and initialize session tracking"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

# Set Up what-did-you-do

Configure the plugin to use your i-did-a-thing arsenal for interview preparation, practice sessions, and company-specific mock interviews. Seeds shared personas and company profiles to the things repo.

This setup uses the shared config used by all career plugins. See `references/things-setup.md` for the full config architecture.

## Steps

### 1. Check for Existing Configuration

Follow the **Bootstrap Detection Flow** from `references/things-setup.md`:

1. Check if `~/.claude/things.local.md` exists
2. If yes, read `things_path` from it
3. Check if `<things_path>/config.yml` exists

**If both exist**: Read `config.yml` and check the `interview_prep:` section. If it has non-default values, tell the user:

> Found existing configuration. I'll walk you through updating it — your current settings will be shown as defaults.

**If bootstrap exists but no config.yml**: Tell the user:

> Found your bootstrap config but no full config. Please run `/i-did-a-thing:setup` first to create the shared config.

Then stop.

**If neither exists**: Tell the user:

> No configuration found. Please run `/i-did-a-thing:setup` first to set up your shared config and accomplishment tracking.
>
> You can still use what-did-you-do without it, but you won't get arsenal-powered feedback.

Then stop.

### 2. Verify Arsenal

Read `<things_path>/config.yml` to confirm the shared profile:

> Found your shared config. Your arsenal at `<things_path>` will power your interview feedback.
>
> - Current role: `<current_role>`
> - Target roles: `<target_roles>`
> - Building skills: `<building_skills>`

### 3. Gather Interview Preferences

Use AskUserQuestion to ask:

**How detailed should follow-up questions be during practice?**
- `concise` — no follow-ups, keep it moving
- `detailed` — first-level follow-ups to test depth
- `coaching` — deep follow-ups with probing questions and action items

Then ask:

**Default interview stage to practice?**
- `phone-screen` — 30-min behavioral/culture fit
- `technical` — coding and system design
- `onsite` — full-day multi-round simulation
- `bar-raiser` — cross-functional deep dive
- `no-default` — ask me each time

### 4. Gather Trusted Sources for Question Updates

Use AskUserQuestion to ask:

**Do you want to enable question bank updates from external sources?**
- Yes — I'll provide trusted domains
- No — only use the built-in question bank

If yes, ask:

**Trusted domains for question sources** (comma-separated, e.g., `leetcode.com, teamblind.com, levels.fyi`)

And:

**Trusted URLs** (specific pages, comma-separated — optional)

### 5. Initialize Interview Prep Directory

Seed shared personas and company profiles to the things repo. For each file in `<plugin_root>/personas/`, copy to `<things_path>/personas/` if not already present. For each file in `<plugin_root>/companies/`, copy to `<things_path>/companies/` if not already present. Never overwrite existing files (user customizations are sacred).

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

Tell the user how many personas and companies were seeded.

Create the directory structure at `<things_path>/interview-prep/`:

```
<things_path>/interview-prep/
├── sessions/
├── progress.md
└── question-overrides/
    └── custom.yaml
```

Run via Bash:
```bash
mkdir -p <things_path>/interview-prep/sessions
mkdir -p <things_path>/interview-prep/question-overrides
```

### 6. Create Progress Dashboard

Write `<things_path>/interview-prep/progress.md`:

```markdown
---
title: "Interview Readiness Dashboard"
total_sessions: 0
last_session: null
dimensions:
  specificity: null
  structure: null
  impact: null
  relevance: null
  self_advocacy: null
strongest_categories: []
weakest_categories: []
last_updated: <current_date>
---

# Interview Readiness

This dashboard is automatically maintained by what-did-you-do.

## Overall Readiness

_No sessions yet. Run `/what-did-you-do:practice` to start._

## Dimension Scores

| Dimension | Average | Trend | Last Session |
|-----------|---------|-------|-------------|
| Specificity | — | — | — |
| Structure | — | — | — |
| Impact | — | — | — |
| Relevance | — | — | — |
| Self-Advocacy | — | — | — |

## Category Breakdown

_Categories will appear as you practice different question types._

## Recent Sessions

_Sessions will be listed here._
```

### 7. Create Custom Questions Starter

Write `<things_path>/interview-prep/question-overrides/custom.yaml`:

```yaml
# Custom interview questions
# Add your own questions here following the schema:
#
# - id: custom-001
#   text: "Your question here"
#   category: behavioral
#   subcategory: custom
#   skills_tested: [skill-1, skill-2]
#   level: [mid, senior]
#   stages: [phone-screen, onsite]
#   interviewer_types: [engineering-manager]
#   follow_ups:
#     - text: "Follow-up question"
#       depth: 2
#   difficulty: 3
#   expected_format: narrative
#   time_budget_minutes: 5
#   red_flags: ["vague answer"]
#   green_flags: ["specific metrics"]

questions: []
```

### 8. Update Config

Read `<things_path>/config.yml` and update the `interview_prep:` section with the user's preferences:

```yaml
interview_prep:
  follow_up_depth: <concise|detailed|coaching>
  default_stage: <stage or no-default>
  trusted_sources:
    domains:
      - <domain>
    urls:
      - <url>
```

Use Edit to update only the `interview_prep:` section, preserving all other config.

### 9. Confirm Setup

Tell the user:

> Your what-did-you-do setup is complete!
>
> - Arsenal: `<things_path>`
> - Follow-up depth: `<depth>`
> - Default stage: `<stage>`
> - Trusted sources: `<count or "built-in only">`
>
> **Quick start:**
> - `/what-did-you-do:practice` — Drill a single question with coached feedback
> - `/what-did-you-do:mock` — Simulate a full interview round
> - `/what-did-you-do:prep-for` — Prepare for a specific company
> - `/what-did-you-do:review` — Check your readiness across dimensions
