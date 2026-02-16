# Gap Analysis Model

Reference for classifying knowledge areas and identifying gaps.

## Classification Criteria

### Strong

A skill area is **Strong** when:
- Arsenal has 3+ entries with diverse evidence types (not just accomplishments)
- Learning session scores average ≥ 4.0/5 across dimensions
- Evidence is recent (within last 6 months)
- Can explain mechanism, tradeoffs, and failure modes
- Can connect to personal experience AND general principles

### Building

A skill area is **Building** when:
- Arsenal has 1-3 entries, possibly limited evidence types
- Learning session scores average 2.5-3.9/5
- Some concepts strong, others partial or gap
- Can use it in practice but gaps in explaining why
- Some connections to experience but not systematic

### Gap

A skill area is **Gap** when:
- Arsenal has 0-1 entries despite relevance to goals
- Learning session scores average < 2.5/5 (or no sessions)
- Knows the topic exists but can't go deep
- Limited or no connection to personal experience
- Important for `target_roles` or `aspirational_skills`

### Blind Spot

A skill area is a **Blind Spot** when:
- No arsenal entries AND no learning sessions
- Relevant to `target_roles` based on typical role requirements
- User may not have identified this as a needed skill
- Discovered through cross-referencing role expectations with actual evidence

## Evidence Type Analysis

Diversity of evidence types matters:

| Missing Type | Risk |
|-------------|------|
| No accomplishments | Can you do it at all? |
| No lessons | Do you recognize when it goes wrong? |
| No expertise | Is your understanding surface-level? |
| No decisions | Can you articulate tradeoffs? |
| No influence | Can you advocate for approaches? |
| No insights | Do you see patterns beyond individual instances? |

## Priority Scoring

For the gap report, prioritize actions by:

1. **Blind spots in critical skills** — highest priority, could be career-blocking
2. **Gaps in building_skills** — actively developing but missing knowledge foundation
3. **Gaps in aspirational_skills** — needed for target roles
4. **Building areas with evidence type gaps** — deepening existing knowledge
5. **Strong areas losing recency** — maintenance to prevent skill decay

## Trend Detection

When multiple sessions exist for a topic:

- **Improving**: Average score increasing over last 3+ sessions
- **Stable**: Score within ±0.5 across recent sessions
- **Declining**: Average score decreasing — may indicate false confidence or forgotten concepts
- **Insufficient data**: Fewer than 2 sessions — need more data points
