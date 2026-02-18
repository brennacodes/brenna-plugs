# Output Format — /sesh:search

## Table Format

Display results as a **numbered markdown table**:

| # | Summary | Project | Modified | Msgs | Match |
|---|---------|---------|----------|------|-------|

## Formatting Rules

- **#**: Sequential number starting at 1.
- **Summary**: Truncate to 50 characters with `...` if longer.
- **Project**: Use the `projectName` field.
- **Modified**: Relative time (same rules as active format).
- **Msgs**: The `messageCount` value.
- **Match**: Where the query was found — show `summary`, `prompt`, or `transcript`.

## After the Table

Show: `Found {total} sessions matching "{query}"`

If `--deep` was used, note that transcript content was also searched.

## Empty Results

If 0 results and `--deep` was not used:
> No sessions found matching "{query}" in metadata. Try `/sesh:search {query} --deep` to also search inside session transcripts.

If 0 results with `--deep`:
> No sessions found matching "{query}" in metadata or transcripts.
