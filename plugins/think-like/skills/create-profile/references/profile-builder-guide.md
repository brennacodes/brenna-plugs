# Profile Builder Guide

Templates and schemas for think-like profile files. Use these when building new profiles.

## Person Profile (`shared/people/<id>/profile.md`)

```markdown
---
display_name: "<Full Name>"
full_name: "<Full Name if different from display>"
domain: "<primary technical domain>"
associations: ["<key projects, companies, frameworks>"]
created: <YYYY-MM-DD>
---

# <Display Name>

## Identity

2-3 sentences. Who they are, why they matter in tech. Be specific - not "influential developer" but "creator of Rails, CTO of 37signals, vocal advocate for the majestic monolith and convention over configuration."

## Philosophy

3-5 core technical beliefs. Each must be specific enough to predict their reaction to a code pattern.

- **<Belief label>**: <Complete sentence explaining the stance. Not "values simplicity" but "believes most abstractions are premature and that three similar lines of code are better than a DRY abstraction you'll need to understand.">
- ...

## Communication Style

How they express opinions, give feedback, argue positions.

- **Tone**: <direct/diplomatic, provocative/measured, etc.>
- **Rhetorical patterns**: <How they structure arguments - e.g., "leads with what's wrong, shows the simpler alternative, doesn't hedge">
- **Characteristic phrases**: <Actual phrases or framings they use>
- **Handling disagreement**: <How they engage with pushback>
```

## Person Index (`shared/people/<id>/index.json`)

```json
{
  "id": "<id>",
  "display_name": "<name>",
  "full_name": "<full name>",
  "domain": "<primary domain>",
  "associations": ["<project>", "<company>"],
  "type": "person",
  "speculative": false,
  "created": "<YYYY-MM-DD>",
  "referenced_by": ["think-like"]
}
```

Set `speculative: true` if sources were thin and positions were inferred rather than documented.

## Action File (`think-like/profiles/<id>/<action>.md`)

Action files are self-contained - reading ONLY this file gives complete instructions for execution. No other files are read at runtime.

```markdown
---
action: "<action-type>"
profile: "<profile-id>"
person_ref: "shared/people/<id>"
description: "<person's approach to this action>"
created: <YYYY-MM-DD>
---

# <Display Name> - <Action Display Name>

## Voice

Identity, tone, rhetorical patterns, characteristic phrases. How this person communicates their feedback.

- **Identity**: <Who they are in 1-2 sentences>
- **Tone**: <direct/diplomatic, provocative/measured, etc.>
- **Rhetorical patterns**: <How they structure arguments>
- **Characteristic phrases**: <Actual phrases or framings they use>

## Approach

The 4-phase execution structure customized for this person:

1. **Orientation**: <How they start - what they look at first>
2. **Analysis**: <Their systematic review method>
3. **Synthesis**: <How they organize and prioritize findings>
4. **Counterpoint**: <How they surface their own blind spots>

## Lens

2-3 sentences. How this person specifically approaches this activity. Not "reviews for quality" but "starts with convention adherence, then hunts for unnecessary abstraction layers, finishes by checking if the code could be deleted entirely."

## Priorities

Ordered by importance. 4-6 items, specific to this person's philosophy.

1. **<Priority>**: <Why this matters to them>
2. ...

## Typical Questions

5-8 questions they would actually ask. These should sound like the person.

- "<Question in their voice?>"
- ...

## Red Flags

5-8 patterns they would flag as problems. Specific to their philosophy.

- **<Pattern name>**: <What it looks like and why they'd flag it>
- ...

## Approval Signals

3-5 things they would praise or approve of.

- **<Signal>**: <What this looks like in code>
- ...

## Output Format

How to structure the review findings:

- **Overall structure**: <How to organize the output>
- **Issue format**: <How to present each finding>
- **Severity levels**: <If applicable, how to communicate severity>
- **Examples**: <Whether to show code examples, alternatives>

## Counterpoint

Mandatory blind spots and limitations. 2-3 substantive weaknesses of this perspective.

- **<Blind spot>**: <Specific scenario where this perspective leads to worse outcomes>
- ...

**Framing**: A paragraph explaining how to constructively surface these blind spots after delivering the review. This guides the mandatory counterpoint phase.
```

## Profile Index (`think-like/profiles/<id>/index.json`)

```json
{
  "id": "<id>",
  "display_name": "<name>",
  "person_ref": "shared/people/<id>",
  "actions": [
    {
      "name": "<action-name>",
      "file": "<action-name>.md",
      "description": "<one-line description>"
    }
  ],
  "tags": ["<tag1>", "<tag2>"],
  "created": "<YYYY-MM-DD>",
  "last_used": null
}
```

## Quality Checklist

Before saving any profile, verify:

- [ ] Philosophy stances are specific enough to produce distinct output (not "values clean code")
- [ ] Communication style has enough detail to shape tone (not just "direct")
- [ ] Action file is self-contained - reading ONLY this file gives complete instructions for execution
- [ ] Voice section captures identity, tone, rhetorical patterns, and characteristic phrases
- [ ] Approach section defines all 4 phases clearly
- [ ] Typical questions sound like the person (not generic review questions)
- [ ] Red flags connect to specific philosophical stances
- [ ] Output format is specific and actionable
- [ ] Blind spots are substantive (not "may miss some edge cases")
- [ ] Counterpoint framing is genuine and actionable
- [ ] No personal information - public professional opinions only
- [ ] `speculative` flag is set where sources are thin

## Action Types

| Action | Focus |
|--------|-------|
| `code-review` | Line-by-line code evaluation |
| `architecture` | System design and structure |
| `security-audit` | Security-focused analysis |
| `code-smell` | Pattern and anti-pattern detection |
| `api-design` | API surface evaluation |
| `pair-programming` | Collaborative coding guidance |
| `debug` | Hypothesis-driven debugging, root cause analysis |
