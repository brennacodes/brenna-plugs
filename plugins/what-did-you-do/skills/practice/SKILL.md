---
name: practice
description: "Drill a single interview question with persona-driven feedback, arsenal cross-references, and spaced repetition selection"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[category: behavioral|technical|leadership|situational|system-design] [--persona staff-engineer|engineering-manager|...]"
---

# Practice

Select a question using spaced repetition, adopt an interviewer persona, coach the user's answer, then log a detailed session file.

## Steps

### 1. Load Configuration

Read `.claude/what-did-you-do.local.md` to get settings. If missing:

> No configuration found. Please run `/what-did-you-do:setup` first.

Then stop.

Read `.claude/i-did-a-thing.local.md` to get `things_path`. Extract `building_skills`, `aspirational_skills`, `current_role`, and `target_roles`.

### 2. Load the User's Arsenal

Read all files in `<things_path>/arsenal/` to understand logged skills and evidence. Read `<things_path>/targets/profile.md` for professional goals.

If no logs exist:

> You haven't logged any entries yet. Run `/i-did-a-thing:thing-i-did` first so I have your arsenal to coach you with. I can still ask questions, but my feedback will be much richer with your evidence loaded.

### 3. Load Session History

Run: `bash <plugin_root>/scripts/search-sessions.sh --recent 10`

Use recent session data for spaced repetition: avoid recently asked questions, weight toward weak dimensions.

### 4. Select Persona

If the user specified `--persona`, load that persona file from `<plugin_root>/personas/<persona>.md`.

If not, select based on the question's `interviewer_types` field. If no question yet, use AskUserQuestion:

**Who's interviewing you today?**
- Staff Engineer — technical depth, architecture, tradeoffs
- Engineering Manager — collaboration, communication, growth
- Principal Engineer — system thinking, organizational impact
- Bar Raiser — judgment, ownership, cross-functional depth
- Recruiter — motivation, culture fit, communication clarity
- Surprise — I'll pick based on the question

Read the selected persona file and adopt their voice, evaluation weights, and follow-up patterns.

### 5. Select Question Category

If the user provided a category argument, use it. Otherwise, use AskUserQuestion:

**What kind of question?**
- `behavioral` — "Tell me about a time when..."
- `technical` — Architecture, code quality, operations
- `system-design` — End-to-end system architecture
- `leadership` — Mentorship, decisions, strategy
- `situational` — "What would you do if..."
- `surprise` — Weighted toward your gaps

### 6. Select Question Using Spaced Repetition

Read `<plugin_root>/questions/<category>.yaml` (and `<things_path>/interview-prep/question-overrides/custom.yaml` for custom questions).

**Selection algorithm:**
1. Filter by category (and stage if `default_stage` is set in config)
2. Filter by level appropriate to `current_role` and `target_roles`
3. Filter out questions asked in the last 7 days (from session history)
4. Score remaining questions:
   - `weakness_weight = 5 - avg_score_for_skills_tested` (from session history)
   - `recency_bonus = days_since_last_asked / 14` (capped at 2.0)
   - `aspirational_bonus = 1.5 if any skill_tested is in aspirational_skills, else 0`
   - `total = weakness_weight + recency_bonus + aspirational_bonus`
5. Select from top-scored questions with some randomness (weighted random, not strictly top)

### 7. Ask the Question

Present the question in the persona's voice:

> **[Persona Name]**: <question>
>
> Take your time. Answer as if you're in an actual interview.

Note the question's `time_budget_minutes` and `expected_format` for coaching context, but don't display them to the user.

### 8. Receive and Analyze the Answer

After the user answers, analyze against five dimensions (from `references/feedback-rubric.md`):

1. **Specificity** (1-5) — Concrete details vs vague claims
2. **Structure** (1-5) — Clear narrative arc (STAR/CAR)
3. **Impact** (1-5) — Quantified outcomes, scope of effect
4. **Relevance** (1-5) — Actually answers the question asked
5. **Self-Advocacy** (1-5) — Owns contribution without hogging credit

Check the answer against the question's `red_flags` and `green_flags`.

