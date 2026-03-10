# mark-my-words

Write, manage, and publish blog posts on any markdown-based platform - Quartz, Hugo, Jekyll, Astro, Eleventy, Docusaurus, and Zola.

Handles the full lifecycle - drafting new posts, editing existing ones, managing tags and draft status, and publishing. Works with both local directories and remote git repos. Each platform gets native support for its frontmatter format, content features, and conventions. If you use i-did-a-thing, the `from-things` skill can turn your evidence logs into blog posts, pulling in the narrative structure, metrics, and reflection you've already captured.

## Installation

```
/plugin install mark-my-words@brenna-plugs
```

## Setup

Configure your blog platform, source location (local path or git remote), content directory, default tags, and git workflow preferences. Writes plugin-specific preferences to `~/.things/mark-my-words/preferences.json`.

```
/setup-mmw
```

Requires things to be set up first (`/things:setup-things`).

### Supported Platforms

| Platform | Frontmatter | Callouts | Mermaid | Key Feature |
|----------|-------------|----------|---------|-------------|
| **Quartz** | YAML | `> [!type]` | Native | Obsidian-compatible wikilinks |
| **Hugo** | YAML | - | Theme-dependent | Figure shortcodes, ref links |
| **Jekyll** | YAML | - | Plugin-dependent | Date-prefixed filenames, `_drafts/` |
| **Astro** | YAML | - | Plugin-dependent | Content collections, `pubDate` |
| **Eleventy** | YAML | - | Plugin-dependent | Flexible structure, tag collections |
| **Docusaurus** | YAML | `:::type` | Official plugin | MDX, rich author metadata |
| **Zola** | TOML `+++` | - | Theme-dependent | Taxonomies, page bundles |

## Skills

**New Post** - Write a new blog post. Walks you through title, length, key points, tags, and draft status, then generates a platform-compatible post with proper frontmatter and structure.

```
/new-post-mmw [topic or idea]
```

**Update Post** - Edit an existing post. Supports targeted section edits, appending content, full rewrites, and metadata-only changes. Preserves your original voice for partial edits.

```
/update-post-mmw [filename or search term]
```

**Manage Posts** - List all posts with metadata, view and publish drafts, and organize tags across your blog (add, remove, rename tags in bulk).

```
/manage-post-mmw [list, drafts, publish, tags]
```

**Create Voice** - Build a voice profile from your writing samples. Analyzes your tone, sentence patterns, vocabulary, and habits to create a compact style guide that makes posts sound like you.

```
/create-voice-mmw [voice name]
```

**Update Voice** - Refine an existing voice profile with new samples, manual edits, or a full regeneration.

```
/update-voice-mmw [voice name]
```

**From Things** - Transform i-did-a-thing evidence logs into blog posts. Finds candidates via the JSON index by blog potential, pulls in the Blog Seed hook, narrative structure, and metrics. You choose the angle - tutorial, retrospective, or one of the angles suggested in the log itself.

```
/from-things-mmw [log filename or search query]
```

**Add Media** - Add images, diagrams, and video embeds to an existing post. Analyzes your post for visual opportunities and walks you through each one - generate diagrams, provide your own images, search the web, or embed videos.

```
/add-media-mmw [post filename or search term]
```

**Migrate Data** - Move mark-my-words data from the old flat `~/.things/` layout to the per-plugin directory structure. Moves voice profiles and renames the blog working directory. Run `/things:setup-things` first if config.json doesn't exist yet.

```
/migrate-mmw [--dry-run]
```

## How It Works

Posts are written in your platform's native markdown format with full frontmatter. Each platform has a dedicated template (`platforms/<name>.md`) that defines its frontmatter fields, content syntax (callouts, code blocks, image format), and conventions. The plugin loads the right template based on your config and follows it throughout.

The plugin handles git workflows (auto, ask, or manual) based on your configuration. Rich media - Mermaid diagrams, images, GIFs, and video embeds - can be added during writing or to existing posts, using your platform's native syntax.

The `from-things` skill bridges your i-did-a-thing evidence logs into narrative blog posts - it uses the JSON index to find high-potential entries, then transforms structured log data into an engaging first-person story.

## Configuration

Settings use the convention-path config system:

- **Global config**: `~/.things/config.json` (shared across all plugins)
- **Plugin preferences**: `~/.things/mark-my-words/preferences.json` (platform, content dir, git workflow, etc.)

The preferences file includes a `platform` field that determines which platform template to use. Run `/setup-mmw` to reconfigure blog settings.

### Voice Profiles

Voice profiles live at `~/.things/mark-my-words/voices/<name>.md` and teach mark-my-words how you write. They're stored in the .things repo for cross-machine sync. Create profiles from your existing writing samples, then set a default voice so all new posts match your style. You can create multiple profiles and switch between them when creating posts.

### Media Support

Configure a `media_dir` in setup to enable image management. When set, the writing and editing skills can add diagrams, download and reference images, and embed videos. Auto-suggest mode detects visual opportunities as you write. AI image generation is available as an opt-in when MCP tools are present.

## Related Plugins

- **things** - Manages `.things/` infrastructure that mark-my-words depends on
- **i-did-a-thing** - Log professional experiences that feed into blog posts via `from-things`
- **think-like** - Apply expert thinking profiles that can inform your writing perspective
- **what-did-you-do** - Practice talking about your work in interviews
