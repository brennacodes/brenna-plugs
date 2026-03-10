# for-the-record

Capture structured documentation from Claude conversations -- decisions, technical references, discussion summaries, how-to guides, and architecture docs with auto-tagging and full-text search. Plus verbatim discussion capture for when you need the full back-and-forth preserved exactly.

Stop manually telling Claude "capture this as a markdown document." The plugin extracts context from your conversation, auto-selects the right document structure, generates tags for discoverability, and writes everything to your `.things/` directory where it's indexed and searchable across all plugins.

## Installation

```
/plugin install for-the-record@brenna-plugs
```

## Setup

Requires things (`/things:setup-things`). Configures documentation preferences.

```
/setup-ftr
```

To reconfigure:

```
/setup-ftr reconfigure
```

## Skills

**Add Document** - Capture a document from conversation context. Gathers relevant context from the current conversation, auto-selects the best document structure (decision doc, technical reference, discussion summary, how-to guide, or architecture doc), generates tags from content and existing tag vocabulary, and writes a frontmatter-enhanced markdown file. Use `--detailed` for maximum context preservation or `--tags` to specify tags explicitly.

```
/add-doc-ftr <topic> [--detailed] [--tags tag1,tag2]
```

**Capture Discussion** - Capture a verbatim discussion exactly as provided. No summarization, no rewording, no omission -- every word is preserved. Use when you need the full back-and-forth, not a structured summary. Paste content directly or read from a file.

```
/capture-discussion [--from-file <path>] [--title <title>] [--tags tag1,tag2]
```

**Prune Discussions** - Delete old discussions based on configured retention, explicit age threshold, or interactive selection. Always confirms before deleting.

```
/prune-discussions [--older-than <days>] [--interactive]
```

**Import** - Import existing documentation files from any directory you specify. Scans for markdown files, shows a numbered list for selection, generates frontmatter (title, date, tags) for files that don't have it, and copies them into `for-the-record/docs/`.

```
/import-ftr [<path>] [--dry-run]
```

## Document Structures

| Content Pattern | Structure |
|----------------|-----------|
| Weighed options, chose an approach | Decision Doc |
| Explained a system, API, or tool | Technical Reference |
| Discussed a topic, reached conclusions | Discussion Summary |
| Walked through steps to accomplish something | How-To Guide |
| Designed a system or component | Architecture Doc |

## How It Works

Each document is stored as a markdown file with YAML frontmatter in `~/.things/for-the-record/docs/`. Verbatim discussions go in `~/.things/for-the-record/discussions/`. The plugin auto-selects the document structure based on content and generates tags for cross-plugin discoverability.

The plugin maintains:

- **index.json** - Master index of all documents and discussions with metadata and `by_type` counts
- **tags.json** - Tag counts and last-used dates
- **Auto-tagging** - Cross-references existing tag vocabulary for consistency

## Directory Structure

```
~/.things/
├── config.json
├── registry.json
└── for-the-record/
    ├── preferences.json
    ├── docs/
    │   ├── 2026-02-23-things-config-architecture.md
    │   ├── 2026-02-20-my-app-prompt-routing.md
    │   └── ...
    ├── discussions/
    │   ├── 2026-02-23-api-design-debate.md
    │   └── ...
    ├── index.json
    └── tags.json
```

The things plugin's PostToolUse hook automatically rebuilds `index.json` and `tags.json` after every document write via the registry rebuild dispatch.

## Configuration

- Global config: `~/.things/config.json` (managed by things)
- Plugin preferences: `~/.things/for-the-record/preferences.json`

Run `/setup-ftr` to reconfigure.

## Related Plugins

- **things** - Foundation data layer that manages `.things/`, git sync, search, validation, and rebuild dispatch
- **playbook** - Orchestrate plans, workflows, implementation tracking, and reviews
- **i-did-a-thing** - Log professional experiences and build resumes
- **mark-my-words** - Write and publish blog posts
