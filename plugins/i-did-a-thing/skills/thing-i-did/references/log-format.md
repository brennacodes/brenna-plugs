# Log Entry Format Reference

Every log entry follows this structure. The format is designed to be:
- **Searchable**: Rich frontmatter metadata for filtering and querying
- **Resume-ready**: Pre-written bullets in type-appropriate format
- **Interview-ready**: Talking points extracted from the narrative
- **Blog-ready**: Compatible with mark-my-words post format (Quartz frontmatter)
- **Arsenal-building**: Skills and evidence linked to skill summary files

## File Naming Convention

```
<YYYY-MM-DD>-<slugified-title>.md
```

Example: `2025-02-09-migrated-auth-service-to-oauth2.md`

## Evidence Types

Every entry has an `evidence_type` that determines how the body sections, resume bullets, interview talking points, and blog seed are structured.

| Type | What it captures |
|------|-----------------|
| `accomplishment` | You did something with a measurable outcome |
| `lesson` | Something didn't go as planned, but you extracted value |
| `expertise` | You went deep on a topic and became a resource |
| `decision` | You evaluated options, made a judgment call, and can articulate why |
| `influence` | You shaped someone else's decision, advocated for a change, or mentored someone |
| `insight` | You noticed a pattern, formed a thesis, developed a perspective |

Existing logs without `evidence_type` default to `accomplishment` — no migration needed.

## Full Template

The body sections adapt based on `evidence_type`. The frontmatter is the same across all types.

```markdown
---
# Core metadata
title: "<Descriptive title>"
date: <YYYY-MM-DD>
description: "<1-2 sentence summary suitable for a blog post subtitle>"

# Classification
evidence_type: "<accomplishment|lesson|expertise|decision|influence|insight>"
impact: "<major|notable|solid|learning>"
category: "<technical|leadership|communication|problem-solving|process|growth|expertise|decision-making|influence>"
tags:
  - <tag1>
  - <tag2>

# Skills & evidence
skills_used:
  - <skill1>
  - <skill2>
skills_developed:
  - <skill1>

# Professional alignment
target_alignment:
  - "<which professional target this supports>"

# Context
role_at_time: "<Your role when this happened>"
team_or_org: "<Team or organization context>"
duration: "<How long this took — hours, days, weeks>"

# Metrics (if applicable)
metrics:
  type: "<quantitative|qualitative>"
  values:
    - label: "<what was measured>"
      value: "<the number or outcome>"
      context: "<why this matters>"

# Blog integration (mark-my-words compatibility)
draft: true
author: "<from config>"
blog_potential: "<high|medium|low>"
---
```

### Body Sections by Evidence Type

#### Accomplishment

```markdown
# <Title>

## Context

<What was the situation? What problem existed? Why did it matter?>

## Action

<What specifically did you do? What was your approach? What decisions did you make?>

## Result

<What happened? What was the outcome? Include specifics — numbers, feedback, changes.>

## Reflection

<What did you learn? What would you do differently? How does this connect to your goals?>
```

#### Lesson

```markdown
# <Title>

## Situation

<What was the context? What were you trying to accomplish?>

## What I Tried

<What was the plan or approach? What did you expect to happen?>

## What Went Wrong

<What actually happened? What surprised you?>

## What I'd Do Differently

<Knowing what you know now, how would you approach this?>

## What I Took From It

<The lasting takeaway. How has this changed how you work?>
```

#### Expertise

```markdown
# <Title>

## The Domain

<What's the topic or area of expertise?>

## How I Developed It

<The journey — how you went from beginner to go-to person.>

## How I Apply It

<Day-to-day application. How this expertise shows up in your work.>

## How I've Shared It

<Teaching, mentoring, documentation, talks, code reviews, etc.>

## What's Non-Obvious

<The thing most people get wrong. Your earned insight.>
```

#### Decision

```markdown
# <Title>

## The Problem

<What needed to be resolved? What was the context and pressure?>

## Options Considered

<What were the choices? Give each option a fair description.>

## How I Evaluated Them

<Tradeoffs, constraints, priorities. What mattered most and why?>

## What I Chose and Why

<The decision and the reasoning. What tipped the balance?>

## How It Played Out

<The outcome. Would you make the same call again?>
```

#### Influence

```markdown
# <Title>

## The Status Quo

<What was the existing state or direction before you got involved?>

## My Position

<What change were you advocating for? Why did it matter?>

## How I Advocated

<Tactics, approach, evidence you marshaled. How you made the case.>

## What Happened

<The outcome. Did the change stick? What was the impact?>

## What I'd Do Differently

<Reflection on the advocacy process itself.>
```

