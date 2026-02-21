# Collection Definition Schema

## Overview

Each collection in the registry defines how a plugin's data is structured on disk. This schema is used by the `/register` skill and by the setup skills of individual plugins.

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `plugin` | string | Plugin that owns this collection (e.g., `think-like`, `i-did-a-thing`) |
| `description` | string | Human-readable description of what the collection stores |
| `item_structure` | object | How items are organized on disk (see below) |
| `index_schema` | object | Expected fields in index entries (see below). Empty `{}` for unindexed collections |
| `master_index` | string/null | Path to master index file relative to `.things/`, or `null` |
| `rebuild_command` | string/null | Shell command invoked after writes to this collection, or `null` |

## Item Structure Patterns

### Pattern 1: Directory Per Item

Each item is a subdirectory containing specific files.

```json
{
  "directory_per_item": true,
  "required_files": ["profile.md", "index.json"],
  "optional_file_patterns": ["*.md"],
  "index_file": "index.json"
}
```

Use when items have multiple related files (e.g., a person profile with multiple context files).

### Pattern 2: Flat Files

Items are individual files in the collection directory.

```json
{
  "directory_per_item": false,
  "file_pattern": "*.md"
}
```

Use when each item is a single file (e.g., role definitions, log entries).

## Index Schema

Declares the shape of entries in the collection's index files. Used for validation and search.

```json
{
  "required_fields": {
    "id": "string",
    "display_name": "string",
    "tags": "string[]",
    "created": "date"
  },
  "optional_fields": {
    "last_used": "date",
    "speculative": "boolean",
    "contexts": "object[]"
  }
}
```

Supported types: `string`, `string[]`, `number`, `boolean`, `date`, `object`, `object[]`.

An empty schema (`{}`) means no index validation is performed.

## Rebuild Command

The `rebuild_command` is invoked by HTT's PostToolUse hook when a write is detected in the collection's directory.

Requirements:
- Must be a complete shell command with absolute paths
- Path is resolved at registration time (not at runtime)
- `${THINGS_PATH}` is available as an environment variable at invocation time
- Command should exit 0 on success, non-zero on failure (failures don't block the hook)

Example:
```json
{
  "rebuild_command": "python3 /Users/user/.claude/plugins/cache/brenna-plugs/i-did-a-thing/4.0.0/scripts/rebuild-data.py ${THINGS_PATH}"
}
```

Set to `null` for collections that don't need automated rebuilds.

## Complete Examples

### Directory-per-item collection with index

```json
{
  "plugin": "think-like",
  "description": "Expert thinking profiles for code-focused activities",
  "item_structure": {
    "directory_per_item": true,
    "required_files": ["index.json"],
    "optional_file_patterns": ["*.md"],
    "index_file": "index.json"
  },
  "index_schema": {
    "required_fields": {
      "id": "string",
      "display_name": "string",
      "person_ref": "string",
      "tags": "string[]",
      "created": "date"
    },
    "optional_fields": {
      "contexts": "object[]",
      "last_used": "date"
    }
  },
  "master_index": "think-like/profiles/master-index.json",
  "rebuild_command": null
}
```

### Flat-file collection with rebuild

```json
{
  "plugin": "i-did-a-thing",
  "description": "Raw accomplishment log files",
  "item_structure": {
    "directory_per_item": false,
    "file_pattern": "*.md"
  },
  "index_schema": {
    "required_fields": {
      "filename": "string",
      "title": "string",
      "date": "date",
      "tags": "string[]"
    },
    "optional_fields": {
      "resume_bullets": "string[]",
      "interview_talking_points": "string"
    }
  },
  "master_index": "i-did-a-thing/index.json",
  "rebuild_command": "python3 /path/to/rebuild-data.py ${THINGS_PATH}"
}
```

### Minimal collection (no index, no rebuild)

```json
{
  "plugin": "heres-the-thing",
  "description": "Shared role definitions accessible to all plugins",
  "item_structure": {
    "directory_per_item": false,
    "file_pattern": "*.md"
  },
  "index_schema": {},
  "master_index": null,
  "rebuild_command": null
}
```
