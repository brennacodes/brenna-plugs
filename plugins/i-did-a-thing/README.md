# i-did-a-thing

Log professional experiences - accomplishments, lessons, expertise, decisions, influence, and insights - and build tailored resumes from your evidence arsenal.

Not everything worth remembering is a win. A hard lesson, deep expertise on a topic, a tough call you can articulate, influence you exercised without authority, or a pattern you noticed - all of these are interview gold and career evidence. The plugin captures each type through a guided deep-dive tailored to what kind of thing it is, then stores it as a structured, searchable log. The plugin automatically maintains skill-level arsenal summaries, pre-written resume bullets, interview talking points, and blog seeds from every entry. Log once, reuse everywhere.

## Installation

```
/plugin install i-did-a-thing@brenna-plugs
```

## Setup

Requires things (`/things:setup`). Configures logging preferences.

```
/setup-idat
```

To reconfigure:

```
/setup-idat reconfigure
```

## Skills

**Log a Thing** - Capture a professional experience with context-aware speed. If you paste a rich transcript, decision summary, or detailed description - or if the conversation already has relevant context - the skill extracts log fields automatically, shows you a summary, and confirms before writing. Only asks about genuinely missing details. For sparse context, it falls back to a full guided deep-dive that adapts based on what kind of thing it is: accomplishments get Context-Action-Result questions, lessons explore what went wrong and what you took from it, expertise entries dig into depth and teaching, decisions walk through options and tradeoffs, influence entries cover advocacy and outcomes, and insights explore observations and theses. Classifies by impact level and category, auto-generates tags, and writes a structured log with resume bullets, interview talking points, and a blog seed. Use `--interview` to force the full interview even when context is available.

```
/thing-i-did [description, pasted context, or --interview]
```

**Build Resume** - Analyze a job listing (URL or pasted text), match it against your logged evidence, and produce a tailored resume. Weights evidence types by what the listing emphasizes - technical depth surfaces expertise entries, learning agility surfaces lessons, sound judgment surfaces decisions. Shows you strong matches, partial matches, and gaps. Pulls resume bullets directly from your logs in their type-appropriate format. Optionally generates cover letter talking points and a gap action plan that suggests specific evidence types to log.

```
/construct-resume [job listing URL or text]
```

**Migrate Data** - Move i-did-a-thing data files from the old flat `~/.things/` layout to the per-plugin directory structure. Moves logs, arsenal, resumes, index.json, and tags.json. Run `/things:setup` first if config.json doesn't exist yet.

```
/migrate-idat [--dry-run]
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

Each entry is logged via a guided deep-dive whose questions adapt to the evidence type. Logs are stored as markdown files with rich frontmatter in your `.things/` directory.

The plugin automatically maintains:

- **Arsenal files** - skill-level summaries with evidence from your logs, tagged by evidence type, fully regenerated on every log write
- **A JSON index** - `index.json` with all entry data inline (frontmatter, resume bullets, body sections, talking points, blog seeds)
- **A tag index** - `tags.json` with tag counts and last-used dates
- **Resume bullets** - pre-written bullets generated with each log entry in the type-appropriate format

Logs include a Blog Seed section for use with `/from-things`, and the celebration step points you to `/practice` for interview rehearsal.

## Directory Structure

```
~/.things/
├── config.json                    # Shared config (managed by things)
├── shared/
│   ├── professional-profile.json  # Career profile
│   ├── roles/                     # Interviewer personas
│   └── companies/                 # Company profiles
└── i-did-a-thing/
    ├── preferences.json           # Plugin preferences
    ├── logs/                      # Individual log entries
    ├── arsenal/                   # Synthesized skill summaries
    ├── resumes/                   # Generated resumes
    ├── index.json                 # Auto-generated index
    └── tags.json                  # Auto-generated tag counts
```

The things plugin's PostToolUse hook automatically regenerates `index.json`, `tags.json`, and all arsenal files after every new log via the registry rebuild dispatch.

## Configuration

- Global config: `~/.things/config.json` (managed by things)
- Plugin preferences: `~/.things/i-did-a-thing/preferences.json`

Run `/setup-idat` to reconfigure.

## Related Plugins

- **things** - Foundation data layer that manages `.things/`, git sync, search, validation, and rebuild dispatch
- **what-did-you-do** - Practice interview questions coached by your arsenal, with evidence-type-aware feedback
- **what-do-you-know** - Deepen your understanding through concept quizzing, gap analysis, and learning plans
- **mark-my-words** - Turn your logs into blog posts with `/from-things`
- **think-like** - Apply expert thinking profiles for code review, architecture, security analysis, and more
