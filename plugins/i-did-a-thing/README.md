# i-did-a-thing

Log professional experiences — accomplishments, lessons, expertise, decisions, influence, and insights — and build tailored resumes from your evidence arsenal.

Not everything worth remembering is a win. A hard lesson, deep expertise on a topic, a tough call you can articulate, influence you exercised without authority, or a pattern you noticed — all of these are interview gold and career evidence. The plugin captures each type through a guided deep-dive tailored to what kind of thing it is, then stores it as a structured, searchable log. The plugin automatically maintains skill-level arsenal summaries, pre-written resume bullets, interview talking points, and blog seeds from every entry. Log once, reuse everywhere.

## Installation

```bash
claude plugin:add i-did-a-thing
```

## Setup

Configure your .things directory (project-local or global), git remote, professional profile (current role, target roles, skills you're building), and preferences. This creates the shared trio config used by i-did-a-thing, what-did-you-do, and mark-my-words.

```
/i-did-a-thing:setup [reconfigure]
```

**Migrating from v2.x?** Run `/i-did-a-thing:migrate-things` to move from per-plugin configs to the centralized trio config.

## Skills

**Log a Thing** — Capture a professional experience with context-aware speed. If you paste a rich transcript, decision summary, or detailed description — or if the conversation already has relevant context — the skill extracts log fields automatically, shows you a summary, and confirms before writing. Only asks about genuinely missing details. For sparse context, it falls back to a full guided deep-dive that adapts based on what kind of thing it is: accomplishments get Context-Action-Result questions, lessons explore what went wrong and what you took from it, expertise entries dig into depth and teaching, decisions walk through options and tradeoffs, influence entries cover advocacy and outcomes, and insights explore observations and theses. Classifies by impact level and category, auto-generates tags, and writes a structured log with resume bullets, interview talking points, and a blog seed. Use `--interview` to force the full interview even when context is available.

```
/i-did-a-thing:thing-i-did [description, pasted context, or --interview]
```

**Build Resume** — Analyze a job listing (URL or pasted text), match it against your logged evidence, and produce a tailored resume. Weights evidence types by what the listing emphasizes — technical depth surfaces expertise entries, learning agility surfaces lessons, sound judgment surfaces decisions. Shows you strong matches, partial matches, and gaps. Pulls resume bullets directly from your logs in their type-appropriate format. Optionally generates cover letter talking points and a gap action plan that suggests specific evidence types to log.

```
/i-did-a-thing:construct-resume [job listing URL or text]
```

**Migrate** — Move from per-plugin configs to the centralized trio config. Run this after updating to v3.0.0.

```
/i-did-a-thing:migrate-things [--dry-run]
```

## Evidence Types

| Type | What it captures |
|------|-----------------|
| `accomplishment` | You did something with a measurable outcome |
| `lesson` | Something didn't go as planned, but you extracted value |
| `expertise` | You went deep on a topic and became a resource |
| `decision` | You evaluated options, made a judgment call, and can articulate why |
| `influence` | You shaped someone else's decision, advocated for a change, or mentored someone |
| `insight` | You noticed a pattern, formed a thesis, developed a perspective |

## How It Works

Each entry is logged via a guided deep-dive whose questions adapt to the evidence type. Logs are stored as markdown files with rich frontmatter in your `.things` directory.

The plugin automatically maintains:

- **Arsenal files** — skill-level summaries with evidence from your logs, tagged by evidence type, fully regenerated on every log write
- **A JSON index** — `index.json` with all entry data inline (frontmatter, resume bullets, body sections, talking points, blog seeds)
- **A tag index** — `tags.json` with tag counts and last-used dates
- **Resume bullets** — pre-written bullets generated with each log entry in the type-appropriate format

Logs include a Blog Seed section for use with `/mark-my-words:from-things`, and the celebration step points you to `/what-did-you-do:practice` for interview rehearsal.

## Directory Structure

```
<things_path>/
├── config.yml      # Shared config for all trio plugins
├── logs/           # Individual log entries
├── arsenal/        # Synthesized skill summaries (auto-regenerated)
├── voices/         # Voice profiles for blog writing
├── personas/       # Shared coaching personas
├── companies/      # Shared company profiles
├── index.json      # Auto-generated JSON index of all logs
└── tags.json       # Auto-generated tag counts
```

A PostToolUse hook automatically regenerates `index.json`, `tags.json`, and all arsenal files after every new log.

## Configuration

Settings are stored in a centralized config shared by all trio plugins:

- **Bootstrap**: `.claude/trio.local.md` (machine-local, contains `things_path`)
- **Full config**: `<things_path>/config.yml` (git-tracked, all settings)

Run `/i-did-a-thing:setup` to reconfigure.

## Related Plugins

- **what-did-you-do** — Practice interview questions coached by your arsenal, with evidence-type-aware feedback
- **what-do-you-know** — Deepen your understanding through concept quizzing, gap analysis, and learning plans
- **mark-my-words** — Turn your logs into blog posts with `/mark-my-words:from-things`
