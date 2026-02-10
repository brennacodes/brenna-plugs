---
name: create-voice
description: "Create a voice profile from writing samples — teach mark-my-words how you actually write"
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[voice name]"
---

# Create Voice Profile

You are creating a voice profile from the user's writing samples. The profile will be a compact style guide that captures how they write — not generic AI voice, their actual voice.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

### 2. Ensure Voices Directory

Check if `.claude/voices/` exists. If not, create it.

### 3. Get Voice Name

If `$ARGUMENTS` was provided, use it as the voice name (convert to kebab-case: lowercase, hyphens for spaces, no special characters).

If no arguments, use AskUserQuestion to ask:

> **What should this voice profile be called?**

Suggest names based on common patterns: `casual-tech`, `professional`, `personal-blog`, `tutorial-voice`. The name becomes the filename and identifier.

### 4. Check for Existing Profile

Check if `.claude/voices/<name>.md` already exists. If it does, tell the user:

> A voice profile named "<name>" already exists. Use `/mark-my-words:update-voice <name>` to refine it, or choose a different name.

Then use AskUserQuestion to offer:
- Choose a different name
- Overwrite the existing profile

If they want a different name, go back to Step 3.

### 5. Get Description

Use AskUserQuestion:

> **Describe this voice in one sentence.** What does it sound like? (e.g., "Conversational technical writing with dry humor" or "Direct and opinionated, like explaining something to a friend")

### 6. Gather Writing Samples

Use AskUserQuestion:

> **How would you like to provide writing samples?**
> - Point to files — I'll give you file paths or a glob pattern
> - Paste text — I'll paste samples directly into the chat
> - Both — files and pasted text

You need enough samples to identify patterns. Aim for at least 2-3 samples, ideally 1000+ words total.

#### If "Point to files":

Use AskUserQuestion to get file paths or a glob pattern (e.g., `content/blog/*.md`, or specific paths).

Use Glob to find matching files. Read each file. Track the source info:
```yaml
- type: file
  path: <absolute path>
```
For glob patterns, track as:
```yaml
- type: glob
  pattern: "<pattern>"
  count: <number of files matched>
```

#### If "Paste text":

Use AskUserQuestion to ask for their writing sample. Ask for a label for reference:

> **What's this sample from?** (e.g., "Blog post about React hooks", "README I wrote last week")

Track the source:
```yaml
- type: paste
  label: "<user's label>"
```

Ask if they have more samples. Repeat until they're done.

#### If "Both":

Do both flows above.

**Important:** Do not fetch URLs. If the user provides a URL, tell them:

> Voice profiles work with local files and pasted text only — no URL fetching. You can paste the content directly or save it to a file first.

### 7. Analyze and Distill

Read all the gathered samples carefully. Analyze the writing for patterns across the six profile sections defined in `references/voice-profile-format.md`:

1. **Tone & Register** — formality, emotional range, reader relationship
2. **Sentence Patterns** — rhythm, length, distinctive structures
3. **Vocabulary & Diction** — word choice, technical level, characteristic phrases
4. **Rhetorical Habits** — how they explain, persuade, use humor
5. **Structural Preferences** — intros, sections, conclusions, formatting
6. **Things to Avoid** — anti-patterns that would break the voice

Be specific and concrete. Pull actual examples from the samples. Don't be generic — "uses humor" is useless, "drops self-deprecating asides in parentheses after technical claims" is useful.

### 8. Present for Review

Show the user the generated profile and ask:

> **How does this look?**
> - Save it — looks good
> - Adjust it — I want to tweak some sections
> - Start over — try again with different samples

#### If "Save it":
Continue to Step 9.

#### If "Adjust it":
Use AskUserQuestion to find out what to change. Update the profile and present again.

#### If "Start over":
Go back to Step 6.

### 9. Save the Profile

Write the profile to `.claude/voices/<name>.md` using the format from `references/voice-profile-format.md`. Include:

- Frontmatter with name, description, created date (today), last_updated (today), and sample_sources
- All six body sections with the distilled analysis

### 10. Set as Default?

Use AskUserQuestion:

> **Should "<name>" be your default voice for new posts?**
> - Yes — use this voice by default
> - No — I'll pick a voice when I need one

If yes, read `.claude/mark-my-words.local.md`, update the `default_voice` field to `<name>`, and write the file back.

### 11. Confirm

Tell the user:

> Voice profile "<name>" saved to `.claude/voices/<name>.md`.

If set as default:

> It's now your default voice — new posts will use this style automatically.

Otherwise:

> You can use it by picking it when creating a post, or set it as default later by updating `default_voice` in your config.
>
> Run `/mark-my-words:update-voice <name>` to refine it with more samples.
