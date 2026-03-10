# Changelog Format Reference

claude-scout parses changelog files to correlate official release notes with observed filesystem changes.

## Keep a Changelog (Standard)

```markdown
# Changelog

## [1.2.0] - 2026-02-28

### Added
- New feature description

### Fixed
- Bug fix description

### Changed
- Change description

## [1.1.0] - 2026-02-15
...
```

## Claude Code Variant

Claude Code's `cache/changelog.md` uses a simplified format:

```markdown
# Claude Code Changelog

## 1.2.0
- Added: New feature description
- Fixed: Bug fix description
- Improved: Performance improvement

## 1.1.0
...
```

## Parsed Output

Both formats are normalized to:

```json
{
  "version": 1,
  "source": "/path/to/changelog.md",
  "source_hash": "sha256...",
  "parsed_date": "2026-03-01",
  "total_entries": 10,
  "entries": [
    {
      "version": "1.2.0",
      "date": "2026-02-28",
      "changes": [
        { "type": "added", "description": "New feature description" },
        { "type": "fixed", "description": "Bug fix description" }
      ]
    }
  ]
}
```

## Change Types

| Type | Description |
|------|-------------|
| added | New features or files |
| fixed | Bug fixes |
| changed | Modifications to existing behavior |
| improved | Performance or quality improvements |
| removed | Removed features or files |
| deprecated | Features marked for future removal |
| security | Security-related changes |
| other | Items that don't match known prefixes |
