# claude-scout

Track filesystem changes in `~/.claude/` and other directories using git-based snapshots, changelog parsing, diff queries, and plugin dependency health checks.

## Why

Claude Code's `~/.claude/` directory changes silently with every update. New files appear, structures shift, paths rename. Plugins that depend on specific paths break with no warning. claude-scout gives you visibility into what changed and whether your plugins are affected.

## Skills

| Skill | Description |
|-------|-------------|
| `/setup-cs` | Initialize a tracking target — configure path, set up git snapshots, detect changelogs |
| `/cs-snapshot` | Capture current state as a git commit on the tracking branch |
| `/diff-cs` | Show changes between snapshots — filter by time, path, or change type |
| `/whats-new-cs` | Human-friendly change summary with changelog correlation |
| `/cs-changelog` | Parse and query changelog files — filter by version, type, or keyword |
| `/cs-dep-doctor` | Plugin health check — scan dependencies and cross-reference with changes |

## Setup

```
/setup-cs
```

Walks you through configuring a target directory (defaults to `~/.claude/`), initializes git tracking on an orphan branch, and takes a baseline snapshot.

## Usage

Take a snapshot after a Claude Code update:

```
/cs-snapshot --message "post-update"
```

See what changed:

```
/whats-new-cs
/diff-cs --since "1 week ago"
```

Check if plugins are affected:

```
/cs-dep-doctor
```

Query the changelog:

```
/cs-changelog --latest 3
/cs-changelog --search "plugin" --type added
```

## Data Model

All data lives in `~/.things/claude-scout/`:

- `preferences.json` — auto_snapshot, default_diff_output, default_target
- `targets.json` — configured tracking targets
- `index.json` — master index
- `snapshots/<target>/snapshot-log.json` — snapshot history
- `changelogs/<target>/parsed.json` — cached parsed changelog entries
- `deps/<target>/dep-map.json` — plugin dependency map

## Scripts

| Script | Purpose |
|--------|---------|
| `snapshot.sh` | Git init, snapshot, status, diff-stat (JSON output) |
| `parse-changelog.py` | Parse Keep a Changelog and variant formats (hash-cached) |
| `scan-deps.py` | Scan installed plugins for path dependencies |
| `rebuild-index.py` | Rebuild index.json from all data sources |

All scripts are Python 3 or Bash with no external dependencies.

## Edge Cases

- **Target is already a git repo**: Uses orphan branch `claude-scout` to avoid interference
- **`.git/` deleted by update**: Re-run `/setup-cs` to re-init; snapshot metadata in `.things/` survives
- **Large directories**: Default `.gitignore` excludes `debug/`, `file-history/`, `paste-cache/`
- **Plugin path doesn't exist**: Skipped with warning during dependency scan
- **Non-standard changelog**: Falls back to raw text extraction per `##` heading
