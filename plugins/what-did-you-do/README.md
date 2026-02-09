# what-did-you-do

Interview preparation with persona-driven practice, company-specific mock interviews, spaced repetition question selection, and progress tracking — powered by your i-did-a-thing arsenal.

Different from generic interview prep because it knows what you've actually done. When you answer a question, it cross-references your logged accomplishments, points out evidence you forgot to mention, flags metrics you could have cited, and identifies skills you demonstrated but didn't articulate. Over time, spaced repetition targets your weakest areas and tracks improvement across scoring dimensions.

## Installation

```bash
claude plugin:add what-did-you-do
```

## Setup

Link to your i-did-a-thing data, set follow-up depth (concise, detailed, or coaching), default interview stage, and trusted sources for question bank updates.

```
/what-did-you-do:setup [reconfigure]
```

## Skills

**Practice** — Drill a single question with a selected interviewer persona. Questions are chosen via spaced repetition — weighted toward your weak areas, filtered to avoid recent repeats, and boosted for aspirational skills. Feedback scores five dimensions and references your arsenal.

```
/what-did-you-do:practice [behavioral|technical|leadership|situational|system-design]
```

**Mock Interview** — Simulate a full interview round. Multiple timed questions from a consistent persona with no feedback between questions — just like the real thing. Comprehensive debrief at the end with per-question scores, company value alignment, and action items. Supports Amazon, Google, Meta, and custom company profiles.

```
/what-did-you-do:mock [amazon|google|meta] [--stage phone-screen|onsite|bar-raiser]
```

**Review Readiness** — Analyze all your sessions to produce a readiness assessment. Dimension trends (improving, stable, declining), category breakdowns, persistent anti-pattern tracking, skill coverage gaps, and company-specific calibration against level expectations.

```
/what-did-you-do:review [--company amazon|google|meta] [--since YYYY-MM-DD]
```

**Prep For** — Build a preparation plan for a specific company. Maps your arsenal to their values, walks through each interview stage with persona and format details, predicts likely questions, and generates a practice timeline scaled to when your interview is.

```
/what-did-you-do:prep-for <company> [--role <target role>] [--level <level>]
```

**Update Questions** — Add questions from trusted external sources or manual entry. Validates against your trusted domains, deduplicates against existing questions, and auto-generates metadata (skills tested, difficulty, follow-ups, red/green flags).

```
/what-did-you-do:update-questions <url or 'manual'>
```

## How It Works

### Personas

Seven interviewer personas shape how questions are asked and feedback is delivered. Each persona has distinct evaluation weights, follow-up patterns, and anti-pattern detection:

- **Staff Engineer** — technical depth, tradeoffs, system thinking
- **Engineering Manager** — collaboration, communication, growth
- **Principal Engineer** — multi-year strategy, organizational impact
- **VP of Engineering** — business alignment, strategic leadership
- **CTO** — technical vision, competitive strategy
- **Recruiter** — motivation, culture fit, communication clarity
- **Bar Raiser** — judgment, ownership, consistency across angles

### Question Bank

45 built-in questions across five categories (behavioral, technical, system-design, leadership, situational) with rich metadata: skills tested, difficulty, follow-ups at multiple depths, red/green flags, time budgets, and level/stage filtering.

Questions are selected using spaced repetition — weighted toward your weak areas, filtered to avoid recent repeats, and boosted for aspirational skills.

### Company Profiles

Built-in profiles for Amazon (14 Leadership Principles), Google, and Meta define each company's values with interview signals and anti-patterns, full interview process with stage-by-stage format and persona mappings, and level expectations. Custom company profiles are supported.

### Scoring

Every answer is scored on five dimensions:

- **Specificity** — concrete details vs vague claims
- **Structure** — clear narrative arc (STAR/CAR format)
- **Impact** — quantified outcomes and scope
- **Relevance** — actually answers the question asked
- **Self-Advocacy** — owns contribution without hogging credit

### Session Logging

Each session is saved as an individual file with full frontmatter: per-dimension scores, anti-patterns detected with examples, arsenal cross-references, unlogged accomplishment hints, and comparison to previous attempts.

### Progress Tracking

A rolling readiness dashboard tracks dimension averages, trends, category breakdowns, and persistent anti-patterns across all sessions.

## Session Data

Stored alongside your i-did-a-thing data:

```
<things_path>/interview-prep/
├── sessions/           # One file per practice or mock session
├── progress.md         # Rolling readiness dashboard
├── companies/          # User-created company profiles
└── question-overrides/ # Custom questions
```

## Configuration

Settings are stored in `.claude/what-did-you-do.local.md`. Run setup again to reconfigure.

## Related Plugins

- **i-did-a-thing** — Log the accomplishments that power your interview feedback
- **mark-my-words** — Turn your accomplishments into blog posts
