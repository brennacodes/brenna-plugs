# Code Review - Context Template

Defines the structure and execution phases for code review action files. Builder agents use this template when constructing person-specific code review actions.

## Phases

### Phase 1: Orientation (Internal)
- Read target files completely before forming opinions
- Identify the technology stack, patterns in use, and project conventions
- Note the scope - are we reviewing a PR, a file, a directory, a module?
- Understand what the code is trying to do before evaluating how it does it

### Phase 2: Analysis (Internal)
- Apply the profile's priorities in order
- Check each priority against the target code systematically
- Track specific findings with file paths and line references
- Note both issues and things done well

### Phase 3: Findings (Output)

Structure findings as:

**Opening**: 2-3 sentences setting the overall impression in the profile's voice and tone.

**Key Issues**: Each issue should include:
- What: the specific problem
- Where: file path and line reference
- Why: connect to a priority or red flag from the profile
- How: concrete suggestion for improvement

**Observations**: Less critical notes - patterns noticed, style preferences, questions about intent.

**What's Good**: Specific things done well, connected to the profile's approval signals.

### Phase 4: Counterpoint (Mandatory - Never Skip)
- Surface the profile's documented blind spots
- Apply them specifically to THIS review (not generic disclaimers)
- Suggest what a reviewer with different priorities might see
- Frame as genuine balance, not a disclaimer

## Output Format

Use markdown. Findings should be scannable - use headers, bullet points, and code references. The voice should be consistent throughout - the reader should feel like they're getting a review from a specific person, not a generic tool.

## Scope Rules

- **Single file**: Deep dive, line-level detail
- **Directory/module**: Focus on patterns across files, architecture within the module
- **PR/changeset**: Evaluate the change as a whole - intent, approach, risk
- **No target specified**: Ask what to review before proceeding

## Variants

- `code-review`: Standard line-level evaluation with actionable feedback
- `code-smell`: Focus on structural patterns across files - name the smells, identify the pressure causing them, suggest refactoring directions
- `pair-programming`: Collaborative tone - "What if we tried..." instead of "This is wrong." Think out loud, show reasoning, explore alternatives together
