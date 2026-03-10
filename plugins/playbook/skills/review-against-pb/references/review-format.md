# Review Format Reference

## Frontmatter Schema

Every review in `playbook/reviews/` uses YAML frontmatter:

```yaml
---
title: "Review: <plan> against <branch>"
date: YYYY-MM-DD
description: "Summary of review findings"
doc_type: "review"
plan_ref: "plans/the-plan/v1.md"
branch: "feature/branch-name"
profile_used: "dhh"
status: "all-addressed|has-open-items|in-progress"
actionable_count: N
done_count: N
tags: [tag1, tag2]
---
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Review title (conventionally "Review: <plan> against <branch>") |
| `date` | date | Date the review was conducted |
| `doc_type` | string | Always `"review"` |
| `tags` | string[] | Searchable tags |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Summary of findings |
| `plan_ref` | string | Relative path to the plan being reviewed |
| `branch` | string | Git branch that was reviewed |
| `profile_used` | string | think-like profile ID if reviewed through a profile lens |
| `status` | string | Review status (see below) |
| `actionable_count` | number | Number of remaining actionable items |
| `done_count` | number | Number of completed items |

## Status Values

- **all-addressed**: Every item is done or resolved
- **has-open-items**: Some items remain actionable
- **in-progress**: Items are actively being addressed

## Review Body Structure

```markdown
## Summary

Done: N | Actionable: N

Brief narrative summary of overall progress and key findings.

## Done

### <Item title>
- **Evidence**: <specific file, commit, or code that proves completion>
- **Notes**: <any relevant context>

### <Item title>
...

## Actionable Items

### <Item title>
- **What's needed**: <specific next step>
- **Context**: <relevant context from the plan and review interview>
- **Priority**: <high|medium|low>

### <Item title>
...
```

## Item Classification Rules

During the review, each plan item is classified as one of:

| Classification | Criteria | Appears In |
|---------------|----------|------------|
| **done** | Clear evidence in branch (files changed, tests added, code matches plan) | Done section |
| **actionable** | Not done, but clear what's needed next | Actionable Items section |
| **needs-more-information** | Ambiguous -- requires user input to classify | Temporary -- resolved via interview loop |

The "needs-more-information" classification is temporary. The review skill runs an interview loop to resolve each ambiguous item via AskUserQuestion before writing the final review. The final document contains only "done" and "actionable" items.

## Interview Loop Pattern

For each "needs-more-information" item:

1. Present what's known about the item
2. Ask a targeted question via AskUserQuestion:
   - "I see partial work on <X>. Is this complete, or is there more to do?"
   - "The plan mentions <Y> but I don't see it in the branch. Was this intentionally deferred?"
   - "There's code for <Z> but no tests. Should I mark this as done or actionable?"
3. Reclassify based on the answer
4. Continue until no "needs-more-information" items remain

## think-like Profile Integration

When `as:<profile>` is specified, the review adopts the profile's lens:

- Load the profile's code-review action file from `think-like/profiles/<id>/code-review.md`
- Apply the profile's voice, priorities, and evaluation criteria
- The Done/Actionable structure remains the same, but the assessment reflects the profile's perspective
- The profile name is recorded in `profile_used` frontmatter field

## Filename Convention

Reviews use dated filenames: `<YYYY-MM-DD>-<plan-slug>-review.md`

Multiple reviews of the same plan are distinguished by date.
