# Plan Format Reference

## Frontmatter Schema

Every plan version in `playbook/plans/<slug>/v<N>.md` uses YAML frontmatter:

```yaml
---
title: "Plan title"
date: YYYY-MM-DD
description: "1-2 sentence summary"
doc_type: "plan"
status: "active|in-progress|completed|superseded|abandoned"
slug: "my-feature-plan"
version: 1
source_plan: "ethereal-mixing-spark.md"
project: "project-name-or-path"
references:
  - "i-did-a-thing/logs/2026-02-20-api-redesign.md"
  - "shared/people/alice.json"
tags: [tag1, tag2]
superseded_by: "new-plan-slug"
---
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Plan title |
| `date` | date | Date the plan was imported/created |
| `doc_type` | string | Always `"plan"` |
| `slug` | string | URL-safe identifier, matches directory name |
| `version` | number | Sequential version number (1, 2, 3...) |
| `tags` | string[] | Searchable tags |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | 1-2 sentence summary |
| `status` | string | Plan lifecycle status (see below) |
| `source_plan` | string | Original Claude plan filename |
| `project` | string | Project name or path |
| `references` | string[] | Paths relative to `~/.things/` linking to other data |
| `superseded_by` | string | Slug of the replacement plan |

## Versioned Directory Structure

Plans are stored in directories named by slug, with sequential version files:

```
playbook/plans/
├── my-feature-plan/
│   ├── v1.md
│   ├── v2.md
│   └── v3.md
└── api-redesign/
    └── v1.md
```

- New imports of the same plan increment the version number
- The rebuild script indexes only the latest version per slug
- All versions are kept for history unless explicitly pruned

## Status Lifecycle

```
active → in-progress → completed
                     → superseded (replaced by another plan)
                     → abandoned (no longer relevant)
```

- **active**: Imported but not yet being worked on
- **in-progress**: Actively being implemented
- **completed**: All items done (confirmed by review)
- **superseded**: Replaced by a newer version (has `superseded_by` field)
- **abandoned**: Dropped, no longer relevant

## References

The `references` field links a plan to other `.things/` data. Paths are relative to `~/.things/`:

- `i-did-a-thing/logs/2026-02-20-api-redesign.md` — related accomplishment
- `shared/people/alice.json` — stakeholder profile
- `heres-the-thing/campaigns/product-launch/campaign.json` — related campaign
- `for-the-record/docs/2026-02-18-auth-architecture.md` — related documentation

## Relationship to Reviews

Reviews reference plans via the `plan_ref` field: `"plans/<slug>/v<N>.md"`.
Multiple reviews can reference the same plan (iterative reviews).
The most recent review reflects current progress.

## Relationship to Claude Plans

Plans are imported from `~/.claude/plans/` via `/capture-plan-pb`. The `source_plan` field preserves the original filename for traceability. The import behavior (copy vs. move) is controlled by preferences.
