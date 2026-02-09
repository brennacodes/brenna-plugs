# i-did-a-thing

A build-me-up tool that helps you log accomplishments and build tailored resumes from your personal arsenal of wins.

Each accomplishment goes through a guided deep-dive that extracts the full story — context, action, result, and reflection — then stores it as a structured, searchable log. The plugin automatically maintains skill-level arsenal summaries, pre-written resume bullets, interview talking points, and blog seeds from every entry. Log once, reuse everywhere.

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

**Log a Thing** — Capture an accomplishment through a guided deep-dive. Asks follow-up questions based on your answers — if you mention a team, it asks about your specific role; if you mention a decision, it asks about alternatives you considered. Classifies by impact level and category, auto-generates tags, and writes a structured log with resume bullets, interview talking points, and a blog seed.

```
/i-did-a-thing:thing-i-did [brief description]
```

**Build Resume** — Analyze a job listing (URL or pasted text), match it against your logged accomplishments, and produce a tailored resume. Shows you strong matches, partial matches, and gaps. Pulls resume bullets directly from your logs and adapts them to the listing's language. Optionally generates cover letter talking points and a gap action plan.

```
/i-did-a-thing:construct-resume [job listing URL or text]
```

## How It Works

Each accomplishment is logged via a guided deep-dive that extracts context, action, result, and reflection. Logs are stored as markdown files with rich frontmatter in your `.things` directory.

The plugin automatically maintains:

- **Arsenal files** — skill-level summaries with evidence from your logs, updated as you log new things
- **An index** — searchable, sorted by date, tag, and impact level
- **Resume bullets** — pre-written STAR-format bullets generated with each log entry

Logs include a Blog Seed section for use with `/mark-my-words:from-things`, and the celebration step points you to `/what-did-you-do:practice` for interview rehearsal.

## Directory Structure

```
<things_path>/
├── logs/           # Individual accomplishment logs
├── arsenal/        # Synthesized skill summaries (auto-generated)
├── targets/        # Professional goal tracking and profile
└── index.md        # Auto-generated index of all logs
```

Hooks automatically rebuild the index and update arsenal files after every new log.

## Configuration

Settings are stored in `.claude/i-did-a-thing.local.md`. Run setup again to reconfigure.

## Related Plugins

- **what-did-you-do** — Practice interview questions coached by your arsenal
- **mark-my-words** — Turn your logs into blog posts with `/mark-my-words:from-things`
