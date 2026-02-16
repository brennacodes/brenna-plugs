---
name: gaps
description: "Analyze knowledge gaps across your skills by cross-referencing arsenal evidence, learning sessions, and career goals"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--focus building|aspirational|all]"
---

# Gaps

Cross-reference your career goals, arsenal evidence, and learning session history to identify knowledge gaps, blind spots, and areas of strength. Produces a prioritized gap report with actionable next steps.

## Steps

### 1. Load Configuration

Read `~/.claude/things.local.md` to get `things_path`. If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

Read `<things_path>/config.yml` for all settings. Extract `building_skills`, `aspirational_skills`, `current_role`, `target_roles` from the shared profile.

### 2. Load All Data

Read:
- `<things_path>/index.json` — all log data
- `<things_path>/arsenal/` — all skill evidence files
- `<things_path>/learning/progress.md` — learning dimension scores
- `<things_path>/learning/knowledge-map.md` — current knowledge classifications

Run: `bash <plugin_root>/scripts/search-sessions.sh --recent 50`

Load all learning session history for score data.

If no learning sessions exist:

> No learning sessions found. I'll analyze your arsenal for potential gaps, but your gap analysis will be more accurate after a few explore or quiz sessions.
>
> Try `/what-do-you-know:explore` first to establish baseline knowledge in your key areas.

### 3. Determine Focus

If `--focus` was provided, use it. Otherwise, use AskUserQuestion:

**Which skills should I analyze?**
- Building skills — skills you're actively developing (Recommended)
- Aspirational skills — skills you want to develop next
- All — comprehensive analysis across both

### 4. Analyze Each Skill Area

For each skill in the selected focus set, evaluate across four dimensions:

**Arsenal evidence:**
- How many index entries reference this skill?
- What evidence types are present? (accomplishments only? or also lessons, decisions, expertise, insights?)
- How recent is the evidence?
- How diverse are the projects/contexts?

**Learning session data:**
- How many explore/quiz sessions cover this topic?
- What are the average scores across learning dimensions?
- Are scores trending up, stable, or down?
- What concepts within this skill are strong vs. gap?

**Evidence type diversity:**
- All accomplishments? → You can do it but can you explain it?
- No lessons? → You may not recognize failure patterns
- No decisions? → You may not be able to articulate tradeoffs
- No expertise? → Surface-level understanding risk

**Goal alignment:**
- Is this skill critical for `target_roles`?
- How does it relate to `career_direction`?
- Is it a prerequisite for `aspirational_skills`?

### 5. Classify Each Area

Based on the analysis, classify each skill:

- **Strong** — Multiple diverse evidence types + high learning scores + recent activity. You can explain it, apply it, and teach it.
- **Building** — Some evidence and/or moderate learning scores. You're developing but have clear depth gaps.
- **Gap** — Little evidence despite relevance to goals. You know it exists but can't go deep.
- **Blind Spot** — Relevant to target roles but no evidence AND no learning sessions. You may not realize you need it.

### 6. Present Gap Report

> **Knowledge Gap Analysis**
>
> **Focus:** `<building|aspirational|all>` skills for `<target_roles>`
>
> ### Strong
> | Skill | Evidence | Types | Learning Score | Last Active |
> |-------|----------|-------|---------------|-------------|
> | <skill> | N entries | acc, les, dec | x.x/5 | <date> |
>
> ### Building
> | Skill | Evidence | Missing Types | Learning Score | Priority |
> |-------|----------|--------------|---------------|----------|
> | <skill> | N entries | <missing types> | x.x/5 | <why it matters> |
>
> ### Gap
> | Skill | Evidence | Learning Score | Why It Matters |
> |-------|----------|---------------|----------------|
> | <skill> | N entries | x.x/5 or — | <relation to goals> |
>
> ### Blind Spot
> | Skill | Relevance | Suggested First Step |
> |-------|-----------|---------------------|
> | <skill> | <why needed for target role> | <explore or bridge suggestion> |

### 7. Prioritized Recommendations

Generate a prioritized list of actions:

> **Recommended Actions** (highest impact first)
>
> 1. **[Gap/Blind Spot skill]** — `/what-do-you-know:explore <topic>` to establish baseline understanding
> 2. **[Building skill]** — `/what-do-you-know:quiz --topic <topic>` to test retention and find specific weak spots
> 3. **[Gap skill]** — `/what-do-you-know:bridge <topic> --from <related strong skill>` to build from existing knowledge
> 4. **[Evidence gap]** — `/i-did-a-thing:thing-i-did` to log a `<missing evidence type>` entry for <skill>

### 8. Offer Next Steps

Use AskUserQuestion:

**What would you like to do?**
- Explore a gap topic — deep-dive into an area I'm weak in
- Quiz a building area — test what I'm developing
- Bridge a gap — build a learning plan from existing knowledge
- Done for now — I'll review the report
