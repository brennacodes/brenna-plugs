# Output Format — /sesh:active

## Table Format

Display sessions as a **numbered markdown table** with these columns:

| # | Summary | Project | Modified | Msgs |
|---|---------|---------|----------|------|

## Formatting Rules

- **#**: Sequential number starting at 1.
- **Summary**: Truncate to 50 characters with `...` if longer.
- **Project**: Use the `projectName` field (already shortened).
- **Modified**: Show as a **relative time** — "2 hours ago", "3 days ago", "Jan 15". Use relative for anything within the last 7 days; use "Mon DD" format for older.
- **Msgs**: The `messageCount` value.

## After the Table

Show: `Showing {showing} of {total} sessions`

Remind the user they can:
- Ask for the resume command for any session by number
- Use `/sesh:active <N>` to change the limit
- Use `/sesh:search` for keyword filtering
