# heres-the-thing

Schema-aware data layer for `.things/` - manages setup, git sync, search, validation, and collection registration for all brenna-plugs plugins.

## What it does

heres-the-thing (HTT) is the foundation layer that other plugins build on. It manages the `.things/` directory - a git-tracked data store for career development, expert profiles, and knowledge artifacts.

HTT is **domain-ignorant**: it doesn't know what logs, profiles, or resumes are. It knows about collections, indexes, and file structures. Plugins register their collections with HTT, and HTT provides the infrastructure (git sync, search, validation, rebuild dispatch).

## Skills

| Skill | Description |
|-------|-------------|
| `/setup-htt` | Initialize `.things/` - create directory structure, config, registry, git repo |
| `/register` | Add, update, or remove collection definitions in the registry |
| `/status` | Show collection counts, last-modified dates, git state, tag aggregation |
| `/search-things` | Search across collections by tag, field, text, or find orphaned items |
| `/validate` | Check git health, registry integrity, structural correctness, orphan detection |
| `/sync` | Git push, pull, or status for the `.things/` repository |
| `/migrate` | Migrate shared resources and clean up old layout artifacts. Per-plugin data is handled by each plugin's own migrate command |

## Directory Structure

```
.things/
├── config.json              # Identity + git settings
├── registry.json            # Collection registry
├── .gitignore
└── shared/
    ├── people/{id}/          # Person profiles
    ├── roles/                # Role definitions
    ├── contexts/             # Activity definitions
    └── companies/            # Company profiles
```

Plugins add their own directories (e.g., `think-like/`, `i-did-a-thing/`) and register their collections in `registry.json`.

## Hooks

HTT runs a PostToolUse hook on `Write|Edit` operations. When a file inside `.things/` is written, HTT checks the registry for a matching collection and invokes its `rebuild_command` if one is registered.

## Requirements

- Python 3 (for registry lookup and validation scripts)
- Git (for `.things/` version control)
