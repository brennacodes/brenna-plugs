---
name: migrate-things
description: "Migrate from per-plugin configs to centralized shared config. Run this after updating to v3.0.0."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[--dry-run]"
---

# Migrate to Centralized Shared Config

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Guide the user through migrating from per-plugin configs (`<home>/.claude/i-did-a-thing.local.md`, `<home>/.claude/what-did-you-do.local.md`, `<home>/.claude/mark-my-words.local.md`) to the centralized shared config system (`<home>/.claude/things.local.md` + `<things_path>/config.yml`), including seeding shared personas and company profiles.

## Steps

### 1. Check if Already Migrated

Check if `<home>/.claude/things.local.md` exists. If it does, read it to get `things_path` (if `things_path` starts with `~`, replace with `<home>`) and check if `<things_path>/config.yml` also exists.

If both exist, check for plugin cache updates before reporting:

1. Check if `<home>/.claude/plugins/cache/brenna-plugs/` exists. If yes:
   - List plugin directories: `ls <home>/.claude/plugins/cache/brenna-plugs/`
   - For each plugin in the cache, find the latest version: `ls <home>/.claude/plugins/cache/brenna-plugs/<plugin>/ | sort -V | tail -1`
   - Read `<home>/.claude/plugins/installed_plugins.json`
   - For each `<plugin>@brenna-plugs` entry, compare installed version to latest cached version
   - If a newer version exists: update `installPath` to `<home>/.claude/plugins/cache/brenna-plugs/<plugin>/<latest>`, `version` to `<latest>`, and `lastUpdated` to current ISO 8601 timestamp
   - If `$ARGUMENTS` contains `--dry-run`, show what would change but don't write
   - Otherwise write the updated JSON back

2. Then report:

> Already using the centralized shared config. No migration needed.
>
> - Bootstrap: `<home>/.claude/things.local.md`
> - Config: `<things_path>/config.yml`
>
> [If any plugin versions were updated: list each plugin with old → new version, then: "**Restart Claude Code** to use the updated plugin versions."]
> [If all current: "All brenna-plugs plugins already at latest cached versions."]
>
> Run `/i-did-a-thing:setup` to reconfigure.

Then stop.

### 2. Detect Existing Configs

Read whichever of these exist:
- `<home>/.claude/i-did-a-thing.local.md`
- `<home>/.claude/what-did-you-do.local.md`
- `<home>/.claude/mark-my-words.local.md`

If none exist:

> No existing configs found. Run `/i-did-a-thing:setup` to set up from scratch — it uses the new centralized config automatically.

Then stop.

### 3. Show Migration Plan

Tell the user what will happen:

> **Migration Plan**
>
> I'll merge your existing configs into a centralized system:
>
> 1. Create `<home>/.claude/things.local.md` (machine-local bootstrap)
> 2. Create `<things_path>/config.yml` (full config, git-tracked)
> 3. Generate `index.json` from your logs (replaces `index.md`)
> 4. Generate `tags.json` for quick tag lookups
> 5. Regenerate arsenal files from scratch
> 6. Copy voice profiles to `<things_path>/voices/` (if any exist)
> 7. Seed shared personas to `<things_path>/personas/`
> 8. Seed shared company profiles to `<things_path>/companies/`
> 9. Rename old configs to `.bak` (non-destructive)
>
> Your logs and existing data are not modified.

Use AskUserQuestion: **Ready to proceed?**
- Yes — let's do it
- Dry run — show me what would change without writing anything

If `$ARGUMENTS` contains `--dry-run`, treat as dry run mode.

### 4. Detect GitHub Username

Try to detect the username:

```bash
gh api user -q .login 2>/dev/null || git config user.name
```

Use AskUserQuestion to confirm: **Is this your GitHub username: `<detected>`?**
- Yes
- No — I'll provide it

### 5. Extract things_path

Read `things_path` from the i-did-a-thing config. If not found there, check what-did-you-do config. If still not found:

Use AskUserQuestion: **Where is your .things directory?**
- `~/.things`
- Custom path

### 6. Sync Existing Things Repo

Check if `<things_path>` is already a git repo with a remote:

```bash
git -C <things_path> rev-parse --is-inside-work-tree 2>/dev/null
```

If yes, check for a remote:

```bash
git -C <things_path> remote -v
```

If a remote exists, pull latest before making any changes:

```bash
git -C <things_path> pull --rebase
```

If the pull fails due to conflicts, tell the user:

> Your things repo has unpushed local changes that conflict with the remote. Please resolve them manually before running migration:
> ```
> cd <things_path>
> git status
> ```

Then stop.

If `<things_path>` is not a git repo yet, that's fine — step 17 will handle initializing it if the user configured a remote.

### 7. Merge Config Fields

Collect fields from all existing configs:

**From i-did-a-thing config:**
- `things_path`, `git_remote`, `git_branch`, `git_workflow`
- `current_role`, `target_roles`, `career_direction`
- `building_skills`, `aspirational_skills`
- `default_tags`

**From what-did-you-do config** (if exists):
- `follow_up_depth`, `default_stage`, `trusted_sources`

**From mark-my-words config** (if exists):
- `source_type`, `repo_url`, `repo_branch`, `content_dir`
- `default_subdirectory`, `default_tags` (as blog tags)
- `git_workflow` (as blog git_workflow)
- `default_voice`, `media_dir`, `auto_suggest_visuals`, `ai_image_generation`

