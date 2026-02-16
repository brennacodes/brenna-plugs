---
name: from-things
description: "Create a blog post from i-did-a-thing evidence logs — turn your wins into stories"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[log filename or search query]"
---

# Create Post from Things

Source a blog post from one or more i-did-a-thing evidence logs. Each log already contains a Blog Seed, narrative structure, and potential angles — this skill transforms them into engaging posts.

## Steps

### 1. Load Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Read `<home>/.claude/things.local.md` to get `things_path` (if `things_path` starts with `~`, replace with `<home>`). If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

Read `<things_path>/config.yml` for all settings. Extract the `blog:` section. If config.yml is missing or blog not configured, tell the user to run `/mark-my-words:setup`.

#### Load Platform Template

Read `blog.platform` from config (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines all platform-specific formatting rules — frontmatter fields, content syntax, image format, callouts, code blocks, and file naming conventions.

#### Load Voice Profile

If the config has `blog.default_voice` set (not null), read the voice profile from `<things_path>/voices/<default_voice>.md`. If the file doesn't exist, warn the user that their default voice profile is missing and continue without a voice.

Also check if any voice profiles exist in `<things_path>/voices/` using Glob. Store this for the interview step.

#### Resolve Media Directory

If the config has `blog.media_dir` set (not null), resolve the full media path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`). Store this path for use in visual planning and post generation.

### 2. Resolve Content Location

- **If `source_type: remote`**: Check if the repo is already cloned locally. Look for a working directory at `.mark-my-words-workdir/` relative to the project root. If not cloned, clone it:
  ```
  git clone --branch <repo_branch> <repo_url> .mark-my-words-workdir
  ```
  If already cloned, pull latest changes.
  The content root is `.mark-my-words-workdir/<content_dir>/`.

- **If `source_type: local`**: The content root is `<local_path>/<content_dir>/`.

### 3. Select Logs

Read `<things_path>/index.json` to get the full index of all logs with their metadata, blog seeds, and blog_potential ratings.

If the user provided a filename or search query as an argument, find matching entries in the index. Otherwise, present options:

Use AskUserQuestion:

**What do you want to write about?**
- Browse recent logs (last 10)
- Search by tag or skill
- Find entries marked high blog potential
- Combine multiple logs into one post

#### If "Browse recent":
Show the first 10 entries from `index.json` (already sorted by date descending) with title, date, impact, and `blog_potential`. Let the user select one.

#### If "Search":
Ask for search criteria (tag, skill, or keyword). Filter entries in `index.json` by matching tags, skills_used, or title/description. Present matching results and let the user select.

#### If "High blog potential":
Filter entries in `index.json` where `blog_potential` is `"high"`. Present results.

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

### 6. Select Voice

If voice profiles exist in `<things_path>/voices/`:
- If a default voice is set, show it and ask if they want to use it, pick a different one, or skip voice for this post
- If no default is set, list available voices and let them pick one or skip

### 7. Scan Existing Posts

Use Glob and Grep to scan the blog content directory:
- Find all `.md` files in the target subdirectory
- Extract existing tags from frontmatter across posts
- This informs tag suggestions and maintains consistency

### 7.5. Plan Visuals

Only run this step if `media_dir` is configured.

Analyze the selected log(s) for visual content opportunities:
- **Architecture in Action section** → flowcharts or system diagrams (only if platform supports Mermaid)
- **Process flows** (deployment pipelines, workflows, data flows) → sequence diagrams or flowcharts
- **Before/after comparisons** → side-by-side images or diagrams
- **Metrics and results** → tables or formatted data presentations

Use AskUserQuestion:

**How should we handle visuals?**
- "Generate diagrams where they fit" — create Mermaid diagrams for architecture and flow content (only offered if platform supports Mermaid)
- "Also find relevant images" — diagrams plus web-searched images for visual concepts
- "Keep it text-only" — skip visuals entirely
- "Decide as we write" — suggest visuals inline during generation

Store the user's choice for Step 8.

### 8. Generate the Post

Transform the log into a blog post following the platform template loaded in Step 1 and the transformation guide in `references/things-bridge.md`.

**Transformation rules:**
1. **Open with the Blog Seed** hook, adapted to the chosen angle
2. **Rewrite the title** — engaging and blog-appropriate, not resume-like
3. **Transform Context → Action → Result** into narrative prose with a natural, first-person voice
4. **Include code/technical details** if the log has them, using proper code blocks with language identifiers and any platform-specific code block features (titles, line highlighting) where appropriate
5. **Pull metrics** from frontmatter and contextualize them (not just numbers, but why they matter)
6. **Expand the Reflection** into a genuine takeaway for readers
7. **Generate platform-compatible frontmatter** following the template:
   - Use the platform's frontmatter format (YAML `---` or TOML `+++`)
   - Use the platform's field names (e.g., `pubDate` for Astro, `date` for most others)
   - `title`: Rewritten for a blog audience
   - Date: Today's date (when the post is written)
   - `description`: 1-2 sentence preview for SEO/social
   - Tags: Adapted from log tags, blended with existing blog tags, using platform format
   - Draft: `true` initially (or platform equivalent)
   - Author: From config, placed in the platform's expected field
8. **Add visuals if planned in Step 7.5** — generate Mermaid diagrams for architecture and flow content from the log's Action section (only if platform supports Mermaid), insert image references using the platform's image syntax, place visuals after the text that introduces the concept. Follow placement rules from `../add-media/references/media-guide.md`. If the user chose "Decide as we write", suggest visuals inline and ask before adding each one. If "Also find relevant images", use WebSearch to find and download relevant images to the media dir.

**Content quality:**
- If a voice profile was selected, follow its guidance for tone, sentence patterns, vocabulary, rhetorical habits, and things to avoid. The voice shapes how you write — the transformation rules still control what you write (Blog Seed hook, narrative structure, metrics integration). Voice and transformation rules are complementary, not competing.
- If no voice profile was selected, write in a natural, engaging voice — personal blog, not documentation
- Use H2 for major sections, H3 for subsections (no H1 in body)
- One idea per paragraph
- Use the platform's native callout/admonition syntax if supported, sparingly and where they add value. If the platform doesn't support callouts, use blockquotes or emphasized text.
- End with a clear takeaway

### 9. Present for Review

Show the generated post and ask:

**How's this draft?**
- Save it — I'll review and publish later
- Edit it first — I want to refine some sections
- Change the angle — try a different approach
- Start over — pick different logs

#### If "Save it":
Continue to Step 10.

#### If "Edit":
Use AskUserQuestion to identify which sections to revise, then Edit the draft and present again.

#### If "Change angle":
Go back to Step 5.

#### If "Start over":
Go back to Step 3.

### 10. Save the File

Generate a filename following the platform's naming convention:
- **Jekyll**: `YYYY-MM-DD-slug.md` (date prefix required)
- **All others**: `slug.md` (lowercase, hyphens for spaces, no special characters)

Write to `<content_root>/<default_subdirectory>/<filename>.md`.

For Jekyll drafts: write to `<content_root>/../_drafts/<slug>.md` (no date prefix needed in `_drafts/`).

Tell the user the file path.

### 11. Update Source Log Metadata

Edit the source log(s) in `<things_path>/logs/` to record that a post was created. Add to the log's frontmatter:

```yaml
blog_post: "<path to generated post>"
blog_post_date: <today's date>
```

This prevents the same log from being surfaced as "unused" in future runs.

### 12. Handle Git Workflow

Before committing, pull latest changes from the remote (if one exists) to avoid conflicts:

```bash
git -C <content_root> pull --rebase 2>/dev/null || true
```

Based on the mark-my-words `git_workflow` config setting:

- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this post?" with options: Yes (commit + push), Commit only (no push), No (skip git)
- **`auto`**: Automatically `git add`, `git commit -m "Add post: <title> (from things)"`, and `git push`
- **`manual`**: Tell the user the file has been written and they can commit when ready

When committing, `git add` both the post file and any media files added to the media directory.

Only do git operations if the content is in a git repository.

### 13. Suggest Related Posts

Based on the source log's tags and skills, check if other logs could make good companion posts:

> Based on your tags, these logs could make good follow-up posts:
> - "<log title>" — <potential angle>
> - "<log title>" — <potential angle>
>
> Run `/mark-my-words:from-things <filename>` to draft one.
