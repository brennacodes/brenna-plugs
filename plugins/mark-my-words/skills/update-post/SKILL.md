---
name: update-post
description: Update an existing blog post on your Quartz site.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[post filename or search term]"
---

# Update Existing Blog Post

You are helping the user update an existing blog post on their Quartz site. Find the post, understand what they want to change, and apply the updates carefully.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

### 2. Resolve Content Location

- **If `source_type: remote`**: Look for the working directory at `.mark-my-words-workdir/`. If not cloned, clone it. If cloned, pull latest.
- **If `source_type: local`**: Use `<local_path>/<content_dir>/`.

### 3. Find the Post

- **If `$ARGUMENTS` was provided**: Search for matching posts by:
  - Filename match (glob for `*<argument>*.md`)
  - Title match (grep for the argument in frontmatter `title:` fields)
  - Content match if no filename/title hits
- **If no arguments**: List the 10 most recently modified `.md` files in the content directory with their titles and dates.

If multiple posts match, use AskUserQuestion to let the user select which one. Show title, date, and filename for each option.

If no posts match, tell the user and suggest they check the filename or try a different search term.

### 4. Read the Post

Read the full content of the selected post. Display a summary to the user:
- Title
- Date
- Tags
- Draft status
- Word count
- First few lines of content (or section headings)

### 5. Interview for Changes

Use AskUserQuestion to determine what the user wants to change. Consult `references/update-strategies.md` for guidance on each approach.

**Update mode**:
- "Edit specific sections" — modify particular parts while keeping the rest intact
- "Append new content" — add a new section or content to the end
- "Full rewrite" — rewrite the entire post with new content
- "Frontmatter only" — just update metadata (tags, title, date, draft status)

**Based on the mode chosen**:

For **edit specific sections**: Ask which section(s) to modify and what the changes should be. List the current headings so the user can reference them.

For **append new content**: Ask what new section/content to add and where it should go (end of post, before conclusion, after a specific section).

For **full rewrite**: Ask for the new direction/focus. Confirm that they want to replace all existing content.

For **frontmatter only**: Use AskUserQuestion to ask what to update:
- Title
- Tags (add/remove)
- Draft status (publish/unpublish)
- Description
- Date

**Frontmatter date handling**: Ask if they want to:
- Keep the original date
- Update to today's date
- Add a `lastmod` field with today's date (recommended for edits)

### 6. Apply Changes

- Use the Edit tool for targeted changes to preserve the rest of the file
- Use Write only for full rewrites
- Preserve any frontmatter fields the user didn't ask to change
- If adding `lastmod`, keep the original `date` field intact
- Maintain the post's existing voice and style unless the user asked for a tone change

### 7. Show the Result

After making changes, read the updated file and show the user:
- Updated frontmatter
- A brief summary of what changed
- The file path

### 8. Handle Git Workflow

Based on the `git_workflow` config setting:
- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this update?" with options: Yes (commit + push), Commit only, No
- **`auto`**: Automatically `git add`, `git commit -m "Update post: <title>"`, and `git push`
- **`manual`**: Tell the user the file has been updated and they can commit when ready