**Detect author name:**
Use the `default_author` from mark-my-words config, or the GitHub username capitalized.

### 8. Write Bootstrap Config

Write `<home>/.claude/things.local.md`:

```yaml
things_path: <things_path>
github_username: <username>
```

### 9. Write Full Config

Write `<things_path>/config.yml` with all merged fields using the schema from `../setup/references/things-setup.md`.

For any plugin-specific section where the plugin wasn't previously configured, write sensible defaults.

### 10. Copy Voice Profiles

Check if `<home>/.claude/voices/` exists and has any `.md` files.

If yes:
1. Create `<things_path>/voices/` directory
2. Copy each voice file from `<home>/.claude/voices/` to `<things_path>/voices/`
3. Tell the user: "Copied N voice profile(s) to `<things_path>/voices/`"

### 11. Seed Shared Personas

Create the shared personas directory and seed default persona files:

```bash
mkdir -p <things_path>/personas
mkdir -p <things_path>/companies
```

Check if the what-did-you-do plugin is installed by looking for `<plugin_root>/../what-did-you-do/personas/`. If it exists, copy each persona file to `<things_path>/personas/` **only if not already present** (never overwrite user customizations):

```bash
for f in <plugin_root>/../what-did-you-do/personas/*.md; do
  dest="<things_path>/personas/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
```

Similarly, seed company profiles:

```bash
for f in <plugin_root>/../what-did-you-do/companies/*.yaml; do
  dest="<things_path>/companies/$(basename "$f")"
  [ -f "$dest" ] || cp "$f" "$dest"
done
```

Tell the user how many personas and companies were seeded.

### 12. Generate JSON Index and Arsenal

Run the rebuild script:

```bash
python3 <plugin_root>/scripts/rebuild-data.py <things_path>
```

Capture the output to show the user entry and tag counts.

### 13. Show Summary

> **Migration complete!**
>
> - Entries: N logs indexed
> - Tags: N unique tags
> - Arsenal: N skill files regenerated
> - Voices: N profiles copied (or "none to copy")
> - Personas: N seeded to `<things_path>/personas/`
> - Companies: N seeded to `<things_path>/companies/`
>
> **New config locations:**
> - Bootstrap: `<home>/.claude/things.local.md`
> - Full config: `<things_path>/config.yml`
> - Index: `<things_path>/index.json`
> - Tags: `<things_path>/tags.json`

### 14. Verify with User

Ask the user to spot-check:

> Let me show you a few entries from the new index to verify they look correct.

Show 2-3 entries from `index.json` with their key fields.

Use AskUserQuestion: **Do these look correct?**
- Yes — everything looks good
- Something's off — let me check

If something's off, help the user investigate.

### 15. Rename Old Configs

Rename the old config files to `.bak`:

```bash
mv ~/.claude/i-did-a-thing.local.md ~/.claude/i-did-a-thing.local.md.bak 2>/dev/null || true
mv ~/.claude/what-did-you-do.local.md ~/.claude/what-did-you-do.local.md.bak 2>/dev/null || true
mv ~/.claude/mark-my-words.local.md ~/.claude/mark-my-words.local.md.bak 2>/dev/null || true
```

Tell the user: "Old configs renamed to `.bak` — you can delete them once you're confident everything works."

### 16. Update Plugin Cache

Check if `<home>/.claude/plugins/cache/brenna-plugs/` exists. If not, skip to next step.

1. List all plugin directories under the cache:
   ```bash
   ls <home>/.claude/plugins/cache/brenna-plugs/
   ```

2. For each plugin found, get the latest cached version:
   ```bash
   ls <home>/.claude/plugins/cache/brenna-plugs/<plugin>/ | sort -V | tail -1
   ```

3. Read `<home>/.claude/plugins/installed_plugins.json`

4. For each `<plugin>@brenna-plugs` entry, compare the installed version to the latest cached version. If a newer version exists in the cache:
   - Update `installPath` to `<home>/.claude/plugins/cache/brenna-plugs/<plugin>/<latest>`
   - Update `version` to `<latest>`
   - Update `lastUpdated` to current ISO 8601 timestamp

5. If in dry-run mode, show what would change but do not write. Otherwise, write the updated JSON back to `<home>/.claude/plugins/installed_plugins.json`.

6. Report:
   - If versions were updated: list each plugin and old → new version, then: "**Restart Claude Code** to use the updated plugin versions."
   - If all current: "All brenna-plugs plugins already at latest cached versions."

### 17. Handle Git

Read the `git_workflow` from the new config.

- **`auto`**: Commit and push the new config files, index.json, tags.json, and arsenal
- **`ask`**: Ask the user if they want to commit and push
- **`manual`**: Tell the user what files to commit

### 18. Done

> Migration complete! All four plugins now share a single config at `<things_path>/config.yml`.
>
> - `/i-did-a-thing:thing-i-did` — Log accomplishments (hooks auto-rebuild index + arsenal)
> - `/i-did-a-thing:construct-resume` — Build resumes from `index.json`
> - `/what-did-you-do:practice` — Practice with your arsenal
> - `/what-do-you-know:explore` — Deep-dive into a topic from your experience
> - `/mark-my-words:from-things` — Turn logs into blog posts
