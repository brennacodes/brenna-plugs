# session-scout

Search, browse, and resume Claude Code sessions across all projects.

Built on a Python script that reads Claude Code's session data directly - no external dependencies.

## Installation

```
/plugin install session-scout@brenna-plugs
```

## Skills

### Active

View recent sessions sorted by last modified date.

```
/active          # Show 10 most recent sessions
/active 20       # Show 20 most recent
```

### Projects

List all projects with session counts, or drill into a specific project.

```
/projects            # List all projects
/projects [project]      # Show all sessions for <project>
```

### Search

Search sessions by keyword across all projects. Searches summaries and first prompts by default, or full transcripts with `--deep`.

```
/search auth bug               # Search index metadata
/search plugin --deep           # Also search full transcripts
/search "" --project <project>      # List all sessions for <project>
/search refactor --since "3 days ago"
/search fix --since 2026-02-01 --until 2026-02-15
```

### Resume

Get the resume command for a session by full or partial ID.

```
/resume 448332ee                                    # Partial ID match
/resume 448332ee-bf11-48c7-ad0b-3d9d1ee2a07d       # Full ID
```

## Requirements

- Python 3
