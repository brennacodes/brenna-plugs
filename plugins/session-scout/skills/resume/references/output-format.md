# Output Format - /resume

## Single Match

Display a **session detail card**:

```
Session: <sessionId>
Summary: <summary>
Project: <projectName> (<projectPath>)
Created: <created as readable date>
Modified: <modified as readable date>
Messages: <messageCount>
```

Then show the resume command in a **fenced code block**:

```bash
cd "/path/to/project" && claude --resume <sessionId>
```

Tell the user they can copy and paste this command to resume the session.

## Multiple Matches

Show a numbered list of matches:

| # | Session ID (first 8 chars) | Summary | Project |
|---|---------------------------|---------|---------|

Ask the user to pick one by number, then show the full resume details for that selection.

## No Match

> No session found matching "{id}". Try `/active` to browse recent sessions or `/search` to find by keyword.
