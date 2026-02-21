# Debug - Context Template

Defines the structure and execution phases for debugging action files. Builder agents use this template when constructing person-specific debug actions.

## Phases

### Phase 1: Orientation (Internal)
- Understand the symptom - what's going wrong, when does it happen, what's expected vs actual
- Map the code path involved - entry point through to the failure point
- Identify the technology stack and its common failure modes
- Gather context - error messages, logs, reproduction steps, recent changes

### Phase 2: Analysis (Internal)
- Form hypotheses based on the symptom and the profile's debugging philosophy
- For each hypothesis:
  - What would be true if this hypothesis were correct?
  - What evidence would confirm or reject it?
  - Where in the code would that evidence live?
- Gather evidence - read code, trace execution paths, check configurations
- Narrow hypotheses based on evidence
- Identify the root cause (not just the proximate cause)

### Phase 3: Findings (Output)

Structure findings as:

**Diagnosis**: 2-3 sentences - what's wrong and why, in the profile's voice.

**Root Cause**: The fundamental issue, with evidence trail:
- Symptom → proximate cause → root cause chain
- File paths and line references
- Why this caused the observed behavior

**Evidence Trail**: How the root cause was identified:
- What hypotheses were considered
- What evidence confirmed/rejected each
- The reasoning chain

**Fix**: Concrete, specific fix:
- What to change and where
- Why this addresses the root cause (not just the symptom)
- What to test to verify the fix

**Prevention**: How to prevent this class of bug:
- What systemic issue allowed this bug?
- What would catch it earlier next time?

### Phase 4: Counterpoint (Mandatory - Never Skip)
- Surface the profile's debugging blind spots
- Consider whether the diagnosis might be incomplete
- Note alternative explanations that weren't fully explored
- Suggest what a different debugging approach might uncover

## Output Format

Use markdown. Include code references and reasoning chains. The reader should be able to follow the investigation from symptom to fix.

## Scope Rules

- **Specific error**: Focus on diagnosing that error
- **Behavioral bug**: Trace the expected vs actual behavior through the code
- **Performance issue**: Profile the hot path, identify bottlenecks
- **Intermittent bug**: Focus on state-dependent conditions, race conditions, timing
