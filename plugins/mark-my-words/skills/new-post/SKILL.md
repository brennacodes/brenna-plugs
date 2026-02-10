---
name: new-post
description: Create a new blog post for your Quartz site via guided interview.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[topic or idea]"
---

# Create New Blog Post

You are creating a new blog post for the user's Quartz-powered blog. Use a structured interview to gather requirements, then generate a well-crafted post.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

#### Load Voice Profile

If the config has a `default_voice` set (not null), read the voice profile from `.claude/voices/<default_voice>.md`. If the file doesn't exist, warn the user that their default voice profile is missing and continue without a voice.

Also check if any voice profiles exist in `.claude/voices/` using Glob. Store this for the interview step.

#### Resolve Media Directory

If the config has `media_dir` set (not null), resolve the full media path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`). Store this path for use in the writing and media processing steps.

### 2. Resolve Content Location

- **If `source_type: remote`**: Check if the repo is already cloned locally. Look for a working directory at `.mark-my-words-workdir/` relative to the project root. If not cloned, clone it:
  ```
  git clone --branch <repo_branch> <repo_url> .mark-my-words-workdir
  ```
  If already cloned, pull latest changes.
  The content root is `.mark-my-words-workdir/<content_dir>/`.

- **If `source_type: local`**: The content root is `<local_path>/<content_dir>/`.

### 3. Scan Existing Posts

Use Glob and Grep to scan the content directory:
- Find all `.md` files in the target subdirectory
- Extract existing tags from frontmatter across posts (look for `tags:` in YAML frontmatter)
- Note the directory structure for suggesting where to place the new post
- This informs tag suggestions and helps maintain consistency

### 4. Interview the User

Use AskUserQuestion for each of these, adapting based on `$ARGUMENTS` if provided:

**Post title**: If `$ARGUMENTS` was provided, suggest a title based on it. Let the user accept, modify, or provide their own. Keep it concise and engaging.

**Target length**:
- Short (~500 words) — quick tip, TIL, brief note
- Medium (~1000 words) — tutorial, explanation, walkthrough
- Long (~2000+ words) — deep dive, comprehensive guide

**Key points/sections**: Ask what the post should cover. What are the main things the reader should learn or take away? Let the user describe in their own words.

**Tags**: Present a combined list of:
- Tags found in existing posts
- The user's `default_tags` from config
- Allow the user to pick multiple and/or add custom tags

**Target directory**: Show the default from config (`default_subdirectory`). Let them override if they want to put it elsewhere.

**Voice** (only if voice profiles exist in `.claude/voices/`):
- If a default voice is set, show it and ask if they want to use it, pick a different one, or skip voice for this post
- If no default is set, list available voices and let them pick one or skip
- If only one voice exists, just confirm they want to use it

**Draft status**:
- Publish immediately (`draft: false`)
- Save as draft (`draft: true`)

**Visuals** (only if `media_dir` is configured):
- "I have specific images (file paths or URLs)"
- "Find relevant images for me"
- "Generate Mermaid diagrams for visual concepts"
- "No visuals for this post"
- "Decide as we write"

If user provides images: collect paths/URLs and descriptions for processing in Step 5.5. If web search: note topics to search during writing. If Mermaid: actively generate diagrams where they fit during Step 5. If "decide as we write": activate auto-suggest behavior for this post regardless of the `auto_suggest_visuals` config setting.

### 5. Write the Post

Generate the blog post following the Quartz format reference in `references/quartz-format.md`. Key requirements:

- **Frontmatter**: Include `title`, `date` (today in YYYY-MM-DD format), `description` (1-2 sentence summary), `tags`, and `draft` status. Add `author` if configured.
- **Content quality**: If a voice profile was selected, follow its guidance for tone, sentence patterns, vocabulary, rhetorical habits, structure, and things to avoid. The voice profile takes precedence over generic style defaults — write as the profile describes, not in a generic "natural, engaging" voice. If no voice profile was selected, write in a natural, engaging voice. Use clear heading hierarchy (h2 for sections, h3 for subsections). Include code blocks with language identifiers when relevant.
- **Quartz features**: Use callouts (`> [!tip]`, `> [!warning]`, etc.) where they add value. Use proper syntax highlighting in code blocks.
- **Length**: Match the target length the user selected.
- **Structure**: Start with a brief intro, organize into logical sections based on the user's key points, end with a conclusion or summary.

#### Inline Visual Integration

When `auto_suggest_visuals` is true in config or the user chose "Decide as we write", integrate visuals as you draft each section. Consult `../add-media/references/media-guide.md` for detection patterns and placement rules.

- **Auto-detection**: As you write each section, detect:
  - Architecture descriptions → Mermaid flowchart with subgraphs
  - Workflows and processes → Mermaid flowchart or sequence diagram
  - Comparisons → table or side-by-side diagram
  - Data and metrics → formatted table or chart description
  - Visual concepts that need an actual image → placeholder comment: `<!-- TODO: add image of [description] -->`

- **User-provided images**: If the user gave file paths or URLs in the interview, reference them with wikilink syntax `![[filename.png|alt text]]` at the appropriate point in the narrative. Place images after the text that introduces the concept.

- **Web-searched images**: If the user asked to find images, use WebSearch (try `site:unsplash.com <topic>` or `creative commons <topic> photo`), then use WebFetch to verify the image URL works. Download with `curl -L -o` to the media dir using a descriptive kebab-case filename. Always include alt text.

- **AI-generated images** (only if `ai_image_generation: true` in config): Check for available image generation tools. If available, ask the user to confirm before generating. If no tools are available, gracefully skip and suggest a web search or placeholder instead.

#### Inline Links

Use WebSearch to find accurate URLs as you write. Link things inline where a reader would genuinely benefit from the reference:

- **Quoted or cited text** — always link to the original source. If you're quoting a person, article, talk, book, tweet, or documentation, the quote gets a link.
- **Tools, libraries, frameworks, protocols, specs** — link on first mention when the reader might want to explore them. A post about building with Astro should link to Astro's site; a post mentioning HTTP doesn't need a link to the HTTP spec.
- **People** — link when who they are matters to the post. If you're referencing someone's specific work, opinion, or contribution, link to their relevant page (personal site, talk, paper). Don't link household names just because they exist.
- **Companies and products** — only link when they're directly relevant to the post's substance, not just mentioned in passing. A post about migrating to Fly.io should link to Fly.io. A post that offhandedly mentions Amazon does not need a link to amazon.com.
- **Papers, blog posts, docs** — link when you're drawing on them or recommending them.

The goal is useful links, not comprehensive ones. When in doubt, skip it.

#### "Mentioned in this post" Section

After the post's conclusion, add a `---` horizontal rule followed by a section:

```markdown
---

