# Things-to-Post Bridge Reference

How to transform an i-did-a-thing accomplishment log into a mark-my-words blog post.

## Log Format Overview

Each i-did-a-thing log has this structure (see the i-did-a-thing plugin's `log-format.md` for full details):

```yaml
---
title: "Descriptive accomplishment title"
date: YYYY-MM-DD
description: "1-2 sentence summary"
impact: "major|notable|solid|learning"
category: "technical|leadership|communication|problem-solving|process|growth"
tags: [...]
skills_used: [...]
metrics:
  type: "quantitative|qualitative"
  values:
    - label: "what was measured"
      value: "the number"
      context: "why it matters"
draft: true
author: "Author Name"
blog_potential: "high|medium|low"
---

# Title

## Context
<situation/problem>

## Action
<what they did>

## Result
<outcome with specifics>

## Reflection
<lessons learned>

---

## Resume Bullets
<pre-written STAR-format bullets — not used in blog>

## Interview Talking Points
<structured talking points — not used in blog>

## Blog Seed
> <1-2 sentence opening hook>

**Potential angles:**
- <angle 1>
- <angle 2>
```

## Frontmatter Mapping

| Log Field | Blog Field | Transformation |
|-----------|------------|---------------|
| `title` | `title` | Rewrite for blog audience (engaging, not resume-like) |
| `date` | `date` | Use today's date (when the post is written), not the log date |
| `description` | `description` | Rewrite as 1-2 sentence preview/hook |
| `tags` | `tags` | Broaden for blog audience, blend with existing blog tags |
| `author` | `author` | Use mark-my-words `default_author` config |
| `draft` | `draft` | Always `true` initially |
| `category` | — | Informs tone, not directly mapped |
| `impact` | — | Calibrates ambition of post |
| `skills_used` | — | Woven into narrative naturally |
| `metrics` | — | Contextualized as concrete evidence in the story |

## Content Transformation

### Log Structure to Blog Structure

```
LOG                          BLOG
────────────────────────────────────────────
Blog Seed hook        →     Opening paragraph
Context section       →     Setup / problem statement
Action section        →     "Here's what I did" narrative
  (technical details)   →     Code blocks with commentary
Result section        →     Outcome / what happened
  (metrics)             →     Concrete numbers in context
Reflection section    →     Takeaway / lessons learned
Resume Bullets        →     (not used)
Interview Points      →     (not used)
Potential angles      →     (used to choose narrative frame)
```

### Tone Shift

Logs are written for personal reference. Blog posts are written for an audience. The transformation should shift tone accordingly:

| Log Tone (resume-like) | Blog Tone (engaging) |
|------------------------|---------------------|
| "Migrated authentication service" | "Last month, our login system was held together with duct tape" |
| "Reduced failures by 40%" | "We went from 'why can't I log in?' tickets every morning to... silence" |
| "Led cross-team effort" | "Getting three teams to agree on anything is like herding cats with opinions" |
| "Established deployment checklist" | "The checklist that saved us from ourselves" |

### Section Templates

**Opening (from Blog Seed):**
```markdown
> {Blog Seed hook, adapted to chosen angle}

{1-2 sentences expanding the hook with context}
```

**Setup (from Context):**
```markdown
## The Problem

{Context section rewritten in narrative voice}
{Why this mattered — stakes, not just facts}
```

**Narrative (from Action):**
```markdown
## What I Did

{Action section as a story, not a report}
{Technical details in code blocks with language identifiers}
{Decision points — what you chose and why}
```

**Results (from Result):**
```markdown
## What Happened

{Outcome with specific numbers from metrics}
{Reactions, feedback, visible changes}
```

**Takeaway (from Reflection):**
```markdown
## What I Learned

{Reflection expanded for readers}
{Actionable insight others can use}
{What you'd do differently, if applicable}
```

## Combining Multiple Logs

When the user selects multiple logs for a single post:

1. **Find the thread**: What connects these accomplishments? A skill, a theme, a time period?
2. **Choose a meta-angle**: "How I leveled up at X", "Three lessons from...", "A year of..."
3. **Order for narrative flow**, not chronologically
4. **Each log becomes a section** with its own mini Context → Action → Result
5. **Shared reflection** ties them together at the end
6. **Tags combine and deduplicate** from all source logs

### Multi-log title patterns:
- "Three things I learned about [topic] this year"
- "How [skill] changed how I work"
- "From [starting point] to [ending point]: a journey in [topic]"

## Quality Checklist

Before finalizing a post from a thing log:

- [ ] Title is engaging, not resume-like
- [ ] Opening hook draws readers in (adapted from Blog Seed)
- [ ] Tone is natural and personal
- [ ] Technical details are accessible to the target audience
- [ ] Metrics are contextualized, not just raw numbers
- [ ] Takeaway is genuinely useful to readers
- [ ] Tags blend log tags with existing blog tags
- [ ] No internal jargon left unexplained
- [ ] Description works as a social media preview
- [ ] Heading hierarchy follows Quartz conventions (H2 → H3)
- [ ] Code blocks have language identifiers
- [ ] Callouts used sparingly and appropriately
