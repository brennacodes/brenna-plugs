# Migration Guide: v1/v2 → v3 Per-Plugin Structure

## Path Mappings

### Directory Moves

| Old Path (relative to .things/) | New Path (relative to .things/) | Notes |
|---|---|---|
| `logs/` | `i-did-a-thing/logs/` | All log .md files |
| `arsenal/` | `i-did-a-thing/arsenal/` | Auto-generated skill summaries |
| `resumes/` | `i-did-a-thing/resumes/` | Generated resume files |
| `index.json` | `i-did-a-thing/index.json` | Log index |
| `tags.json` | `i-did-a-thing/tags.json` | Tag counts |
| `voices/` | `mark-my-words/voices/` | Writing voice profiles |
| `personas/` | `shared/roles/` | Interview/learning personas |
| `companies/` | `shared/companies/` | Company profiles |
| `interview-prep/sessions/` | `what-did-you-do/sessions/` | Practice/mock sessions |
| `interview-prep/question-overrides/` | `what-did-you-do/questions/` | Custom question banks |
| `interview-prep/companies/` | `what-did-you-do/` | Company prep plans |
| `learning/sessions/` | `what-do-you-know/sessions/` | Explore/quiz sessions |
| `learning/study-plans/` | `what-do-you-know/study-plans/` | Learning plans |
| `~/.mark-my-words-workdir` | `~/.mark-my-words` | Blog repo clone (stays outside .things/) |

### Format Conversions

| Old File | New File | Conversion |
|---|---|---|
| `interview-prep/progress.md` | `what-did-you-do/progress.json` | Markdown dashboard → JSON |
| `learning/progress.md` | `what-do-you-know/progress.json` | Markdown dashboard → JSON |
| `learning/knowledge-map.md` | `what-do-you-know/knowledge-map.json` | Markdown categories → JSON |

---

## Config Conversion

### config.yml Field Mapping

| config.yml Field | New File | New Field |
|---|---|---|
| `github_username` | `config.json` | `github_username` |
| `things_repo` | `config.json` | `git.remote` |
| `things_branch` | `config.json` | `git.branch` |
| `git_workflow` | `config.json` | `git.workflow` |
| `author_name` | `shared/professional-profile.json` | `author_name` |
| `current_role` | `shared/professional-profile.json` | `current_role` |
| `target_roles` | `shared/professional-profile.json` | `target_roles` |
| `career_direction` | `shared/professional-profile.json` | `career_direction` |
| `building_skills` | `shared/professional-profile.json` | `building_skills` |
| `aspirational_skills` | `shared/professional-profile.json` | `aspirational_skills` |
| `logging.default_tags` | `i-did-a-thing/preferences.json` | `default_tags` |
| `interview_prep.follow_up_depth` | `what-did-you-do/preferences.json` | `follow_up_depth` |
| `interview_prep.default_stage` | `what-did-you-do/preferences.json` | `default_stage` |
| `interview_prep.trusted_sources` | `what-did-you-do/preferences.json` | `trusted_sources` |
| `learning.default_depth` | `what-do-you-know/preferences.json` | `default_depth` |
| `learning.default_persona` | `what-do-you-know/preferences.json` | `default_persona` |
| `learning.session_length` | `what-do-you-know/preferences.json` | `session_length` |
| `learning.focus_areas` | `what-do-you-know/preferences.json` | `focus_areas` |
| `blog.platform` | `mark-my-words/preferences.json` | `platform` |
| `blog.repo_url` | `mark-my-words/preferences.json` | `repo_url` |
| `blog.content_dir` | `mark-my-words/preferences.json` | `content_dir` |
| `blog.voice` | `mark-my-words/preferences.json` | `default_voice` |
| `blog.media_dir` | `mark-my-words/preferences.json` | `media_dir` |
| `blog.source_type` | `mark-my-words/preferences.json` | `source_type` |
| `blog.repo_branch` | `mark-my-words/preferences.json` | `repo_branch` |
| `blog.default_subdirectory` | `mark-my-words/preferences.json` | `default_subdirectory` |
| `blog.default_tags` | `mark-my-words/preferences.json` | `default_tags` |
| `blog.auto_suggest_visuals` | `mark-my-words/preferences.json` | `auto_suggest_visuals` |
| `blog.git_workflow` | `mark-my-words/preferences.json` | `git_workflow` |

---

## Progress File Conversion

### Interview Progress (Markdown → JSON)

The old `progress.md` contains dimension averages, category breakdowns, and session history in markdown tables. The new `progress.json` stores the same data structurally.

**Parsing approach:** Read the markdown file. Look for dimension score patterns (e.g., `| Specificity | 3.5 |`). Extract session entries from the history section.

### Knowledge Map (Markdown → JSON)

The old `knowledge-map.md` categorizes topics under headings like `## Strong`, `## Building`, `## Gap`, `## Blind Spot`. Each topic is a list item.

**Parsing approach:** Read the markdown. For each heading, extract the list items below it. Map heading names to level values: Strong→`strong`, Building→`building`, Gap→`gap`, Blind Spot→`blind_spot`.

---

## Rollback Instructions

If migration fails partway:

1. The old `config.yml` is archived as `config.yml.bak` - restore with `mv config.yml.bak config.yml`
2. The old bootstrap at `~/.claude/things.local.md` is removed last - if it still exists, the old plugins can still find data
3. Moved files can be moved back using the inverse of the path mappings above
4. The old `progress.md` and `knowledge-map.md` files are not deleted during migration (only the new JSON files are created alongside)

**Full rollback:**
```bash
cd ~/.things
mv config.yml.bak config.yml
rm config.json shared/professional-profile.json local.json registry.json 2>/dev/null
# Move files back from per-plugin dirs to flat structure
# (reverse the mv commands from the migration)
```

---

## What's NOT Migrated

- **Log file contents** - Unchanged. Frontmatter and body structure identical.
- **Session file contents** - Unchanged. Same markdown format.
- **Voice file contents** - Unchanged. Same markdown format with frontmatter.
- **Persona file contents** - Unchanged. Same markdown format.
- **Company file contents** - Unchanged. Same YAML format.
- **Arsenal file contents** - Unchanged (and will be regenerated by rebuild-data.py anyway).
- **Blog repo content** - The `.mark-my-words` working directory is renamed but content is untouched.
