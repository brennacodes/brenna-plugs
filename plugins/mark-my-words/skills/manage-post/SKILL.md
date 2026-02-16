---
name: manage-post
description: List, search, and manage your blog posts — drafts, tags, and metadata.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[action: list, drafts, publish, tags]"
---

# Manage Blog Posts

You are helping the user manage their blog posts. This includes listing posts, managing drafts, publishing, and organizing tags.

## Steps

### 1. Load Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Read `<home>/.claude/things.local.md` to get `things_path` (if `things_path` starts with `~`, replace with `<home>`). If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

Read `<things_path>/config.yml` for all settings. Extract the `blog:` section. If config.yml is missing or blog not configured, tell the user to run `/mark-my-words:setup`.

#### Load Platform Template

Read `blog.platform` from config (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines how drafts work and frontmatter field names for the user's platform.

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
- Date (field name varies by platform — check template)
- Draft status (varies by platform — see draft detection below)
- Tags (YAML `tags:` list, or TOML `tags = []` for Zola, or `[taxonomies]` table)
- Calculate word count from content body

**Draft detection by platform**:
- **Jekyll**: A post is a draft if it's in the `_drafts/` directory OR has `published: false` in frontmatter
- **Zola/Hugo/Quartz/Astro/Eleventy**: `draft: true` in frontmatter (or `draft = true` for TOML)
- **Docusaurus**: `draft: true` in frontmatter

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

Scan all `.md` files and identify drafts using the platform-specific draft detection described above. For Jekyll, also scan the `_drafts/` directory.

Display the drafts with title, date, tags, and word count.

If drafts exist, use AskUserQuestion: "Would you like to publish any of these drafts?" with options listing each draft by title, plus "No, just looking."

If the user selects a draft to publish, apply the platform-specific publish action:

**For Jekyll** (if post is in `_drafts/`):
1. Read the file
2. Add a `date` field in frontmatter if not present (today's date)
3. Move the file to `_posts/` with the date-prefixed filename: `YYYY-MM-DD-slug.md`
4. Handle git workflow per config

**For Jekyll** (if post has `published: false`):
1. Read the file
2. Change `published: false` to `published: true`
3. Ask about date update
4. Handle git workflow per config

**For all other platforms**:
1. Read the file
2. Change `draft: true` to `draft: false` (or `draft = false` for TOML)
3. Use AskUserQuestion: "Update the date to today?" — Yes or Keep original date
4. If yes, update the date field (using the platform's field name)
5. Write the changes
6. Handle git workflow per config

---

#### Action: `publish`

If `$ARGUMENTS` includes a post identifier beyond "publish", search for matching draft posts.

If no specific post given, behave like `drafts` action above.

If a specific post is found:
1. Confirm with the user: "Publish '<title>'?"
2. Apply the platform-specific publish action (same as drafts above)

If the post is already published, tell the user.

---

#### Action: `tags`

Scan all `.md` files and extract all tags from frontmatter. For TOML-based platforms (Zola), look for tags in the `[taxonomies]` table.

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
2. Update the tags in frontmatter using the platform's format (YAML list or TOML array)
3. Write the changes
4. Handle git workflow per config (batch all tag changes into one commit if auto)

### 5. Git Workflow

Before committing, pull latest changes from the remote (if one exists) to avoid conflicts:

```bash
git -C <content_root> pull --rebase 2>/dev/null || true
```

After any modifications, handle git based on `git_workflow` config:
- **`ask`**: Use AskUserQuestion to confirm commit/push
- **`auto`**: Auto commit with descriptive message and push
- **`manual`**: Inform user that changes are saved locally
