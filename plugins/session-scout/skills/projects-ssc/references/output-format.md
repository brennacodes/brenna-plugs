# Output Format - /projects-ssc

## Project List (no argument)

Display as a **markdown table**:

| Project | Sessions | Last Active |
|---------|----------|-------------|

- **Project**: Use `projectName` (shortened path).
- **Sessions**: The `sessionCount`.
- **Last Active**: Relative time for `lastModified`.

After the table: `{N} projects found`

Remind the user they can drill into any project with `/projects-ssc <name>`.

## Filtered by Project (with argument)

When a project name argument is provided, the skill calls `search "" --project <name>` and returns a session list. Display it using the same numbered table format as `/active-ssc`:

| # | Summary | Modified | Msgs |
|---|---------|----------|------|

The project column is omitted since all results are from the same project. Show the project name as a header above the table.

After the table: `{total} sessions in {projectName}`
