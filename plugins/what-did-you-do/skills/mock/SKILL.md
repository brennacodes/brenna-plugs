---
name: mock
description: "Simulate a full interview round with timed questions, persona-consistent follow-ups, and end-of-round assessment"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[company: amazon|google|meta|<custom>] [--stage phone-screen|technical|onsite|bar-raiser|system-design] [--duration 30|45|60]"
---

# Mock Interview

Run a realistic interview round: multiple questions, consistent persona, timed pacing, and a comprehensive debrief at the end.

## Steps

### 1. Load Configuration

Read `.claude/what-did-you-do.local.md` and `.claude/i-did-a-thing.local.md`. If either is missing, direct the user to the appropriate setup.

### 2. Load Arsenal and Session History

Read `<things_path>/arsenal/` and `<things_path>/targets/profile.md`.
Run `bash <plugin_root>/scripts/search-sessions.sh --type mock --recent 5` to load recent mock history.

### 3. Select Company and Stage

If the user provided a company argument, load the company profile from `<plugin_root>/companies/<company>.yaml` or `<things_path>/interview-prep/companies/<company>.yaml` for custom profiles.

If no company specified, use AskUserQuestion:

**Which company are you preparing for?**
- Amazon — LP-driven, bar raiser focus
- Google — technical excellence, Googleyness
- Meta — move fast, impact-driven
- Generic — no company-specific framing
- Custom — I have a company profile set up

If the user provided a `--stage`, use it. Otherwise, if a company was selected, present the company's interview stages. If generic, use AskUserQuestion:

**Which interview stage?**
- Phone Screen (30 min) — 3-4 questions, culture and motivation
- Technical (45 min) — coding and technical discussion
- Onsite Behavioral (45 min) — 4-5 deep behavioral questions
- System Design (45 min) — one end-to-end design problem
- Bar Raiser (60 min) — cross-functional deep dive

### 4. Configure the Round

Based on company profile and stage, determine:
- **Duration**: from `--duration` arg, company profile, or stage default
- **Number of questions**: from `references/mock-formats.md`
- **Persona**: from company profile's `persona` field for this stage, or select appropriate persona
- **Evaluation focus**: from company profile or stage defaults
- **Question categories**: from company values → question_themes mapping

Load the selected persona from `<plugin_root>/personas/<persona>.md`.

### 5. Brief the User

> **Mock Interview: [Company] — [Stage]**
>
> Duration: ~[X] minutes
> Questions: [N]
> Interviewer: [Persona Role]
> Focus: [evaluation areas]
>
> I'll ask questions one at a time. Answer as you would in a real interview. I'll hold all feedback until the debrief at the end.
>
> Ready?

Wait for confirmation.

### 6. Conduct the Round

For each question in the round:

1. Select a question using the same spaced repetition algorithm as the practice skill, but filtered by the company's `question_themes` and stage's `evaluation_focus`
2. Ask the question in the persona's voice
3. Receive the answer
4. If the question has relevant `depth: 2` follow-ups and time permits, ask ONE follow-up in persona voice
5. Silently score the answer (do NOT share scores yet)
6. Track time spent per question (use `references/timing-guide.md`)
7. Transition to next question naturally in persona voice

**Between questions**, use persona-appropriate transitions:
- Staff Engineer: "Good. Let me shift gears..."
- Engineering Manager: "Thank you for sharing that. I'd like to explore..."
- Bar Raiser: "Interesting. Here's a different angle..."

Do NOT provide feedback between questions. Save it all for the debrief.

### 7. End-of-Round Debrief

After all questions, break character and deliver a comprehensive assessment:

> **Mock Interview Debrief**
>
> **Overall Assessment: [Strong / Advancing / Developing / Not Ready]**
>
> **Dimension Scores:**
>
> | Dimension | Avg Score | Strongest Answer | Weakest Answer |
> |-----------|-----------|-----------------|----------------|
> | Specificity | x/5 | Q<n> | Q<n> |
> | Structure | x/5 | Q<n> | Q<n> |
> | Impact | x/5 | Q<n> | Q<n> |
> | Relevance | x/5 | Q<n> | Q<n> |
> | Self-Advocacy | x/5 | Q<n> | Q<n> |

If company-specific, add:

> **[Company] Alignment:**
> - Values demonstrated: <list>
> - Values missing: <list>
> - Level calibration: <assessment vs target level>

Then per-question breakdown:

> **Q1: "<question>"**
> Score: x/5 | Strengths: <brief> | To improve: <brief>
> Arsenal suggestion: <relevant log>

Finally:

> **Top 3 Action Items:**
> 1. <most impactful improvement>
> 2. <next priority>
> 3. <third priority>

### 8. Log the Session

Write session file at `<things_path>/interview-prep/sessions/<date>-mock-<company>-<stage>.md` with full frontmatter including all per-question scores, company alignment, and overall assessment.

### 9. Update Progress Dashboard

Update `<things_path>/interview-prep/progress.md` with new scores and session entry.

### 10. Suggest Unlogged Accomplishments

If the user mentioned experiences not in their arsenal during the mock:

> During the mock, you referenced some experiences I don't see in your logs:
> - <experience>
>
> Logging these would strengthen your arsenal. Run `/i-did-a-thing:thing-i-did` when ready.

### 11. Offer Next Steps

Use AskUserQuestion:

**What next?**
- Run another mock round (same company, different stage)
- Drill specific questions that were weak
- Review progress across all mocks
- Prep for a specific company (`/what-did-you-do:prep-for`)
- Done for now
