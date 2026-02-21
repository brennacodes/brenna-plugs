# Action File Reference

Reference for action types, action file format, and session log format.

## Action Types

| Action | Description |
|--------|-------------|
| `code-review` | Line-by-line code evaluation, style, patterns, correctness |
| `code-smell` | Structural patterns and anti-patterns across files |
| `pair-programming` | Collaborative mode - suggestions framed as exploration |
| `architecture` | System boundaries, dependencies, data flow, evolution |
| `api-design` | Public surface area, naming, consistency, versioning |
| `security-audit` | Vulnerabilities, attack surface, threat modeling |
| `debug` | Hypothesis-driven debugging, root cause analysis |

New action types can be created using the agent-builder (via `/create-profile`).

## Action File Format

Action files are self-contained at `think-like/profiles/<id>/<action>.md`. Each contains everything needed for execution - no other files are read at runtime.

```yaml
---
action: "<action-type>"
profile: "<profile-id>"
person_ref: "shared/people/<id>"
description: "<person's approach to this action>"
created: <YYYY-MM-DD>
---
```

### Required Sections

| Section | Purpose |
|---------|---------|
| Voice | Identity, tone, rhetorical patterns, characteristic phrases |
| Approach | 4-phase execution structure customized for this person |
| Lens | How this person approaches this activity |
| Priorities | What to check, in order of importance |
| Typical Questions | 5-8 questions in their voice |
| Red Flags | Patterns they'd flag as problems |
| Approval Signals | Patterns they'd praise |
| Output Format | How to structure findings |
| Counterpoint | Mandatory blind spots and limitations |

### Execution

The action file is read directly - Claude follows it as instructions. No subagent is launched. The file must be detailed enough to produce a complete review.

## Session Log Format

Sessions are stored at `<home>/.things/think-like/sessions/` with the naming pattern:

```
<YYYY-MM-DD>-<profile-id>-<action>.md
```

If multiple sessions occur on the same day with the same profile and action, append a counter:

```
<YYYY-MM-DD>-<profile-id>-<action>-2.md
```

### Session Frontmatter

```yaml
---
profile: "<profile-id>"
action: "<action-name>"
target: "<file path, directory, or description>"
date: <YYYY-MM-DD>
---
```

### Session Body

```markdown
# <Display Name> - <Action Display Name> Session

## Target
<Description of what was reviewed - file paths, components, etc.>

## Summary
<2-3 sentences capturing the key takeaway from the review>

## Key Issues
- <Issue 1 - severity + brief description>
- <Issue 2>

## Counterpoint Notes
- <Key blind spot observations relevant to this review>
- <Factors that might justify decisions the expert flagged>
```

Sessions are for the user's reference and pattern tracking. They should be concise - the full review output is in the conversation, the session log captures the highlights.
