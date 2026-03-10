# playbook

Orchestrate plans, workflows, implementation tracking, and reviews -- import plans from Claude sessions, create XML-enhanced workflows, review implementations against plans, resume work where you left off, and track progress across everything.

Plans sit in `~/.claude/plans/` after Claude Code plan mode. This plugin brings them into your `.things/` data layer where they're indexed, searchable, and trackable. Import a plan, review your branch against it, resume implementation from where you left off, create structured workflows, and track progress with a dashboard. Plans are versioned -- reimporting creates a new version rather than overwriting.

## Installation

```
/plugin install playbook@brenna-plugs
```

## Setup

Requires things (`/things:setup-things`). Configures workflow targets, import behavior, and review defaults.

```
/setup-pb
```

To reconfigure:

```
/setup-pb reconfigure
```

## Skills

| Skill | Description |
|-------|-------------|
| [capture-plan](#capture-plan) | Import plans from `~/.claude/plans/` into playbook. |
| [create-workflow](#create-workflow) | Create a workflow file optimized for Claude use. |
| [review-against-plan](#review-against-plan) | Review current branch work against what was planned. |
| [resume-plan](#resume-plan) | Resume work on a plan that was previously suspended. |
| [implement-items](#implement-items) | Implement specific actionable items from a review. |
| [update-plan](#update-plan) | Evolve a plan over time. |
| [progress-dashboard](#progress-dashboard) | Show progress for a specific plan or all active plans. |
| [import-plans](#import-plans) | Import Claude plan documents from `~/.claude/plans/` into playbook in bulk. |
| [prune-plans](#prune-plans) | Delete old plan versions or entire plans based on retention preferences, explicit age, or interactive selection. |

### **Capture Plan**

```
/capture-plan <thing> [--status active] [--project <name>] [--references path1,path2]
```

Import a plan from `~/.claude/plans/` into playbook with versioning, references, and status tracking. Searches available plans by content, generates a title, tags, and status, and writes to a versioned directory `playbook/plans/<slug>/v<N>.md`. Plans can link to other `.things/` data via references.

### **Create Workflow**

```
/create-workflow <scope> [--target <path>] [--update <existing>] [--embed-in <file>]
```

Create or update an XML-enhanced workflow file. Structured steps with gates, prerequisites, verification commands, and principles. Writes an archive copy to `.things/` and optionally a working copy to the project's `.claude/workflows/` directory. Can reference from CLAUDE.md or embed directly into a SKILL.md.

### **Review Against Plan**

```
/review-against <plan> [as:<profile-name>] [--branch <name>]
```

Review current branch work against a plan. Compares plan items against branch changes, classifies each as done or actionable, resolves ambiguity through targeted questions, and writes a structured review. Optionally apply a think-like profile lens (e.g., `as:dhh`) for expert-perspective reviews.

### **Resume Plan**

```
/resume-plan <plan>
```

Resume implementing a plan from where you left off. Reads the plan, latest review, and current branch state. Shows what's done vs. what's next, then starts working on the next actionable item.

### **Implement Items**

```
/implement <item-or-review>
```

Implement specific actionable items from a review. Shows remaining items as a numbered list, lets you pick which to implement, does the work, and marks them as resolved in the review document.

### **Update Plan**

```
/update <plan> [--status <status>] [--notes]
```

Evolve a plan over time. Update status (active, in-progress, completed, superseded, abandoned), append dated implementation notes, rewrite sections based on new information, or supersede with a new version.

### **Progress Dashboard**

```
/progress [plan]
```

Show progress for a specific plan or all active plans. Displays done/actionable counts, progress bars, latest review dates, and branch status. Offers quick actions to resume implementation or run a review.

### **Import Plans**

```
/import-pb [--dry-run]
```

Import Claude plan documents from `~/.claude/plans/` into playbook in bulk. Discovers plans, displays them with titles, descriptions, and scope estimates, marks which ones are already imported, and lets you pick and choose. Imports with proper frontmatter, versioning, and status tracking.

### **Prune Plans**

```
/prune-plans [--older-than <days>] [--interactive]
```

Delete old plan versions or entire plans based on retention preferences, explicit age, or interactive selection. Age-based modes keep the latest version per plan. Interactive mode allows fine-grained control.

## Workflow Format

Workflows use XML-enhanced markdown with structured steps:

- `<step>` with `<title>`, `<goal>`, `<instructions>`, `<gate>`
- `<prerequisite ref="">` for step dependencies
- `<command>` with `<expected>` for verification
- `<on_fail goto="">` for gate failure loops
- `<principles>` for guiding philosophy
- `<verification-commands>` for quick-reference command lists

## How It Works

Plans, workflows, and reviews are stored as markdown files with YAML frontmatter in `~/.things/playbook/`. Plans use a versioned directory structure (`plans/<slug>/v1.md, v2.md, ...`). A unified index tracks all three types with a `doc_type` field, indexing only the latest version of each plan.

The plugin maintains:

- **Unified index.json** - All plans, workflows, and reviews with type-specific metadata
- **tags.json** - Tag counts across all document types
- **Status tracking** - Plans progress through active -> in-progress -> completed
- **Review chain** - Multiple reviews per plan, tracking implementation progress over time
- **Plan versioning** - Reimporting creates new versions; old versions kept for history
- **References** - Plans can link to other `.things/` data (logs, people, campaigns, docs)

## Directory Structure

```
~/.things/
├── config.json
├── registry.json
└── playbook/
    ├── preferences.json
    ├── plans/
    │   ├── my-feature-plan/
    │   │   ├── v1.md
    │   │   └── v2.md
    │   └── api-redesign/
    │       └── v1.md
    ├── workflows/
    │   ├── development-workflow.md
    │   └── ...
    ├── reviews/
    │   ├── 2026-02-23-my-feature-plan-review.md
    │   └── ...
    ├── index.json
    └── tags.json
```

The things plugin's PostToolUse hook automatically rebuilds `index.json` and `tags.json` after every write via the registry rebuild dispatch.

## Configuration

- Global config: `~/.things/config.json` (managed by things)
- Plugin preferences: `~/.things/playbook/preferences.json`

Run `/setup-pb` to reconfigure.

## Related Plugins

- **things** - Foundation data layer that manages `.things/`, git sync, search, validation, and rebuild dispatch
- **for-the-record** - Capture structured documentation from conversations
- **think-like** - Expert thinking profiles used by `/review-against as:<profile>`
- **i-did-a-thing** - Log professional experiences (completed plan items make great log entries)
