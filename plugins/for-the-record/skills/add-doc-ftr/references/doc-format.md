# Document Format Reference

## Frontmatter Schema

Every document in `for-the-record/docs/` uses YAML frontmatter:

```yaml
---
title: "Descriptive title"
date: YYYY-MM-DD
description: "1-2 sentence summary"
detail_level: "concise|detailed"
source_type: "conversation|import|manual"
tags: [tag1, tag2]
related_docs: ["playbook/plans/some-plan.md"]
---
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Descriptive title for the document |
| `date` | date | Date the document was created (YYYY-MM-DD) |
| `tags` | string[] | Searchable tags for discovery |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | 1-2 sentence summary |
| `detail_level` | string | `concise` or `detailed` |
| `source_type` | string | `conversation`, `import`, or `manual` |
| `related_docs` | string[] | Cross-references to other docs in .things/ |

## Document Structures

The structure is auto-chosen based on content type:

### Decision Doc
```
## Context
## Options
## Evaluation
## Decision
## Rationale
```

### Technical Reference
```
## Overview
## Details
## Usage
## Caveats
```

### Discussion Summary
```
## Topic
## Key Points
## Conclusions
## Open Questions
```

### How-To Guide
```
## Goal
## Prerequisites
## Steps
## Verification
```

### Architecture Doc
```
## Overview
## Components
## Data Flow
## Constraints
```

## Filename Convention

Files are named: `<YYYY-MM-DD>-<slugified-topic>.md`

- Date prefix for chronological sorting
- Slugified topic for human readability
- Example: `2026-02-23-things-config-architecture.md`

## Detail Levels

**Concise** (default): Key points, decisions, and outcomes. Compact and scannable. Good for reference docs you'll glance at later.

**Detailed**: Full reasoning chains, code blocks, all alternatives discussed, edge cases, and caveats. Maximum context preservation. Good for complex technical decisions or architecture docs where you need the full picture.

## Tag Conventions

Tags should be consistent with the existing tag vocabulary in `tags.json`. Common patterns:
- Technologies: `rust`, `python`, `claude-code`, `mcp`
- Domains: `architecture`, `security`, `performance`, `testing`
- Activity types: `decision`, `reference`, `how-to`, `discussion`
- Project names: `my-app`, `brenna-plugs`