Cross-reference with arsenal, prioritizing evidence types by question theme:
- If the question asks about failure or challenge → prioritize `lesson` entries from arsenal
- If the question asks about expertise or technical depth → prioritize `expertise` entries
- If the question asks about a technical or architectural decision → prioritize `decision` entries
- If the question asks about influence, leadership without authority, or mentoring → prioritize `influence` entries
- If the question asks about "what would you do" or vision → prioritize `insight` entries
- Default to `accomplishment` entries for standard behavioral questions

For each relevant arsenal entry:
- Find logged entries that could strengthen the answer
- Identify skills demonstrated but not mentioned
- Note metrics from logs they could have cited

### 9. Deliver Follow-Ups (Based on Depth Config)

Based on `follow_up_depth` in config:

#### If `concise`:
Skip follow-ups. Go directly to feedback.

#### If `detailed`:
Ask the question's `depth: 2` follow-up in the persona's voice. Analyze the follow-up answer.

#### If `coaching`:
Ask `depth: 2` follow-up, analyze, then ask `depth: 3` follow-up. Continue the conversation until the user is satisfied.

### 10. Deliver Feedback

Use the persona's voice and evaluation weights. Reference `references/feedback-rubric.md` for scoring and `references/answer-anti-patterns.md` for anti-pattern detection. Use `references/stage-coaching.md` for stage-specific guidance.

**Feedback format:**

> **[Persona Name]'s Assessment**
>
> | Dimension | Score | Notes |
> |-----------|-------|-------|
> | Specificity | x/5 | <brief note> |
> | Structure | x/5 | <brief note> |
> | Impact | x/5 | <brief note> |
> | Relevance | x/5 | <brief note> |
> | Self-Advocacy | x/5 | <brief note> |
>
> **What worked:** <specific strength in the persona's voice>
>
> **To strengthen:** <specific improvement in the persona's voice>
>
> **From your arsenal:** <reference to logged entries that could enhance the answer, adapted by evidence type — e.g., "Your lesson about X is directly relevant here" or "Your expertise entry on X covers exactly what they're asking about" or "Your decision entry about X demonstrates the tradeoff analysis they want to see">
>
> **Anti-patterns detected:** <any from the question's red_flags or references/answer-anti-patterns.md>

If `coaching` depth, also add:

> **Action items:**
> 1. <specific thing to practice>
> 2. <accomplishment to log that would fill a gap>
> 3. <skill to develop>

### 11. Log the Session

Write a session file at `<things_path>/interview-prep/sessions/<date>-practice-<question-id>.md`:

```markdown
---
type: practice
date: <date>
question_id: <id>
question_category: <category>
question_text: "<text>"
persona: <persona used>
follow_up_depth: <concise|detailed|coaching>
scores:
  specificity: <1-5>
  structure: <1-5>
  impact: <1-5>
  relevance: <1-5>
  self_advocacy: <1-5>
  overall: <average>
anti_patterns_detected:
  - pattern: "<name>"
    example: "<quote from user's answer>"
green_flags_hit:
  - "<flag>"
arsenal_references:
  - file: "<log filename>"
    relevance: "<how it could strengthen the answer>"
skills_tested:
  - "<skill>"
unlogged_accomplishment_hints:
  - "<something the user mentioned that isn't in their logs>"
comparison_to_previous:
  same_question: <null or previous score>
  same_skills: <avg score for these skills across sessions>
---

# Practice Session: <date>

## Question
<question text>

## User's Answer
<summary of their answer>

## Feedback Given
<summary of feedback>

## Arsenal Connections
<which logs were referenced and how>
```

### 12. Update Progress Dashboard

Read and update `<things_path>/interview-prep/progress.md`:
- Update dimension averages with new scores
- Update category breakdown
- Add to recent sessions list
- Recalculate strongest/weakest categories

### 13. Suggest Logging Unlogged Accomplishments

If the user mentioned experiences during their answer that aren't in their arsenal:

> I noticed you mentioned some experiences that aren't logged yet:
> - <experience summary> — this sounds like a <evidence type> entry
>
> These would strengthen your arsenal. Run `/i-did-a-thing:thing-i-did` when you're ready to log them.

### 14. Offer Next Steps

Use AskUserQuestion:

**What next?**
- Practice another question
- Practice the same category again
- Review my progress across sessions
- Done for now

If another question, go back to Step 5.
If review progress, display a summary from `progress.md`.
