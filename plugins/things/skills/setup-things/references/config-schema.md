# Config Schema Reference

## Convention Path

`.things/` lives at `~/.things/` by convention. No bootstrap or pointer file is needed. All plugins use this path directly.

In SKILL.md files, resolve `$HOME` first (run `echo $HOME` via Bash), then read `<home>/.things/config.json`. In shell scripts, use `$HOME/.things`.

---

## Main Config

**File**: `<home>/.things/config.json`
**Purpose**: Identity, git settings, and environment tracking. Git-tracked in the `.things/` repo.

```json
{
  "version": "1.0.0",
  "github_username": "string",
  "git": {
    "remote": "string | null",
    "branch": "string",
    "workflow": "auto | ask | manual"
  },
  "environments": {
    "<hostname>": {
      "first_seen": "date",
      "last_active": "date",
      "plugins": ["string"]
    }
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Config schema version (semver) |
| `github_username` | string | GitHub username |
| `git.remote` | string/null | Git remote URL, or null for local-only |
| `git.branch` | string | Git branch name (default: `main`) |
| `git.workflow` | string | `auto` (commit+push automatically), `ask` (prompt each time), `manual` (user handles git) |
| `environments` | object | Map of hostname → machine info |
| `environments.<host>.first_seen` | date | When this machine first used .things |
| `environments.<host>.last_active` | date | Last time a plugin was used on this machine |
| `environments.<host>.plugins` | string[] | Plugin names active on this machine |

---

## Local Overrides

**File**: `<home>/.things/local.json`
**Purpose**: Machine-specific overrides. Gitignored - never synced.

```json
{}
```

Reserved for future use (e.g., machine-specific git settings, local-only plugin preferences). Plugins may read this file but should not depend on it having any keys.

---

## Professional Profile

**File**: `<home>/.things/shared/professional-profile.json`
**Purpose**: User's career identity. Used by career plugins for context. Git-tracked.

```json
{
  "author_name": "string",
  "current_role": "string",
  "target_roles": ["string"],
  "career_direction": ["string"],
  "building_skills": ["string"],
  "aspirational_skills": ["string"]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `author_name` | string | Display name for attribution |
| `current_role` | string | Current job title |
| `target_roles` | string[] | Roles being targeted |
| `career_direction` | string[] | Professional growth directions |
| `building_skills` | string[] | Skills actively being developed |
| `aspirational_skills` | string[] | Skills to develop next |

---

## Per-Plugin Preferences

**File**: `<home>/.things/{plugin-name}/preferences.json`
**Purpose**: Plugin-specific settings. Each plugin defines its own schema.

Example (think-like):
```json
{
  "default_profile": null,
  "session_logging": true
}
```

HTT does not enforce a preferences schema - it's entirely plugin-owned. HTT only cares that preferences files are valid JSON if they exist.
