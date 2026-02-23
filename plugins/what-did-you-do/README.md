# what-did-you-do

Interview preparation with persona-driven practice, company-specific mock interviews, spaced repetition question selection, and progress tracking - powered by your i-did-a-thing arsenal.

Different from generic interview prep because it knows what you've actually done. When you answer a question, it cross-references your logged accomplishments, points out evidence you forgot to mention, flags metrics you could have cited, and identifies skills you demonstrated but didn't articulate. Over time, spaced repetition targets your weakest areas and tracks improvement across scoring dimensions.

## Installation

```
/plugin install what-did-you-do@brenna-plugs
```

## Setup

Configure interview preferences, set follow-up depth (concise, detailed, or coaching), default interview stage, and trusted sources for question bank updates.

```
/setup-wdyd [reconfigure]
```

Requires things to be set up first (`/things:setup`).

## Skills

**Practice** - Drill a single question with a selected interviewer persona. Questions are chosen via spaced repetition - weighted toward your weak areas, filtered to avoid recent repeats, and boosted for aspirational skills. Feedback scores five dimensions and references your arsenal.

```
/practice [behavioral|technical|leadership|situational|system-design]
```

**Mock Interview** - Simulate a full interview round. Multiple timed questions from a consistent persona with no feedback between questions - just like the real thing. Comprehensive debrief at the end with per-question scores, company value alignment, and action items. Supports Amazon, Google, Meta, and custom company profiles.

```
/mock [amazon|google|meta] [--stage phone-screen|onsite|bar-raiser]
```

**Review Readiness** - Analyze all your sessions to produce a readiness assessment. Dimension trends (improving, stable, declining), category breakdowns, persistent anti-pattern tracking, skill coverage gaps, and company-specific calibration against level expectations.

```
/review [--company amazon|google|meta] [--since YYYY-MM-DD]
```

**Prep For** - Build a preparation plan for a specific company. Maps your arsenal to their values, walks through each interview stage with persona and format details, predicts likely questions, and generates a practice timeline scaled to when your interview is.

```
/prep-for <company> [--role <target role>] [--level <level>]
```

**Update Questions** - Add questions from trusted external sources or manual entry. Validates against your trusted domains, deduplicates against existing questions, and auto-generates metadata (skills tested, difficulty, follow-ups, red/green flags).

```
/update-questions <url or 'manual'>
```

**Migrate Data** - Move what-did-you-do data from the old `~/.things/interview-prep/` layout to the per-plugin directory structure. Moves sessions, question overrides, company prep plans, and converts the markdown progress dashboard to JSON. Run `/things:setup` first if config.json doesn't exist yet.

```
/migrate-wdyd [--dry-run]
```

## How It Works

### Personas

Seven interviewer personas shape how questions are asked and feedback is delivered. Personas are shared with what-do-you-know and stored at `~/.things/shared/roles/`. Each persona has distinct evaluation weights, follow-up patterns, and anti-pattern detection:

- **Staff Engineer** - technical depth, tradeoffs, system thinking
- **Engineering Manager** - collaboration, communication, growth
- **Principal Engineer** - multi-year strategy, organizational impact
- **VP of Engineering** - business alignment, strategic leadership
- **CTO** - technical vision, competitive strategy
- **Recruiter** - motivation, culture fit, communication clarity
- **Bar Raiser** - judgment, ownership, consistency across angles

### Question Bank

45 built-in questions across five categories (behavioral, technical, system-design, leadership, situational) with rich metadata: skills tested, difficulty, follow-ups at multiple depths, red/green flags, time budgets, and level/stage filtering.

Questions are selected using spaced repetition - weighted toward your weak areas, filtered to avoid recent repeats, and boosted for aspirational skills.

### Company Profiles

Built-in profiles for Amazon (14 Leadership Principles), Google, and Meta are shared across plugins and stored at `~/.things/shared/companies/`. Each defines company values with interview signals and anti-patterns, full interview process with stage-by-stage format and persona mappings, and level expectations. Custom company profiles are supported - add them to the same directory.

### Scoring

Every answer is scored on five dimensions:

- **Specificity** - concrete details vs vague claims
- **Structure** - clear narrative arc (STAR/CAR format)
- **Impact** - quantified outcomes and scope
- **Relevance** - actually answers the question asked
- **Self-Advocacy** - owns contribution without hogging credit

### Session Logging

Each session is saved as an individual file with full frontmatter: per-dimension scores, anti-patterns detected with examples, arsenal cross-references, unlogged accomplishment hints, and comparison to previous attempts.

### Progress Tracking

A rolling readiness dashboard tracks dimension averages, trends, category breakdowns, and persistent anti-patterns across all sessions.

## Session Data

```
~/.things/what-did-you-do/
├── preferences.json    # Interview preferences
├── sessions/           # One file per practice or mock session
├── progress.json       # Rolling readiness dashboard
└── questions/
    └── custom.yaml     # Custom questions
```

## Configuration

- **Global config**: `~/.things/config.json` (managed by things)
- **Plugin preferences**: `~/.things/what-did-you-do/preferences.json`

Run `/setup-wdyd` to reconfigure.

## Related Plugins

- **things** - Data layer that manages shared config and plugin coordination
- **i-did-a-thing** - Log the accomplishments that power your interview feedback
- **what-do-you-know** - Deepen your understanding through concept quizzing and learning plans, using the same personas
- **think-like** - Expert thinking profiles for different perspectives on your preparation
- **mark-my-words** - Turn your accomplishments into blog posts
