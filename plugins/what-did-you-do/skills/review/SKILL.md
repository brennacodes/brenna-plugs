---
name: review
description: "Assess interview readiness across all dimensions with trend analysis, gap identification, and targeted recommendations"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--company amazon|google|meta] [--since YYYY-MM-DD]"
---

# Review Readiness

Analyze all practice and mock sessions to produce a comprehensive readiness assessment with trends, gaps, and specific action items.

## Steps

### 1. Load Configuration

Read `.claude/what-did-you-do.local.md` and `.claude/i-did-a-thing.local.md`. If either is missing, direct to setup.

### 2. Load All Session Data

Read all files in `<things_path>/interview-prep/sessions/`. If the user provided `--since`, filter to sessions after that date. If `--company` is provided, load the company profile for company-specific calibration.

If no sessions exist:

> No practice sessions found. Run `/what-did-you-do:practice` or `/what-did-you-do:mock` first to build data for a readiness review.

Then stop.

### 3. Load Arsenal and Profile

Read `<things_path>/arsenal/` and `<things_path>/targets/profile.md` for context.

### 4. Compute Readiness Assessment

Use the model in `references/readiness-model.md` to compute:

**Dimension Analysis:**
For each of the 5 scoring dimensions (specificity, structure, impact, relevance, self-advocacy):
- Current average (last 5 sessions)
- All-time average
- Trend (improving / stable / declining)
- Weakest question category for this dimension

**Category Analysis:**
For each question category (behavioral, technical, leadership, situational, system-design):
- Average score
- Number of sessions
- Strongest and weakest dimension within this category
- Questions that scored lowest

**Skill Coverage:**
Compare `building_skills` and `aspirational_skills` from profile against skills tested in sessions:
- Skills practiced (with frequency and average scores)
- Skills never practiced
- Skills tested but not in user's goals (may indicate profile needs updating)

**Anti-Pattern Tracking:**
Across all sessions, identify:
- Most frequent anti-patterns
- Anti-patterns that have improved (no longer appearing)
- Persistent anti-patterns (appearing in recent sessions despite earlier coaching)

### 5. Company-Specific Calibration (if applicable)

If `--company` was provided or the user has recent mock sessions for a specific company:

**Values Alignment:**
For each company value, assess how well the user's session scores demonstrate alignment. Map values → question_themes → skills_tested → session scores.

**Level Readiness:**
Compare the user's average scores against the company's `level_expectations` for their target role.

**Stage Readiness:**
For each interview stage in the company's process, assess readiness based on mock sessions for that stage.

### 6. Present the Assessment

> **Interview Readiness Review**
> *Based on [N] sessions from [date range]*
>
> ## Overall Readiness: [Strong / Advancing / Developing / Not Ready]
>
> **Dimension Scores:**
>
> | Dimension | Current Avg | All-Time Avg | Trend | Weakest Category |
> |-----------|------------|-------------|-------|-----------------|
> | Specificity | x/5 | x/5 | ↑/→/↓ | <category> |
> | Structure | x/5 | x/5 | ↑/→/↓ | <category> |
> | Impact | x/5 | x/5 | ↑/→/↓ | <category> |
> | Relevance | x/5 | x/5 | ↑/→/↓ | <category> |
> | Self-Advocacy | x/5 | x/5 | ↑/→/↓ | <category> |
>
> **Strongest Areas:** <top 2-3>
> **Biggest Gaps:** <top 2-3>
>
> **Category Readiness:**
>
> | Category | Avg Score | Sessions | Status |
> |----------|-----------|----------|--------|
> | Behavioral | x/5 | N | Ready/Developing/Gap |
> | Technical | x/5 | N | Ready/Developing/Gap |
> | Leadership | x/5 | N | Ready/Developing/Gap |
> | Situational | x/5 | N | Ready/Developing/Gap |
> | System Design | x/5 | N | Ready/Developing/Gap |
>
> **Persistent Anti-Patterns:**
> - <pattern>: seen in X of last Y sessions. <coaching note>
>
> **Skills Coverage:**
> - Practiced: <list with scores>
> - Never practiced: <list>

If company-specific:

> **[Company] Readiness:**
> - Values coverage: X/Y demonstrated
> - Target level: <level> — [Ready / Close / Gap]
> - Stage readiness: <per-stage assessment>

### 7. Generate Action Plan

> **Recommended Next Steps (priority order):**
>
> 1. **[Highest priority]:** <specific action — e.g., "Practice 3 more leadership questions focusing on structure">
> 2. **[Second priority]:** <specific action>
> 3. **[Third priority]:** <specific action>
>
> **Arsenal Gaps:**
> - <skills that need more logged evidence>
> - Run `/i-did-a-thing:thing-i-did` to log accomplishments in these areas
>
> **Recommended Practice Plan:**
> - This week: <category> questions with <persona> focus
> - Next week: <category> questions, then a full mock
> - Before interview: Full mock for each stage

### 8. Update Progress Dashboard

Write the updated assessment to `<things_path>/interview-prep/progress.md`.

### 9. Offer Next Steps

Use AskUserQuestion:

**What would you like to do?**
- Practice my weakest category
- Run a full mock for [company]
- Drill a specific dimension (specificity, structure, etc.)
- Update my professional profile
- Done for now
