# PR Review - Context Template

Defines the structure and execution phases for PR review action files. Builder agents use this template when constructing person-specific PR review actions.

## Phases

### Phase 1: Orientation (Internal)
- Read the full changeset — understand every file touched
- Identify the PR's intent — what problem is being solved and how
- Map the scope — how many files, which areas of the codebase, what's the blast radius
- Note the PR metadata — title, description, linked issues, size

### Phase 2: Analysis (Internal)
- Evaluate whether the approach fits the problem
- Assess the scope — is it too broad, too narrow, or well-scoped?
- Check for risk — breaking changes, migration concerns, data integrity, rollback difficulty
- Evaluate completeness — are there missing pieces (tests, docs, edge cases)?
- Consider the change in context — how does it fit with the codebase's direction?

### Phase 3: Findings (Output)

Structure findings as:

**Overall Assessment**: 2-3 sentences on the PR as a whole — does the approach make sense for the problem?

**Approach**: Is this the right way to solve the problem? Are there simpler alternatives? Does the scope match the goal?

**Risk Assessment**: What could go wrong? Breaking changes, performance implications, data concerns, deployment risks.

**Completeness**: What's missing? Tests, documentation, error handling, edge cases, migration steps.

**Observations**: Patterns noticed, questions about intent, suggestions for improvement.

**What's Good**: What the PR does well — clear commit messages, good test coverage, clean scope.

### Phase 4: Counterpoint (Mandatory - Never Skip)
- Surface the profile's documented blind spots
- Apply them specifically to THIS PR (not generic disclaimers)
- Suggest what a reviewer with different priorities might see
- Frame as genuine balance, not a disclaimer

## Output Format

Use markdown. Findings should be scannable — headers, bullet points, and file references. The voice should be consistent throughout. Focus on the changeset as a whole, not individual lines.

## Scope Rules

- **Single PR**: Full holistic assessment — approach, scope, risk, completeness
- **PR series**: Evaluate how this PR fits in the sequence — dependencies, ordering, incremental value
- **Draft PR**: Focus on approach and direction, not polish
- **No target specified**: Ask which PR to review before proceeding
