---
name: setup
description: "Configure what-did-you-do plugin: link to i-did-a-thing data, set interview preferences, and initialize session tracking"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[reconfigure]"
---

# Set Up what-did-you-do

Configure the plugin to use your i-did-a-thing arsenal for interview preparation, practice sessions, and company-specific mock interviews.

## Steps

### 1. Check for Existing Configuration

Read `.claude/what-did-you-do.local.md`. If it exists, tell the user:

> Found existing configuration. I'll walk you through updating it — your current settings will be shown as defaults.

### 2. Verify i-did-a-thing Integration

Read `.claude/i-did-a-thing.local.md` to get the user's `things_path`. If missing:

> This plugin works best with i-did-a-thing. Please run `/i-did-a-thing:setup` first to set up your accomplishment tracking.
>
> You can still use what-did-you-do without it, but you won't get arsenal-powered feedback.

If found, confirm:

> Found your i-did-a-thing config. Your arsenal at `<things_path>` will power your interview feedback.

Extract from the i-did-a-thing config:
- `things_path` — where accomplishments live
- `current_role` — for level-appropriate questions
- `target_roles` — for gap-targeted practice
- `building_skills` — for question weighting
- `aspirational_skills` — for bonus weighting in question selection

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

Create the directory structure at `<things_path>/interview-prep/`:

```
<things_path>/interview-prep/
├── sessions/
├── progress.md
├── companies/
└── question-overrides/
    └── custom.yaml
```

Run via Bash:
```bash
mkdir -p <things_path>/interview-prep/sessions
mkdir -p <things_path>/interview-prep/companies
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

### 8. Write Configuration

Write `.claude/what-did-you-do.local.md`:

```yaml
---
things_path: "<from i-did-a-thing config>"
follow_up_depth: "<concise|detailed|coaching>"
default_stage: "<stage or no-default>"
trusted_sources:
  domains:
    - "<domain>"
  urls:
    - "<url>"
current_role: "<from i-did-a-thing config>"
target_roles:
  - "<from i-did-a-thing config>"
building_skills:
  - "<from i-did-a-thing config>"
aspirational_skills:
  - "<from i-did-a-thing config>"
last_updated: <current_date>
---

# what-did-you-do Configuration

Generated by `/what-did-you-do:setup`. Run it again to reconfigure.

These settings are used by all what-did-you-do skills:
- `practice` — single-question drill with persona-driven feedback
- `mock` — full interview round simulation
- `review` — readiness assessment across dimensions
- `prep-for` — company-specific preparation plan
- `update-questions` — add questions from trusted sources
```

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
