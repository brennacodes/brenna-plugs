# things

Schema-aware data layer for `.things/` - manages setup, git sync, search, validation, collection registration, and central tag indexing for all brenna-plugs plugins.

## What it does

things is the foundation layer that other plugins build on. It manages the `.things/` directory - a git-tracked data store for career development, expert profiles, and knowledge artifacts.

things is **domain-ignorant**: it doesn't know what logs, profiles, or resumes are. It knows about collections, indexes, tags, and file structures. Plugins register their collections with things, and things provides the infrastructure (git sync, search, validation, rebuild dispatch, tag aggregation).

## Skills

| Skill | Description |
|-------|-------------|
| `/things:setup` | Initialize `.things/` - create directory structure, config, registry, git repo |
| `/things:register` | Add, update, or remove collection definitions in the registry |
| `/things:status` | Show collection counts, last-modified dates, git state, tag aggregation |
| `/things:search` | Search across collections by tag, field, text, or find orphaned items |
| `/things:validate` | Check git health, registry integrity, structural correctness, orphan detection |
| `/things:sync` | Git push, pull, or status for the `.things/` repository |
| `/things:migrate` | Migrate shared resources and clean up old layout artifacts. Per-plugin data is handled by each plugin's own migrate command |

## Directory Structure

```
.things/
├── config.json              # Identity + git settings
├── registry.json            # Collection registry
├── tags/
│   └── index.json           # Central tag index (aggregated from all collections)
├── .gitignore
└── shared/
    ├── people/{id}/          # Person profiles
    ├── roles/                # Role definitions
    ├── contexts/             # Activity definitions
    └── companies/            # Company profiles
```

Plugins add their own directories (e.g., `think-like/`, `i-did-a-thing/`) and register their collections in `registry.json`.

## Tags

Collections can declare `tags_field` in their registry definition. The central tag index at `tags/index.json` aggregates tags across all registered collections, enabling cross-plugin tag search via `/things:search --tag <tag>`.

## Hooks

things runs a PostToolUse hook on `Write|Edit` operations. When a file inside `.things/` is written, things checks the registry for a matching collection and invokes its `rebuild_command` if one is registered. It also triggers a central tag index rebuild if the collection declares `tags_field`.

## Requirements

- Python 3 (for registry lookup, validation, and tag rebuild scripts)
- Git (for `.things/` version control)
