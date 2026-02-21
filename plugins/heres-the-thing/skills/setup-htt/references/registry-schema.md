# Registry Schema Reference

## Overview

The collection registry at `.things/registry.json` declares the structure of every data collection stored in `.things/`. It enables HTT to validate structure, search across collections, dispatch rebuild commands, and detect orphaned data - all without understanding domain semantics.

## Schema

```json
{
  "version": "1.0.0",
  "collections": {
    "<collection-path>": {
      "plugin": "string",
      "description": "string",
      "item_structure": { ... },
      "index_schema": { ... },
      "master_index": "string | null",
      "rebuild_command": "string | null"
    }
  }
}
```

## Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Registry schema version (semver) |
| `collections` | object | Map of collection path → collection definition |

Collection paths are relative to `.things/` root (e.g., `shared/people`, `think-like/profiles`, `i-did-a-thing/logs`).

## Collection Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `plugin` | string | yes | Plugin that owns this collection |
| `description` | string | yes | Human-readable description |
| `item_structure` | object | yes | How items are organized on disk |
| `index_schema` | object | yes | Shape of index entries (can be empty `{}`) |
| `master_index` | string/null | yes | Path to master index file (relative to `.things/`), or null |
| `rebuild_command` | string/null | yes | Shell command to rebuild indexes after writes, or null |

## Item Structure

Two patterns: directory-per-item and flat files.

### Directory Per Item

Each item is a subdirectory containing required and optional files.

```json
{
  "directory_per_item": true,
  "required_files": ["profile.md", "index.json"],
  "optional_file_patterns": ["*.md"],
  "index_file": "index.json"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `directory_per_item` | boolean | `true` for directory-per-item |
| `required_files` | string[] | Files that must exist in each item directory |
| `optional_file_patterns` | string[] | Glob patterns for optional files |
| `index_file` | string/null | Name of the per-item index file |

### Flat Files

Items are individual files in the collection directory.

```json
{
  "directory_per_item": false,
  "file_pattern": "*.md"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `directory_per_item` | boolean | `false` for flat files |
| `file_pattern` | string | Glob pattern for item files |

## Index Schema

Declares the expected fields in index entries. Used by HTT for validation and search.

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
    "speculative": "boolean"
  }
}
```

### Supported Field Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Plain text | `"dhh"` |
| `string[]` | Array of strings | `["rails", "ruby"]` |
| `number` | Numeric value | `42` |
| `boolean` | True or false | `true` |
| `date` | ISO date string | `"2026-02-20"` |
| `object` | Nested JSON object | `{"name": "code-review"}` |
| `object[]` | Array of objects | `[{"name": "code-review", "file": "code-review.md"}]` |

An empty `index_schema` (`{}`) means the collection has no structured index - HTT won't validate index entries for this collection.

## Rebuild Command

When present, HTT's PostToolUse hook invokes this command after detecting a write to the collection's directory. The command receives `${THINGS_PATH}` as an environment variable.

```json
{
  "rebuild_command": "python3 /absolute/path/to/rebuild-data.py ${THINGS_PATH}"
}
```

The path is resolved to an absolute path at registration time. If the plugin is upgraded to a new cached version, the registration should be updated.

If `rebuild_command` is `null`, no rebuild is triggered for writes to this collection.

## Example: Full Registry

```json
{
  "version": "1.0.0",
  "collections": {
    "shared/people": {
      "plugin": "heres-the-thing",
      "description": "Shared people profiles accessible to all plugins",
      "item_structure": {
        "directory_per_item": true,
        "required_files": ["profile.md", "index.json"],
        "optional_file_patterns": ["*.md"],
        "index_file": "index.json"
      },
      "index_schema": {
        "required_fields": {
          "id": "string",
          "display_name": "string",
          "tags": "string[]",
          "created": "date"
        },
        "optional_fields": {
          "source_references": "string[]",
          "speculative": "boolean"
        }
      },
      "master_index": "shared/people/master-index.json",
      "rebuild_command": null
    },
    "think-like/profiles": {
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
  }
}
```
