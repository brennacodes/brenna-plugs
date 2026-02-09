---
name: manage-post
description: List, search, and manage your Quartz blog posts — drafts, tags, and metadata.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[action: list, drafts, publish, tags]"
---

# Manage Blog Posts

You are helping the user manage their Quartz blog posts. This includes listing posts, managing drafts, publishing, and organizing tags.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

### 2. Resolve Content Location

- **If `source_type: remote`**: Look for the working directory at `.mark-my-words-workdir/`. If not cloned, clone it. If cloned, pull latest.
- **If `source_type: local`**: Use `<local_path>/<content_dir>/`.

### 3. Determine Action

Check `$ARGUMENTS` for the requested action. If not provided or unclear, use AskUserQuestion:

- **list** — Show all posts with metadata
- **drafts** — Show draft posts and offer to publish
- **publish** — Publish a specific draft post
- **tags** — View and manage tags across all posts

### 4. Execute the Action

---

#### Action: `list`

Scan all `.md` files in the content directory. For each post, extract from frontmatter:
- Title
- Date
- Draft status
- Tags
- Calculate word count from content body

Display as a formatted table or list, sorted by date (newest first):

```
| Title                    | Date       | Status    | Tags                  | Words |
|--------------------------|------------|-----------|-----------------------|-------|
| Building a CLI in Go     | 2025-01-15 | published | go, cli, tutorial     | 1,245 |
| Learning Rust            | 2025-01-10 | draft     | rust, learning        |   832 |
```

Show summary stats: total posts, published count, draft count.

---

#### Action: `drafts`

Scan all `.md` files and filter to those with `draft: true` in frontmatter.

Display the drafts with title, date, tags, and word count.

If drafts exist, use AskUserQuestion: "Would you like to publish any of these drafts?" with options listing each draft by title, plus "No, just looking."

If the user selects a draft to publish:
1. Read the file
2. Change `draft: true` to `draft: false`
3. Use AskUserQuestion: "Update the date to today?" — Yes or Keep original date
4. If yes, update the `date` field to today
5. Write the changes
6. Handle git workflow per config

---

#### Action: `publish`

If `$ARGUMENTS` includes a post identifier beyond "publish", search for matching draft posts.

If no specific post given, behave like `drafts` action above.

If a specific post is found:
1. Confirm with the user: "Publish '<title>'?"
2. Set `draft: false`
3. Ask about date update
4. Save and handle git workflow

If the post is already published, tell the user.

---

#### Action: `tags`

Scan all `.md` files and extract all tags from frontmatter.

**Display tag summary**: List each unique tag with how many posts use it, sorted by count:

```
| Tag          | Posts |
|--------------|-------|
| programming  |    12 |
| tutorial     |     8 |
| python       |     6 |
| learning     |     3 |
```

Then use AskUserQuestion to offer:
- "Add a tag to posts" — select a tag, then select which posts to add it to
- "Remove a tag from posts" — select a tag, show which posts have it, select which to remove from
- "Rename a tag" — rename a tag across all posts that use it
- "Done" — exit

For tag modifications:
1. Read each affected file
2. Update the `tags` list in frontmatter
3. Write the changes
4. Handle git workflow per config (batch all tag changes into one commit if auto)

### 5. Git Workflow

After any modifications, handle git based on `git_workflow` config:
- **`ask`**: Use AskUserQuestion to confirm commit/push
- **`auto`**: Auto commit with descriptive message and push
- **`manual`**: Inform user that changes are saved locally
