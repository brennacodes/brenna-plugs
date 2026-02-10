# mark-my-words

Write, manage, and publish blog posts on Quartz static sites.

Handles the full lifecycle — drafting new posts, editing existing ones, managing tags and draft status, and publishing. Works with both local Quartz directories and remote git repos. If you use i-did-a-thing, the `from-things` skill can turn your accomplishment logs into blog posts, pulling in the narrative structure, metrics, and reflection you've already captured.

## Installation

```bash
claude plugin:add mark-my-words
```

## Setup

Configure your Quartz blog source (local path or git remote), content directory, author info, default tags, and git workflow preferences.

```
/mark-my-words:setup
```

## Skills

**New Post** — Write a new blog post. Walks you through title, length, key points, tags, and draft status, then generates a Quartz-compatible post with proper frontmatter and structure.

```
/mark-my-words:new-post [topic or idea]
```

**Update Post** — Edit an existing post. Supports targeted section edits, appending content, full rewrites, and metadata-only changes. Preserves your original voice for partial edits.

```
/mark-my-words:update-post [filename or search term]
```

**Manage Posts** — List all posts with metadata, view and publish drafts, and organize tags across your blog (add, remove, rename tags in bulk).

```
/mark-my-words:manage-post [list, drafts, publish, tags]
```

**Create Voice** — Build a voice profile from your writing samples. Analyzes your tone, sentence patterns, vocabulary, and habits to create a compact style guide that makes posts sound like you.

```
/mark-my-words:create-voice [voice name]
```

**Update Voice** — Refine an existing voice profile with new samples, manual edits, or a full regeneration.

```
/mark-my-words:update-voice [voice name]
```

**From Things** — Transform i-did-a-thing accomplishment logs into blog posts. Pulls in the Blog Seed hook, narrative structure, and metrics from your logs. You choose the angle — tutorial, retrospective, or one of the angles suggested in the log itself.

```
/mark-my-words:from-things [log filename or search query]
```

## How It Works

Posts are written in Quartz-compatible markdown with full frontmatter (title, date, description, tags, draft status, author). The plugin handles git workflows (auto, ask, or manual) based on your configuration.

The `from-things` skill bridges your i-did-a-thing accomplishment logs into narrative blog posts — choose an angle, and it transforms structured log data into an engaging first-person story.

## Configuration

Settings are stored in `.claude/mark-my-words.local.md` and include source type, content directory, author, default tags, git workflow (auto, ask, or manual), and default voice profile. Run setup again to reconfigure.

### Voice Profiles

Voice profiles live at `.claude/voices/<name>.md` and teach mark-my-words how you write. Create profiles from your existing writing samples, then set a default voice so all new posts match your style. You can create multiple profiles and switch between them when creating posts.

## Related Plugins

- **i-did-a-thing** — Log accomplishments that feed into blog posts via `from-things`
- **what-did-you-do** — Practice talking about your work in interviews
