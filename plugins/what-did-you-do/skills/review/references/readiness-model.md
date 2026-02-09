# Readiness Model

Framework for computing interview readiness from session data.

## Overall Readiness Levels

| Level | Criteria |
|-------|----------|
| **Strong** | All dimensions avg ≥ 4.0, no category below 3.5, ≥ 10 sessions, no persistent anti-patterns |
| **Advancing** | Most dimensions avg ≥ 3.5, no category below 2.5, ≥ 5 sessions, improving trend |
| **Developing** | Some dimensions avg ≥ 3.0, active improvement on weak areas, ≥ 3 sessions |
| **Not Ready** | Multiple dimensions below 3.0, fewer than 3 sessions, or persistent anti-patterns without improvement |

## Trend Calculation

Trend is based on the last 5 sessions compared to the 5 before that (or all prior sessions if fewer than 10 total):

- **Improving (↑):** Current average is ≥ 0.5 higher than previous period
- **Stable (→):** Difference is less than 0.5 in either direction
- **Declining (↓):** Current average is ≥ 0.5 lower than previous period

If fewer than 5 sessions exist, trend is "insufficient data."

## Dimension Scoring

Each session produces 5 dimension scores (1-5). The readiness model uses:

- **Current average:** Mean of last 5 sessions
- **All-time average:** Mean of all sessions
- **Weighted average:** More recent sessions count more: `weight = 1 + (0.1 * recency_rank)` where most recent = highest rank

## Category Assessment

| Status | Criteria |
|--------|----------|
| **Ready** | Avg ≥ 4.0 across ≥ 3 sessions in this category |
| **Developing** | Avg ≥ 3.0 OR fewer than 3 sessions but showing improvement |
| **Gap** | Avg < 3.0 OR zero sessions in this category |

## Anti-Pattern Persistence

An anti-pattern is "persistent" if:
- Detected in ≥ 3 sessions total AND
- Detected in ≥ 1 of the last 3 sessions

An anti-pattern is "improving" if:
- Detected in ≥ 3 sessions total AND
- NOT detected in any of the last 3 sessions

## Skill Coverage Score

For each skill in `building_skills` and `aspirational_skills`:

- **Well-covered:** Tested in ≥ 3 sessions with avg score ≥ 3.5
- **Partially covered:** Tested in 1-2 sessions OR avg score < 3.5
- **Uncovered:** Never tested

Overall coverage score = well-covered / total target skills.

## Company-Specific Readiness

When assessing readiness for a specific company:

1. Map company values → question_themes → skills_tested
2. For each value, compute average score across sessions that tested related skills
3. A value is "demonstrated" if the average related skill score is ≥ 3.5
4. Values coverage = demonstrated values / total values

Level readiness is assessed by comparing:
- Scope of accomplishments described in sessions vs level expectations
- Dimension scores vs level-appropriate thresholds (higher levels need higher scores)
- Leadership evidence for staff+ levels

## Minimum Session Thresholds

| Assessment Type | Minimum Sessions | Minimum for Confidence |
|-----------------|-----------------|----------------------|
| Overall readiness | 3 | 10 |
| Category readiness | 2 | 5 |
| Dimension trend | 5 | 10 |
| Company readiness | 3 (including ≥1 mock) | 8 (including ≥2 mocks) |
