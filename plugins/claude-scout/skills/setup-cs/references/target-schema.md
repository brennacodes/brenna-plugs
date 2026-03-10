# Target Schema

A target is a directory that claude-scout tracks via git snapshots.

## targets.json

```json
{
  "version": 1,
  "targets": {
    "<target-id>": {
      "id": "<target-id>",
      "path": "/absolute/path/to/directory",
      "display_name": "Human-Readable Name",
      "created": "YYYY-MM-DD",
      "last_snapshot": "YYYY-MM-DDTHH:MM:SSZ",
      "snapshot_count": 0,
      "git_branch": "claude-scout",
      "changelogs": [
        { "path": "relative/path/to/changelog.md", "type": "keep-a-changelog" }
      ],
      "plugin_scan_paths": ["plugins/cache/", "plugins/installed_plugins.json"]
    }
  }
}
```

## Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique identifier, typically kebab-case (e.g., `claude-home`) |
| path | string | Absolute path to the tracked directory |
| display_name | string | Human-readable name for display |
| created | string | ISO date when the target was created |
| last_snapshot | string | ISO timestamp of the most recent snapshot |
| snapshot_count | number | Total snapshots taken for this target |
| git_branch | string | Branch name used for snapshots (default: `claude-scout`) |
| changelogs | array | Changelog files to parse, relative to target path |
| plugin_scan_paths | array | Paths within the target to scan for plugin dependencies |

## Changelog Types

- `keep-a-changelog`: Standard format with `## [version] - date` and `### Type` sections
- `claude-variant`: `## version` headings with prefixed items (Added/Fixed/etc.)

## snapshot-log.json

```json
{
  "version": 1,
  "target_id": "<target-id>",
  "last_updated": "YYYY-MM-DDTHH:MM:SSZ",
  "entries": [
    {
      "sha": "abc123...",
      "timestamp": "YYYY-MM-DDTHH:MM:SSZ",
      "message": "snapshot message",
      "files_changed": 5,
      "insertions": 42,
      "deletions": 3,
      "tags": ["tag1"]
    }
  ]
}
```
