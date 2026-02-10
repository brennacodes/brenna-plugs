---
name: add-media
description: Add images, diagrams, and video embeds to an existing blog post.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[post filename or search term]"
---

# Add Media to Blog Post

You are adding rich media — Mermaid diagrams, images, and video embeds — to an existing blog post. Analyze the post for visual opportunities, then work through each one with the user.

Consult `references/media-guide.md` for visual detection patterns, Mermaid syntax, file naming conventions, alt text guidelines, and placement rules.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` for blog settings. If missing:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

Resolve `media_dir`: if configured, compute the full path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`). If `media_dir` is null, ask the user:

> No media directory is configured. You can still add inline content like Mermaid diagrams and video embeds. For images, would you like to:
> - Provide a one-time media directory path for this session
> - Continue without image support (diagrams and embeds only)

If they provide a path, use it for this session but don't update the config file.

### 2. Resolve Content Location

- **If `source_type: remote`**: Look for the working directory at `.mark-my-words-workdir/`. If not cloned, clone it. If cloned, pull latest.
- **If `source_type: local`**: Use `<local_path>/<content_dir>/`.

### 3. Find the Post

- **If `$ARGUMENTS` was provided**: Search for matching posts by:
  - Filename match (glob for `*<argument>*.md`)
  - Title match (grep for the argument in frontmatter `title:` fields)
  - Content match if no filename/title hits
- **If no arguments**: List the 10 most recently modified `.md` files in the content directory with their titles and dates.

If multiple posts match, use AskUserQuestion to let the user select which one. Show title, date, and filename for each.

If no posts match, tell the user and suggest checking the filename or trying a different search term.

### 4. Analyze the Post

Read the full post content and scan for visual opportunities using the detection patterns from `references/media-guide.md`.

Look for:
- **Diagram candidates**: processes, architectures, workflows, decision logic, state changes, request/response flows, data models
- **Image candidates**: UI references, visual concepts, results/screenshots, before/after comparisons
- **Table candidates**: comparisons, structured data, feature lists
- **Video candidates**: references to talks, demos, tutorials, recordings

Present findings organized by section:

> **Visual opportunities found:**
>
> **"How Authentication Works" (line 24)**
> - Diagram: the login flow described here would work well as a sequence diagram
>
> **"Architecture Overview" (line 45)**
> - Diagram: the three-service architecture could be a flowchart with subgraphs
> - Image: the system diagram mentioned could be a screenshot or architecture image
>
> **"Results" (line 78)**
> - Image: before/after comparison of the dashboard redesign
>
> **"Demo" (line 92)**
> - Video: the conference talk mentioned could be embedded

Use AskUserQuestion to let the user choose:
- Accept all suggestions
- Pick and choose which ones to add
- Add their own images/media instead
- Skip specific suggestions

### 5. Process Media

Work through each selected item one at a time.

#### Mermaid Diagrams

1. Read the relevant section carefully
2. Generate Mermaid diagram code following the syntax in `references/media-guide.md`
3. Show the diagram code to the user for review
4. Use AskUserQuestion: "Does this diagram look right?" — Looks good / Revise it / Skip this one
5. If approved, use Edit to insert the diagram after the text that introduces the concept
6. If revision requested, adjust and show again

#### Images (User-Provided)

1. Ask for the file path or URL and a description
2. Generate a descriptive kebab-case filename if the original name is generic
3. Generate concise alt text from the description
4. If it's a local file: copy to media dir with `cp`
5. If it's a URL: download with `curl -L -o <media_dir>/<filename> <url>`
6. Insert the image reference using wikilink syntax: `![[filename|alt text]]`
7. Place it following the placement rules in `references/media-guide.md`

#### Images (Web Search)

1. Ask the user for the topic or description of what they're looking for
2. Use WebSearch to find relevant images (search `site:unsplash.com <topic>` or `creative commons <topic> photo`)
3. Present 2-3 options with descriptions
4. Download the selected image with `curl -L -o <media_dir>/<descriptive-filename> <url>`
5. Generate alt text and insert the reference
6. Always include alt text describing the image content

#### Images (AI Generated)

Only offer this if `ai_image_generation: true` in config.

1. Check if image generation tools are available (e.g., Hugging Face MCP tools)
2. If no tools available: tell the user and offer alternatives (web search, placeholder, skip)
3. If tools available: ask the user to describe what they want
4. Use AskUserQuestion to confirm before generating: "Generate an image of [description]?"
5. Generate the image and save to media dir
6. Insert the reference with alt text

If `ai_image_generation` is false or not set, do not offer this option.

#### Video Embeds

1. Ask for the video URL (YouTube or Vimeo)
2. Extract the video ID from the URL
3. Generate the appropriate iframe embed:
   - YouTube: `<iframe width="560" height="315" src="https://www.youtube.com/embed/<ID>" title="<title>" frameborder="0" allowfullscreen></iframe>`
   - Vimeo: `<iframe width="560" height="315" src="https://player.vimeo.com/video/<ID>" title="<title>" frameborder="0" allowfullscreen></iframe>`
4. Ask the user for a title/description for the video
5. Insert a context sentence before the embed and a fallback link after it
6. Use Edit to place the embed in the post

### 6. Review Changes

After processing all selected media, read the updated post and show the user a summary:

> **Media added:**
> - Sequence diagram in "How Authentication Works" (line 26)
> - Architecture flowchart in "Architecture Overview" (line 48)
> - Downloaded `dashboard-before-after.png` (from unsplash.com)
> - YouTube embed in "Demo" section

Use AskUserQuestion:
- Done — I'm happy with the changes
- Add more — I want to add additional media
- Undo last — remove the last media item added
- Start over — revert all changes and try again

If "Add more": go back to Step 4 to re-analyze (the post now has some media, so the analysis will be different).
If "Undo last": use Edit to remove the last inserted media item and offer to continue or stop.
If "Start over": re-read the original post content (from git or backup) and return to Step 4.

### 7. Handle Git Workflow

Based on the `git_workflow` config setting:

- **`ask`**: Use AskUserQuestion — "Would you like to commit and push these media changes?" with options: Yes (commit + push), Commit only, No
- **`auto`**: Automatically `git add` the post and any media files, `git commit -m "Add media to post: <title>"`, and `git push`
- **`manual`**: Tell the user the files have been updated and they can commit when ready

When committing, include both the updated post file and any new files in the media directory.
