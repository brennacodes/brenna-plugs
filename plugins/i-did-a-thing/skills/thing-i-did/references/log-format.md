# Log Entry Format Reference

Every accomplishment log follows this structure. The format is designed to be:
- **Searchable**: Rich frontmatter metadata for filtering and querying
- **Resume-ready**: Pre-written STAR-format bullets
- **Interview-ready**: Talking points extracted from the narrative
- **Blog-ready**: Compatible with mark-my-words post format (Quartz frontmatter)
- **Arsenal-building**: Skills and evidence linked to skill summary files

## File Naming Convention

```
<YYYY-MM-DD>-<slugified-title>.md
```

Example: `2025-02-09-migrated-auth-service-to-oauth2.md`

## Full Template

```markdown
---
# Core metadata
title: "<Descriptive title of what you did>"
date: <YYYY-MM-DD>
description: "<1-2 sentence summary suitable for a blog post subtitle>"

# Classification
impact: "<major|notable|solid|learning>"
category: "<technical|leadership|communication|problem-solving|process|growth>"
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

# <Title>

## Context

<What was the situation? What problem existed? Why did it matter?>

## Action

<What specifically did you do? What was your approach? What decisions did you make?>

## Result

<What happened? What was the outcome? Include specifics — numbers, feedback, changes.>

## Reflection

<What did you learn? What would you do differently? How does this connect to your goals?>

---

## Resume Bullets

- <ACTION VERB> <what you did> by <how you did it>, resulting in <measurable outcome>
- <ACTION VERB> <scope of work>, <leveraging|using|applying> <skills/tools>, <achieving|delivering> <result>

## Interview Talking Points

- **Situation**: <1-line setup>
- **Task**: <what needed to happen>
- **Action**: <what you specifically did>
- **Result**: <the outcome, with specifics>
- **Lessons**: <what you'd say you learned>

## Blog Seed

> <A 1-2 sentence hook that could open a blog post about this experience. Written in an engaging, first-person voice.>

**Potential angles:**
- <angle 1>
- <angle 2>
```

## Frontmatter Field Reference

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `title` | Yes | string | Descriptive title of the accomplishment |
| `date` | Yes | date | When this happened (YYYY-MM-DD) |
| `description` | Yes | string | 1-2 sentence summary |
| `impact` | Yes | enum | `major`, `notable`, `solid`, `learning` |
| `category` | Yes | enum | `technical`, `leadership`, `communication`, `problem-solving`, `process`, `growth` |
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
2. Transforms the **Context → Action → Result** narrative into engaging prose
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
