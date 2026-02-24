# Discussion Format Reference

## Frontmatter Schema

Every discussion in `for-the-record/discussions/` uses minimal YAML frontmatter:

```yaml
---
title: "Descriptive title"
date: YYYY-MM-DD
doc_type: "discussion"
tags: [tag1, tag2]
source_type: "conversation|import"
---
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Brief descriptive title for the discussion |
| `date` | date | Date the discussion was captured (YYYY-MM-DD) |
| `doc_type` | string | Always `"discussion"` |
| `tags` | string[] | Searchable tags for discovery |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `source_type` | string | `conversation` (pasted) or `import` (from file) |

## Body Content

The body is **verbatim, unmodified content**. Unlike `/add-doc` documents which are structured into sections, discussion files preserve the exact text as provided -- no summarization, rewording, restructuring, or omission.

## Filename Convention

Files are named: `<YYYY-MM-DD>-<slugified-title>.md`

- Date prefix for chronological sorting
- Slugified title for human readability
- Example: `2026-02-23-api-design-debate.md`

## Tag Conventions

Tags follow the same conventions as `for-the-record/docs/`. Cross-reference `tags.json` and `~/.things/tags/index.json` for vocabulary consistency.

## Retention

Discussions can be auto-pruned based on the `discussion_retention_days` preference. Use `/prune-discussions` to manage retention manually.
