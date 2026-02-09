# Update Strategies Reference

Guidance for updating existing Quartz blog posts while preserving integrity.

## Preserving Frontmatter

When updating a post, always read the full frontmatter first and only modify the fields the user requested. Never drop existing fields.

### Safe Frontmatter Update Pattern

1. Read the file and parse all existing frontmatter fields
2. Apply only the requested changes
3. Keep all other fields exactly as they were
4. Write the complete frontmatter back

Example — if the user asks to add a tag, and the original frontmatter is:

```yaml
---
title: "My Post"
date: 2025-01-10
tags:
  - programming
  - python
draft: false
description: "A post about Python"
---
```

The result should add the new tag while keeping everything else:

```yaml
---
title: "My Post"
date: 2025-01-10
tags:
  - programming
  - python
  - tutorial
draft: false
description: "A post about Python"
---
```

## Date Update Considerations

### When to update `date`
- The user explicitly asks to change the publication date
- The post was a draft being published for the first time

### When to add `lastmod`
- The post was already published and is being edited
- This preserves the original publication date while showing it was updated
- Format: `lastmod: 2025-03-15`

### When to keep dates unchanged
- Frontmatter-only changes like tag edits
- Typo fixes
- Minor corrections

## Section-Level Editing

### Finding Sections

Identify sections by their heading markers (`##`, `###`). A section spans from its heading to the next heading of the same or higher level.

### Replacing a Section

When replacing a section's content:
1. Identify the start: the heading line
2. Identify the end: the line before the next heading of the same or higher level, or end of file
3. Replace everything between start and end (inclusive of heading if title changed, exclusive if not)
4. Preserve blank lines between sections for readability

### Inserting After a Section

When appending content after a specific section:
1. Find the end of the target section (line before next same-or-higher-level heading)
2. Insert a blank line, then the new content
3. Ensure proper heading hierarchy — if inserting under an h2, use h3 for subsections

## Append Patterns

### Adding to the End

Insert new content before any final horizontal rule or "conclusion" section if one exists. If the post ends with a summary/conclusion, ask the user if the new content should go before or after it.

### Adding a New Section

- Use the same heading level as other major sections (typically h2)
- Maintain consistent formatting with the rest of the post
- Add a blank line before and after the new section

## Tag Management

### Adding Tags
- Check existing tags across the blog for consistency (avoid duplicates like `javascript` vs `js`)
- Add to the existing `tags` list in frontmatter
- Keep tags lowercase by convention

### Removing Tags
- Remove from the `tags` list
- If the list becomes empty, keep `tags: []` rather than removing the field

## Full Rewrite

When doing a full rewrite:
1. Preserve the original frontmatter as a starting point
2. Update `date` or add `lastmod` as appropriate
3. Generate entirely new content based on the user's direction
4. Maintain the same filename and path
5. Consider updating `description` to match the new content