#### Insight

```markdown
# <Title>

## What I Observed

<The raw observation. What caught your attention?>

## Where and How Often

<Scope and frequency. One-off or recurring pattern?>

## My Thesis

<Your interpretation. What do you think is going on?>

## The Evidence

<What supports your thinking? Data, examples, analogies.>

## My Recommendation

<What should be done about it? Have you acted on this?>
```

### Output Sections (all types)

After the body sections, every log includes:

```markdown
---

## Resume Bullets

<2-3 pre-written bullets in the type-appropriate format>

## Interview Talking Points

<Key points structured for the evidence type>

## Blog Seed

> <A 1-2 sentence hook tailored to the evidence type>

**Potential angles:**
- <angle 1>
- <angle 2>
```

**Resume bullet format by type:**

| Type | Format |
|------|--------|
| Accomplishment | `ACTION VERB <what you did> by <how>, resulting in <measurable outcome>` |
| Lesson | `Learned <X> from <Y>, now apply <Z> to <outcome>` |
| Expertise | `Deep expertise in <X>, demonstrated through <Y>, enabling <Z>` |
| Decision | `Evaluated <X, Y, Z>; chose <Z> based on <A, B, C>, resulting in <outcome>` |
| Influence | `Drove adoption of <X> by <method>, resulting in <Y>` |
| Insight | `Identified <pattern X>, proposed <Y>, leading to <Z>` |

**Interview talking points by type:**

| Type | Structure |
|------|-----------|
| Accomplishment | Situation - Task - Action - Result - Lessons |
| Lesson | Situation - Mistake/Surprise - Learning - Application |
| Expertise | Domain - Depth - Application - Teaching |
| Decision | Problem - Options - Tradeoffs - Choice - Outcome |
| Influence | Status Quo - Position - Advocacy - Outcome |
| Insight | Observation - Evidence - Thesis - Recommendation |

**Blog seed hook by type:**

| Type | Hook style |
|------|-----------|
| Accomplishment | Engaging first-person hook about the experience |
| Lesson | "The time I learned..." |
| Expertise | "Everything I know about..." |
| Decision | "Why I chose X over Y..." |
| Influence | "How I convinced my team to..." |
| Insight | "A pattern I keep seeing..." |

## Frontmatter Field Reference

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `title` | Yes | string | Descriptive title of the entry |
| `date` | Yes | date | When this happened (YYYY-MM-DD) |
| `description` | Yes | string | 1-2 sentence summary |
| `evidence_type` | Yes | enum | `accomplishment`, `lesson`, `expertise`, `decision`, `influence`, `insight` |
| `impact` | Yes | enum | `major`, `notable`, `solid`, `learning` |
| `category` | Yes | enum | `technical`, `leadership`, `communication`, `problem-solving`, `process`, `growth`, `expertise`, `decision-making`, `influence` |
| `tags` | Yes | list | Searchable tags |
| `skills_used` | Yes | list | Skills demonstrated |
| `skills_developed` | No | list | New skills learned/grown |
| `target_alignment` | No | list | Professional targets this supports |
| `role_at_time` | No | string | Your role when this happened |
| `team_or_org` | No | string | Team/org context |
| `duration` | No | string | How long it took |
| `metrics` | No | object | Quantifiable outcomes |
| `draft` | Yes | boolean | Always `true` (for mark-my-words) |
| `author` | Yes | string | From config |
| `blog_potential` | No | enum | `high`, `medium`, `low` |

## Mark-My-Words Compatibility

The log format is intentionally compatible with Quartz markdown frontmatter. When mark-my-words' `from-things` skill converts a log to a blog post, it:

1. Uses `title`, `date`, `description`, `tags`, `draft`, and `author` directly
2. Transforms the body narrative into engaging prose (adapting to the evidence type's section structure)
3. Uses the **Blog Seed** section as the opening hook
4. Pulls from **Potential angles** to choose a narrative frame
5. References **Metrics** for concrete details

## Impact Level Guidelines

| Level | Description | Examples |
|-------|-------------|---------|
| `major` | Career-defining, org-wide impact | Led a critical migration, saved $X, promoted based on this |
| `notable` | Team-level impact, skill breakthrough | Shipped a key feature, mentored someone, resolved a major incident |
| `solid` | Good work, pattern-building | Consistent delivery, process improvement, code review impact |
| `learning` | Valuable lesson from challenge | Failed experiment with insights, stretch assignment, course completion |
