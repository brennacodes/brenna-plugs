# what-do-you-know

Deepen your understanding of topics through concept quizzing, knowledge gap analysis, and personalized learning plans — powered by your i-did-a-thing arsenal.

Different from generic learning tools because it knows what you've actually done. When you explore a topic, it grounds the conversation in your logged projects. When you quiz yourself, questions reference your real architecture decisions, not textbook scenarios. When it finds gaps, they're measured against your career goals and compared to evidence you've actually produced.

## Installation

```bash
claude plugin:add what-do-you-know
```

## Setup

Link to your shared trio config, set learning depth, default persona, session length, and focus areas.

```
/what-do-you-know:setup [reconfigure]
```

Requires i-did-a-thing to be set up first (`/i-did-a-thing:setup`).

## Skills

**Explore** — Topic-driven deep dive with a persona probing your understanding. Grounded in your arsenal — questions reference your actual projects, decisions, and lessons. Produces a concept map showing what's strong, partial, and missing.

```
/what-do-you-know:explore <topic> [--persona staff-engineer|...] [--depth exploratory|focused|deep]
```

**Quiz** — Concept-based spaced repetition with dynamically generated questions. No static question bank — every question is created from your index.json, referencing your real projects and experiences. Tracks scores over time for spaced repetition scheduling.

```
/what-do-you-know:quiz [--topic <topic>] [--persona staff-engineer|...] [--count 3|5|10]
```

**Gaps** — Knowledge gap analysis that cross-references your building and aspirational skills against arsenal evidence depth, evidence type diversity, learning session scores, and evidence recency. Classifies each area as Strong, Building, Gap, or Blind Spot.

```
/what-do-you-know:gaps [--focus building|aspirational|all]
```

**Bridge** — Personalized learning plan builder. Finds your closest existing knowledge and builds a path from there to the gap topic, with exercises tied to your actual projects and checkpoints using explore and quiz sessions.

```
/what-do-you-know:bridge <gap-topic> [--from <existing-strength>] [--timeline 1-week|2-weeks|1-month]
```

## How It Works

### Personas

Seven coaching personas shape the probing dialogue and feedback delivery. Shared with what-did-you-do and stored at `<things_path>/personas/`. Each persona has distinct evaluation weights and follow-up patterns adapted for learning (not interview coaching):

- **Staff Engineer** — technical depth, architecture, tradeoffs
- **Engineering Manager** — collaboration, communication, growth
- **Principal Engineer** — multi-year strategy, organizational impact
- **VP of Engineering** — business alignment, strategic leadership
- **CTO** — technical vision, competitive strategy
- **Recruiter** — communication clarity, motivation
- **Bar Raiser** — judgment, ownership, consistency

### Dynamic Questions

No static question bank. Questions are generated from your `index.json` on every session, referencing your actual:
- Architecture decisions and their tradeoffs
- Technologies you've used and their internals
- Projects you've built and their failure modes
- Patterns you've observed across experiences

### Scoring

Every answer is scored on five learning dimensions:

- **Depth** — how far below the surface can you explain? Internals vs. buzzwords
- **Accuracy** — are your mental models technically correct?
- **Connections** — can you relate this to adjacent concepts and your own experiences?
- **Application** — can you apply the knowledge to new situations?
- **Articulation** — can you explain it clearly to someone else?

### Knowledge Map

A living document at `<things_path>/learning/knowledge-map.md` that classifies your knowledge into:
- **Strong** — consistent depth, accuracy, ability to teach
- **Building** — partial understanding, some depth but gaps remain
- **Gap** — limited knowledge despite relevance to goals
- **Blind Spot** — relevant to target roles but unexplored

### Session Logging

Each session is saved with full frontmatter: per-dimension scores, concept classifications, arsenal cross-references, and recommendations for next steps.

### Progress Tracking

A rolling progress dashboard tracks dimension averages, trends, topic breakdowns, and concept strength across all sessions.

## Session Data

Stored alongside your i-did-a-thing data:

```
<things_path>/learning/
├── sessions/        # One file per explore or quiz session
├── progress.md      # Rolling learning progress dashboard
├── knowledge-map.md # Living knowledge area classifications
└── study-plans/     # Bridge learning plans
```

## Configuration

Settings are stored in the centralized trio config shared by all trio plugins:

- **Bootstrap**: `.claude/trio.local.md` (machine-local, contains `things_path`)
- **Full config**: `<things_path>/config.yml` (git-tracked, `learning:` section)

Run `/what-do-you-know:setup` to reconfigure learning preferences.

## Related Plugins

- **i-did-a-thing** — Log the experiences that power your learning sessions
- **what-did-you-do** — Practice interview questions with the same personas and arsenal
- **mark-my-words** — Turn your learning insights into blog posts
