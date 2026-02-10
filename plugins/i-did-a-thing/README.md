# i-did-a-thing

Log professional experiences — accomplishments, lessons, expertise, decisions, influence, and insights — and build tailored resumes from your evidence arsenal.

Not everything worth remembering is a win. A hard lesson, deep expertise on a topic, a tough call you can articulate, influence you exercised without authority, or a pattern you noticed — all of these are interview gold and career evidence. The plugin captures each type through a guided deep-dive tailored to what kind of thing it is, then stores it as a structured, searchable log. The plugin automatically maintains skill-level arsenal summaries, pre-written resume bullets, interview talking points, and blog seeds from every entry. Log once, reuse everywhere.

## Installation

```bash
claude plugin:add i-did-a-thing
```

## Setup

Configure your .things directory (project-local or global), git remote, professional profile (current role, target roles, skills you're building), and preferences.

```
/i-did-a-thing:setup [reconfigure]
```

## Skills

**Log a Thing** — Capture a professional experience through a guided deep-dive. The interview adapts based on what kind of thing it is: accomplishments get Context-Action-Result questions, lessons explore what went wrong and what you took from it, expertise entries dig into depth and teaching, decisions walk through options and tradeoffs, influence entries cover advocacy and outcomes, and insights explore observations and theses. Classifies by impact level and category, auto-generates tags, and writes a structured log with resume bullets, interview talking points, and a blog seed.

```
/i-did-a-thing:thing-i-did [brief description]
```

**Build Resume** — Analyze a job listing (URL or pasted text), match it against your logged evidence, and produce a tailored resume. Weights evidence types by what the listing emphasizes — technical depth surfaces expertise entries, learning agility surfaces lessons, sound judgment surfaces decisions. Shows you strong matches, partial matches, and gaps. Pulls resume bullets directly from your logs in their type-appropriate format. Optionally generates cover letter talking points and a gap action plan that suggests specific evidence types to log.

```
/i-did-a-thing:construct-resume [job listing URL or text]
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

- **Arsenal files** — skill-level summaries with evidence from your logs, tagged by evidence type, updated as you log new things
- **An index** — searchable, sorted by date, tag, impact level, and evidence type
- **Resume bullets** — pre-written bullets generated with each log entry in the type-appropriate format

Logs include a Blog Seed section for use with `/mark-my-words:from-things`, and the celebration step points you to `/what-did-you-do:practice` for interview rehearsal.

## Directory Structure

```
<things_path>/
├── logs/           # Individual log entries
├── arsenal/        # Synthesized skill summaries (auto-generated)
├── targets/        # Professional goal tracking and profile
└── index.md        # Auto-generated index of all logs
```

Hooks automatically rebuild the index and update arsenal files after every new log.

## Configuration

Settings are stored in `.claude/i-did-a-thing.local.md`. Run setup again to reconfigure.

## Related Plugins

- **what-did-you-do** — Practice interview questions coached by your arsenal, with evidence-type-aware feedback
- **mark-my-words** — Turn your logs into blog posts with `/mark-my-words:from-things`
