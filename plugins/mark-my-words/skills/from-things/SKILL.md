---
name: from-things
description: "Create a blog post from i-did-a-thing accomplishment logs — turn your wins into stories"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[log filename or search query]"
---

# Create Post from Things

Source a blog post from one or more i-did-a-thing accomplishment logs. Each log already contains a Blog Seed, narrative structure, and potential angles — this skill transforms them into engaging posts.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` for blog settings. If missing:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

Read `.claude/i-did-a-thing.local.md` to find the things directory. If missing:

> No i-did-a-thing configuration found. Please run `/i-did-a-thing:setup` first to set up your accomplishment tracking.

Then stop.

### 2. Resolve Content Location

- **If `source_type: remote`**: Check if the repo is already cloned locally. Look for a working directory at `.mark-my-words-workdir/` relative to the project root. If not cloned, clone it:
  ```
  git clone --branch <repo_branch> <repo_url> .mark-my-words-workdir
  ```
  If already cloned, pull latest changes.
  The content root is `.mark-my-words-workdir/<content_dir>/`.

- **If `source_type: local`**: The content root is `<local_path>/<content_dir>/`.

### 3. Select Logs

If the user provided a filename or search query as an argument, find matching logs in `<things_path>/logs/`. Otherwise, present options:

Use AskUserQuestion:

**What do you want to write about?**
- Browse recent logs (last 10)
- Search by tag or skill
- Find entries marked high blog potential
- Combine multiple logs into one post

#### If "Browse recent":
List the 10 most recent logs from `<things_path>/logs/` showing title, date, impact, and `blog_potential` from frontmatter. Let the user select one.

#### If "Search":
Ask for search criteria (tag, skill, or keyword). Use Grep to search log frontmatter and content. Present matching results and let the user select.

#### If "High blog potential":
Search all logs for entries with `blog_potential: "high"` in frontmatter. Present results.

#### If "Combine multiple":
Let the user select 2-5 logs to weave into a single narrative post. See `references/things-bridge.md` for multi-log strategies.

### 4. Read Selected Logs

Read the full content of selected log(s). Extract:
- **Blog Seed** section — the opening hook
- **Potential angles** — narrative direction options
- **Context / Action / Result** — the substance
- **Reflection** — personal voice and takeaway
- **Metrics** — concrete numbers from frontmatter
- **Tags and skills** — for post categorization

### 5. Choose the Narrative Angle

Use AskUserQuestion to present the potential angles from the log(s), plus standard options:

**What angle should this post take?**
- <Angle 1 from log's "Potential angles">
- <Angle 2 from log's "Potential angles">
- Tutorial/how-to (teach what you learned)
- Retrospective (reflect on the journey)

### 6. Scan Existing Posts

Use Glob and Grep to scan the blog content directory:
- Find all `.md` files in the target subdirectory
- Extract existing tags from frontmatter across posts
- This informs tag suggestions and maintains consistency

### 7. Generate the Post

Transform the log into a blog post following the Quartz format in `../new-post/references/quartz-format.md` and the transformation guide in `references/things-bridge.md`.

**Transformation rules:**
1. **Open with the Blog Seed** hook, adapted to the chosen angle
2. **Rewrite the title** — engaging and blog-appropriate, not resume-like
3. **Transform Context → Action → Result** into narrative prose with a natural, first-person voice
4. **Include code/technical details** if the log has them, using proper Quartz code blocks with language identifiers
5. **Pull metrics** from frontmatter and contextualize them (not just numbers, but why they matter)
6. **Expand the Reflection** into a genuine takeaway for readers
7. **Generate Quartz-compatible frontmatter:**
   - `title`: Rewritten for a blog audience
   - `date`: Today's date (when the post is written)
   - `description`: 1-2 sentence preview for SEO/social
   - `tags`: Adapted from log tags, blended with existing blog tags where appropriate
   - `draft`: `true` initially
   - `author`: From mark-my-words config (`default_author`)

**Content quality:**
- Write in a natural, engaging voice — personal blog, not documentation
- Use H2 for major sections, H3 for subsections (no H1 in body)
- One idea per paragraph
- Use callouts (`> [!tip]`, etc.) sparingly and where they add value
- End with a clear takeaway

### 8. Present for Review

Show the generated post and ask:

**How's this draft?**
- Save it — I'll review and publish later
- Edit it first — I want to refine some sections
- Change the angle — try a different approach
- Start over — pick different logs

#### If "Save it":
Continue to Step 9.

#### If "Edit":
Use AskUserQuestion to identify which sections to revise, then Edit the draft and present again.

#### If "Change angle":
Go back to Step 5.

#### If "Start over":
Go back to Step 3.

### 9. Save the File

- Generate a filename from the title: lowercase, hyphens for spaces, no special characters
- Write to `<content_root>/<default_subdirectory>/<filename>.md`
- Tell the user the file path

### 10. Update Source Log Metadata

Edit the source log(s) in `<things_path>/logs/` to record that a post was created. Add to the log's frontmatter:

```yaml
blog_post: "<path to generated post>"
blog_post_date: <today's date>
```

This prevents the same log from being surfaced as "unused" in future runs.

### 11. Handle Git Workflow

Based on the mark-my-words `git_workflow` config setting:

- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this post?" with options: Yes (commit + push), Commit only (no push), No (skip git)
- **`auto`**: Automatically `git add`, `git commit -m "Add post: <title> (from things)"`, and `git push`
- **`manual`**: Tell the user the file has been written and they can commit when ready

Only do git operations if the content is in a git repository.

### 12. Suggest Related Posts

Based on the source log's tags and skills, check if other logs could make good companion posts:

> Based on your tags, these logs could make good follow-up posts:
> - "<log title>" — <potential angle>
> - "<log title>" — <potential angle>
>
> Run `/mark-my-words:from-things <filename>` to draft one.
