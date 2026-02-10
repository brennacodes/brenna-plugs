---
name: update-voice
description: "Refine an existing voice profile — add samples, adjust sections, or regenerate"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[voice name]"
---

# Update Voice Profile

You are helping the user refine an existing voice profile. They might want to add new writing samples, manually adjust sections, or regenerate the whole profile.

## Steps

### 1. Load Configuration

Read `.claude/mark-my-words.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/mark-my-words:setup` first to configure your blog settings.

Then stop.

### 2. List Available Voices

Use Glob to find all `.md` files in `.claude/voices/`. If none exist:

> No voice profiles found. Run `/mark-my-words:create-voice` to create one.

Then stop.

### 3. Select Voice

If `$ARGUMENTS` was provided, look for a matching profile in `.claude/voices/<argument>.md`. If no exact match, try fuzzy matching against available voice names.

If no arguments or no match, use AskUserQuestion to present the available voices. Show each voice's name and description (read from frontmatter).

### 4. Show Current Profile

Read the selected voice profile from `.claude/voices/<name>.md`. Display it to the user in full — frontmatter and all body sections.

### 5. Choose Update Mode

Use AskUserQuestion:

> **How do you want to update this voice?**
> - Add samples — feed in more writing to sharpen the profile
> - Manual adjust — edit specific sections yourself
> - Regenerate — rebuild from scratch using all sources (existing + new)

### 6. Apply Update

#### If "Add samples":

Follow the same sample-gathering flow as create-voice Step 6 (file paths, paste, or both — no URLs).

After gathering new samples, re-analyze all sections in the context of both the existing profile and the new samples. The profile should evolve, not be replaced — new patterns get added, existing ones get refined or confirmed.

Update the `sample_sources` list in frontmatter to include the new sources. Update `last_updated` to today's date.

Use Edit to update changed sections. Preserve sections that didn't change.

#### If "Manual adjust":

Use AskUserQuestion to ask which section(s) to update. List the six sections:
1. Tone & Register
2. Sentence Patterns
3. Vocabulary & Diction
4. Rhetorical Habits
5. Structural Preferences
6. Things to Avoid

For each selected section, show the current content and use AskUserQuestion to get the user's changes. They can describe what to add, remove, or modify.

Use Edit to apply the changes. Update `last_updated` to today's date.

#### If "Regenerate":

Gather new samples using the same flow as create-voice Step 6. Combine with existing `sample_sources` from the current profile.

Read all available sources (both old file paths and new samples). Re-analyze everything from scratch following the format in `../create-voice/references/voice-profile-format.md`.

Update `last_updated` to today's date. Keep the original `created` date.

Use Write to replace the profile file.

### 7. Present Result

Show the updated profile and ask:

> **How does the updated profile look?**
> - Save it — looks good
> - Keep editing — I want to change more
> - Revert — go back to the previous version

#### If "Save it":
Confirm the profile has been saved.

#### If "Keep editing":
Go back to Step 5.

#### If "Revert":
Write back the original profile content (keep a copy in memory before making changes). Tell the user the profile has been reverted.

### 8. Confirm

Tell the user:

> Voice profile "<name>" updated.

Check if this voice is set as the `default_voice` in config. If so:

> This is your default voice — new posts will use the updated style.

If not:

> Run `/mark-my-words:create-voice` to create additional profiles, or update `default_voice` in your config to make this the default.
