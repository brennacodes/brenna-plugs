# brenna-plugs

![installs](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbrennacodes%2Fbrenna-plugs%2Fmain%2F.github%2Fdata%2Fclones.json&query=%24.total&label=installs&color=brightgreen)

A Claude Code plugin marketplace by [brennacodes](https://github.com/brennacodes).

Three plugins for building a professional reputation from the ground up. Log what you do, practice talking about it, write about it publicly. Each plugin works on its own, but together they create a single source of truth — log an accomplishment once, and it flows into interview prep, resume building, and blog posts without re-telling the story from scratch every time.

**i-did-a-thing** is the foundation. You log accomplishments through a guided deep-dive, and the plugin builds a searchable arsenal of evidence — tagged, classified, and pre-formatted for reuse. Every log generates resume bullets, interview talking points, and a blog seed automatically.

**what-did-you-do** reads that arsenal and uses it to coach you. When you practice an interview question, it cross-references your logged accomplishments, points out evidence you forgot to mention, and flags skills you've demonstrated but never articulated. When you run a mock interview for Amazon, it maps your arsenal to their Leadership Principles and shows where you're strong and where you have gaps.

**mark-my-words** turns the same logs into public writing. The `from-things` skill pulls a log's narrative structure and metrics into a blog post draft — you choose the angle, and it handles the transformation from structured career evidence to an engaging first-person story on your Quartz site.

The loop compounds: logging more accomplishments makes your interviews sharper and your writing richer. Practicing interviews exposes gaps to log. Writing about what you've done forces you to articulate impact clearly — which makes you better at interviews.

## Installation

Add the marketplace from GitHub:

```
/plugin marketplace add brennacodes/brenna-plugs
```

Or from a local clone:

```
/plugin marketplace add <path_to_brenna_plugs>
```

Then install plugins:

```
/plugin install i-did-a-thing@brenna-plugs
```

```
/plugin install what-did-you-do@brenna-plugs
```

```
/plugin install mark-my-words@brenna-plugs
```

## Plugins

### i-did-a-thing

Log accomplishments and build tailored resumes from your personal arsenal of wins.

**Setup** — Configure your .things directory, git remote, professional goals, and preferences.

```
/i-did-a-thing:setup [reconfigure]
```

**Log a Thing** — Capture an accomplishment through a guided deep-dive that extracts context, action, result, and reflection.

```
/i-did-a-thing:thing-i-did [brief description]
```

**Build Resume** — Analyze a job listing, match it against your logged accomplishments, and produce a tailored resume.

```
/i-did-a-thing:construct-resume [job listing URL or text]
```

### what-did-you-do

Interview preparation with persona-driven practice, company-specific mocks, spaced repetition, and progress tracking — powered by your i-did-a-thing arsenal.

**Setup** — Link to your i-did-a-thing data, set interview preferences, and initialize session tracking.

```
/what-did-you-do:setup [reconfigure]
```

**Practice** — Drill a single question with a selected interviewer persona and arsenal-powered feedback.

```
/what-did-you-do:practice [behavioral|technical|leadership|situational|system-design]
```

**Mock Interview** — Simulate a full interview round with timed questions and an end-of-round debrief.

```
/what-did-you-do:mock [amazon|google|meta] [--stage phone-screen|onsite|bar-raiser]
```

**Review Readiness** — Assess interview readiness with trend analysis and gap identification.

```
/what-did-you-do:review [--company amazon|google|meta] [--since YYYY-MM-DD]
```

**Prep For** — Build a company-specific preparation plan with value mapping and a practice timeline.

```
/what-did-you-do:prep-for <company> [--role <target role>] [--level <level>]
```

**Update Questions** — Add new questions from trusted sources or manual entry.

```
/what-did-you-do:update-questions <url or 'manual'>
```

### mark-my-words

Write, manage, and publish blog posts on Quartz static sites.

**Setup** — Configure your Quartz blog source, author info, and publishing preferences.

```
/mark-my-words:setup
```

**New Post** — Write a new blog post. Walks you through topic, angle, length, and tags, then generates the post.

```
/mark-my-words:new-post [topic or idea]
```

**Update Post** — Edit an existing post — revise sections, append content, rewrite, or update metadata.

```
/mark-my-words:update-post [filename or search term]
```

**Manage Posts** — List, search, and organize posts — drafts, tags, publishing status.

```
/mark-my-words:manage-post [list, drafts, publish, tags]
```

**From Things** — Turn i-did-a-thing accomplishment logs into blog posts.

```
/mark-my-words:from-things [log filename or search query]
```