## Mentioned in this post

- [Thing Name](https://example.com) — one-line description of what it is and why it's relevant
- [Another Thing](https://example.com) — brief context
```

Include items that a reader might want to explore further — tools, libraries, articles, people's work, specs, or projects that played a meaningful role in the post. This is a curated list, not an exhaustive index. Skip anything that was only mentioned in passing or that everyone already knows how to find. Aim for 3-8 items; if the post only has 1-2, skip the section entirely.

### 5.5. Process Media Files

Only run this step if the user requested images (provided files, web search, or AI generation) and `media_dir` is configured.

1. **Ensure media directory exists**: `mkdir -p <content_root>/<media_dir>`
2. **Copy local files**: For each user-provided local file, copy it to the media dir. Rename generic filenames (like `IMG_4523.png`, `Screenshot 2025-01-15.png`) to descriptive kebab-case names based on the image content or context.
3. **Download remote images**: For each URL collected during writing, download with `curl -L -o <media_dir>/<descriptive-filename> <url>`
4. **Update image references**: Ensure all image references in the post point to the correct relative paths using wikilink syntax: `![[filename.png|alt text]]`
5. **Summarize**: Tell the user what was processed — files copied, images downloaded, references updated.

### 6. Save the File

- Generate a filename from the title: lowercase, hyphens for spaces, no special characters (e.g., `my-first-post.md`)
- Write to `<content_root>/<target_subdirectory>/<filename>.md`
- Tell the user the file path

### 7. Handle Git Workflow

Based on the `git_workflow` config setting:

- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this post?" with options: Yes (commit + push), Commit only (no push), No (skip git)
- **`auto`**: Automatically `git add`, `git commit -m "Add post: <title>"`, and `git push`
- **`manual`**: Tell the user the file has been written and they can commit when ready

When committing, `git add` both the post file and any media files added to the media directory.

Only do git operations if the content is in a git repository.
