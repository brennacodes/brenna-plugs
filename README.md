# brenna-plugs

A Claude Code plugin marketplace by [brennacodes](https://github.com/brennacodes).

## Installation

First, add the marketplace:

```bash
claude marketplace:add https://github.com/brennacodes/brenna-plugs
```

Then install plugins:

```bash
claude plugin:add mark-my-words
```

```bash
claude plugin:add i-did-a-thing
```

Or install directly from a local clone:

```bash
claude plugin:add <path_to_brenna_plugs>/plugins/mark-my-words
```

```bash
claude plugin:add <path_to_brenna_plugs>/plugins/i-did-a-thing
```

## Plugins

### mark-my-words

Create and manage blog posts for Quartz static sites with guided interview workflows.

**Setup** — Configure for your Quartz blog — source location, author info, and preferences.

```
/mark-my-words:setup
```

**New Post** — Create a new blog post via guided interview.

```
/mark-my-words:new-post [topic or idea]
```

**Update Post** — Update an existing blog post.

```
/mark-my-words:update-post [filename or search term]
```

**Manage Posts** — List, search, and manage posts — drafts, tags, and metadata.

```
/mark-my-words:manage-post [list, drafts, publish, tags]
```

**From Things** — Turn i-did-a-thing accomplishment logs into blog posts.

```
/mark-my-words:from-things [log filename or search query]
```

### i-did-a-thing

A build-me-up tool that helps you log accomplishments, practice interviews, and construct tailored resumes from your personal arsenal of wins.

**Setup** — Configure plugin settings — .things directory, git remote, goals, and preferences.

```
/i-did-a-thing:setup [reconfigure]
```

**Log a Thing** — Log an accomplishment through a guided interview.

```
/i-did-a-thing:thing-i-did [brief description]
```

**Interview Me** — Practice interview questions with coaching powered by your accomplishments.

```
/i-did-a-thing:interview-me [behavioral|technical|leadership|situational]
```

**Build Resume** — Build a tailored resume matched against a specific job listing.

```
/i-did-a-thing:construct-resume [job listing URL or text]
```
