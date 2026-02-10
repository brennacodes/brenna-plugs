# Voice Profile Format

Voice profiles are stored as markdown files at `.claude/voices/<name>.md`. Each profile is a compact, actionable style guide distilled from writing samples — not raw samples themselves.

## File Structure

### Frontmatter

```yaml
---
name: casual-tech
description: "Conversational technical writing with humor and first-person anecdotes"
created: 2026-02-09
last_updated: 2026-02-09
sample_sources:
  - type: file
    path: /path/to/original/post.md
  - type: paste
    label: "Medium article about debugging"
  - type: glob
    pattern: "content/blog/*.md"
    count: 12
---
```

**Fields:**
- `name`: Kebab-case identifier, matches the filename
- `description`: One-line summary of the voice — what it sounds like
- `created`: Date the profile was first generated
- `last_updated`: Date of the most recent update
- `sample_sources`: List of where the writing samples came from. Each entry has a `type` (`file`, `paste`, or `glob`) and relevant metadata. This is for reference only — raw samples are not stored.

### Body Sections

Each section should be concise — bullet points preferred, prose only where nuance demands it. The whole profile should fit on one page.

#### Tone & Register

How formal or casual the writing is. The emotional temperature. Where it sits on the spectrum from academic to conversational.

Examples of what to capture:
- Formality level (e.g., "casual but not sloppy — contractions yes, slang rarely")
- Emotional range (e.g., "enthusiastic about solutions, self-deprecating about mistakes")
- Relationship with the reader (e.g., "peer-to-peer, never talks down")

#### Sentence Patterns

The rhythm and structure of sentences. What makes this writer's prose feel distinctive at the sentence level.

Examples of what to capture:
- Average sentence length tendencies (short and punchy vs. complex and layered)
- Opening patterns (e.g., "starts paragraphs with a question or bold claim")
- Use of fragments, em dashes, parentheticals
- Transition style between ideas

#### Vocabulary & Diction

Word choice patterns. The lexical fingerprint.

Examples of what to capture:
- Technical vocabulary level (jargon-heavy vs. plain language)
- Characteristic words or phrases the writer leans on
- How they handle acronyms and technical terms (define inline, assume knowledge, etc.)
- Swearing or colloquial language patterns

#### Rhetorical Habits

Persuasion and explanation patterns. How the writer makes points and builds arguments.

Examples of what to capture:
- Use of analogies, metaphors, or examples
- How they introduce and explain concepts
- Handling of counterarguments or caveats
- Use of humor (type, frequency, placement)

#### Structural Preferences

How the writer organizes content at the macro level.

Examples of what to capture:
- Intro style (jump straight in vs. set the scene)
- Section length preferences
- Use of lists, code blocks, callouts
- Conclusion style (summary, call to action, trailing thought)
- Heading style (descriptive, witty, question-based)

#### Things to Avoid

Patterns that would break the voice. Anti-patterns to steer clear of.

Examples of what to capture:
- Phrases that feel wrong for this voice ("In this blog post, we will...")
- Structural habits to avoid (e.g., "never starts with a dictionary definition")
- Tone missteps (e.g., "never preachy, never uses 'simply' or 'just'")
