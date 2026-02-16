---
name: quiz
description: "Test your knowledge with dynamically generated concept questions drawn from your actual projects and experiences"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--topic <topic>] [--persona staff-engineer|engineering-manager|...] [--count 3|5|10]"
---

# Quiz

Generate concept questions dynamically from your arsenal and index, present them in a persona's voice, score answers on learning dimensions, and track progress via spaced repetition.

## Steps

### 1. Load Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Read `<home>/.claude/things.local.md` to get `things_path` (if `things_path` starts with `~`, replace with `<home>`). If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

Read `<things_path>/config.yml` for all settings. Extract `building_skills`, `aspirational_skills` from the shared profile, and `default_depth`, `default_persona`, `session_length` from `learning:`.

### 2. Load Arsenal and Index

Read `<things_path>/index.json` for structured entry data.
Read all files in `<things_path>/arsenal/` for skill evidence.

If no logs exist:

> You haven't logged any entries yet. Run `/i-did-a-thing:thing-i-did` first — quiz questions are generated from your actual projects and experiences.

Then stop.

### 3. Load Session History

Run: `bash <plugin_root>/scripts/search-sessions.sh --recent 20`

Use session history for spaced repetition: weight toward topics with lower scores, longer time since last quiz, and gaps identified in explore sessions.

### 4. Select Topic

If `--topic` was provided, use it.

Otherwise, select a topic using spaced repetition weighting:
1. Topics with gap or partial scores from recent explore/quiz sessions
2. Topics from `building_skills` and `aspirational_skills` not recently quizzed
3. Topics with declining scores (tested before but getting worse)
4. Random selection from arsenal skill areas not yet explored

Use AskUserQuestion to confirm:

**I'm thinking we should quiz [topic] — it's been [reason]. Sound good?**
- Yes — let's do it
- Different topic — I have something in mind

### 5. Select Persona

If `--persona` was provided, use it. Otherwise, use `default_persona` from config.

Load the selected persona from `<things_path>/personas/<persona>.md`. Adopt their voice for question delivery and feedback.

### 6. Determine Question Count

If `--count` was provided, use it. Otherwise, base on `session_length`:
- **short** → 3 questions
- **medium** → 5 questions
- **deep** → 10 questions

### 7. Generate Questions Dynamically

Generate questions from `index.json` — NOT from a static question bank. Each question should reference the user's actual projects and experiences:

**Question generation patterns:**

- **Mechanism**: "Explain how [mechanism from their project] works under the hood." (e.g., "Explain how the PostToolUse hook mechanism works in your screenshotr plugin")
- **Tradeoff**: "What are the tradeoffs of [approach they chose] vs. [alternative]?" (e.g., "What are the tradeoffs of atomic file writes vs. direct writes?")
- **Decision rationale**: "You chose [decision from log]. What alternatives exist and why did you pick this?" (e.g., "You chose Homebrew for distribution. What alternatives exist and why?")
- **Failure mode**: "What would go wrong if [component from their project] failed? How would you detect and recover?"
- **Generalization**: "You applied [pattern] in [project]. Where else would this pattern be useful? Where would it break down?"
- **Connection**: "How does [concept A from project 1] relate to [concept B from project 2]?"
- **Teaching**: "Explain [concept from their work] to someone who's never seen it before."

**Selection algorithm:**
1. Filter index entries by topic relevance (tags, skills_used, skills_developed)
2. For each entry, identify 2-3 potential question angles
3. Score potential questions:
   - `gap_weight = 5 - avg_score_for_topic` (from session history)
   - `recency_bonus = days_since_last_asked / 14` (capped at 2.0)
   - `variety_bonus = 1.5 if question_type not recently used`
4. Select from top-scored questions with weighted randomness

### 8. Present Questions

Present questions one at a time in the persona's voice:

> **[Persona Name]**: <question>
>
> Take your time. Think through it carefully before answering.

After each answer, briefly acknowledge but don't give detailed feedback yet (unless `session_length` is short — in which case give per-question feedback).

### 9. Score Each Answer

Score each answer on the five learning dimensions (from `references/quiz-rubric.md`):

1. **Depth** (1-5) — Surface-level recall vs. deep understanding
2. **Accuracy** (1-5) — Technically correct mental models
3. **Connections** (1-5) — Links to related concepts and experiences
4. **Application** (1-5) — Can apply to new scenarios
5. **Articulation** (1-5) — Clear, structured explanation

Classify each answer's concept as: **strong** | **partial** | **gap**

### 10. Deliver Feedback

After all questions, deliver batched feedback:

> **Quiz Results: [Topic]**
>
> | # | Concept | Score | Strength |
> |---|---------|-------|----------|
> | 1 | <concept> | x/5 | strong/partial/gap |
> | 2 | <concept> | x/5 | strong/partial/gap |
> | ... | | | |
>
> **Overall Dimensions:**
>
> | Dimension | Score | Notes |
> |-----------|-------|-------|
> | Depth | x/5 | <brief note> |
> | Accuracy | x/5 | <brief note> |
> | Connections | x/5 | <brief note> |
> | Application | x/5 | <brief note> |
> | Articulation | x/5 | <brief note> |
>
> **What you nailed:** <strongest answers>
>
> **Where to dig deeper:** <weakest areas with specific suggestions>
>
> **From your arsenal:** <entries that could strengthen weak answers>

### 11. Log the Session

Write a session file at `<things_path>/learning/sessions/<date>-quiz-<topic-slug>.md`:

```markdown
---
type: quiz
date: <date>
topic: <topic>
persona: <persona>
question_count: <N>
scores:
  depth: <1-5>
  accuracy: <1-5>
  connections: <1-5>
  application: <1-5>
  articulation: <1-5>
  overall: <average>
per_question:
  - concept: "<concept>"
    score: <1-5>
    strength: strong|partial|gap
  - concept: "<concept>"
    score: <1-5>
    strength: strong|partial|gap
arsenal_references:
  - file: "<log filename>"
---

# Quiz Session: <topic> — <date>

## Questions and Answers
<per-question summary>

## Feedback
<summary of feedback>

## Spaced Repetition Notes
<concepts to re-quiz, suggested interval>
```

### 12. Update Progress

Read and update `<things_path>/learning/progress.md` and `<things_path>/learning/knowledge-map.md` with new scores and concept classifications.

### 13. Offer Next Steps

Use AskUserQuestion:

**What next?**
- Quiz again (same topic, different questions)
- Quiz a different topic
- Explore a weak area from this quiz
- Bridge a gap to build a learning plan
- Done for now

If quiz again on same topic, go back to Step 7. If different topic, go to Step 4.
