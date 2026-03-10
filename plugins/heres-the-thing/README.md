# heres-the-thing

Persuasion and positioning engine -- take any subject, tailor it for any audience, in any medium, and track what works.

**Core question**: "Can I make them care?"

## What it does

heres-the-thing takes any subject matter and tailors communication for a specific audience, context, and medium. It tracks outcomes and learns what works through a feedback loop that updates audience profiles and your professional profile.

## Skills

| Skill | Description |
|-------|-------------|
| `/heres-the-thing:setup-htt` | Initialize directories, preferences, launchd agent, register collections with things |
| `/heres-the-thing:pitch-htt` | Guided interview to create a campaign with strategy brief and deliverables |
| `/heres-the-thing:prep-htt` | Generate or refine deliverables for a specific goal, includes Q&A prep sessions |
| `/heres-the-thing:outcome-htt` | Log what happened, capture reflections, push feedback to profiles |
| `/heres-the-thing:review-htt` | Cross-campaign analysis -- patterns, medium effectiveness, audience insights |
| `/heres-the-thing:audience-htt` | Create and manage reusable audience segment profiles |
| `/heres-the-thing:create-type-htt` | Create custom deliverable types with templates and tool requirements |
| `/heres-the-thing:migrate-htt` | Future migration support |

## Data Structure

```
~/.things/heres-the-thing/
  preferences.json
  campaigns/
    <campaign-id>/
      campaign.json
      strategy/
        <goal-id>-<timestamp>.md       # versioned strategy briefs
      artifacts/
        <goal-id>-<type>-<timestamp>.md # generated deliverables
      outcomes/
        <goal-id>-<timestamp>.json      # per-goal outcome logs
  audiences/
    <slug>.json                         # reusable audience segments
  deliverable-types/
    index.json                          # custom type registry
    <type-id>.md                        # type templates
  scripts/
    notify.sh                           # scheduled check-in runner
```

## Where it fits

| Plugin | Core question |
|--------|---------------|
| i-did-a-thing | What did I accomplish? |
| what-did-you-do | Can I tell the story under pressure? |
| what-do-you-know | Do I actually understand this? |
| mark-my-words | Can I publish this clearly? |
| think-like | How would an expert see this? |
| **heres-the-thing** | **Can I make them care?** |

## Cross-Plugin Integration

- **things** (data layer): Registry, shared resources, tag index
- **i-did-a-thing**: Source material for campaigns (logs, arsenal)
- **mark-my-words**: Voice profiles for artifact generation
- **think-like**: Audience perspective modeling for Q&A prep sessions
- **what-did-you-do**: Strengths/weaknesses from practice sessions
- **what-do-you-know**: Subject knowledge gaps

## Requirements

- things plugin (`/things:setup-things`) must be set up first
- Python 3 (for notification scripts)
- macOS (for launchd-based notifications, optional)
