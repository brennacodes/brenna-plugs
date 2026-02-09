---
name: update-questions
description: "Add new questions to the bank from trusted external sources with validation and deduplication"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
argument-hint: "<url or 'manual'>"
---

# Update Questions

Add new interview questions to the question bank from trusted sources or manual entry, with validation, deduplication, and proper metadata tagging.

## Steps

### 1. Load Configuration

Read `.claude/what-did-you-do.local.md` to get `trusted_sources`. If missing, direct to setup.

### 2. Determine Source

If the user provided a URL argument:
- Validate the URL against `trusted_sources.domains` and `trusted_sources.urls` using `references/source-validation.md`
- If untrusted:
  > That URL isn't in your trusted sources. Add it via `/what-did-you-do:setup` or provide a trusted source.
  Then stop.
- If trusted, use WebFetch to retrieve the content

If the user provided `manual`:
- Proceed to manual entry flow (Step 5)

If no argument, use AskUserQuestion:

**How do you want to add questions?**
- From a URL — I'll paste a link to interview questions
- Manual entry — I'll type them in
- Browse suggestions — show me what's new from my trusted sources

### 3. Parse External Content

From the fetched URL content, extract potential interview questions. Look for:
- Questions in quote format or numbered lists
- Follow-up questions
- Category indicators (behavioral, technical, etc.)
- Skill/topic tags
- Difficulty indicators

### 4. Validate and Enrich Questions

For each extracted question, apply the schema from `references/source-validation.md`:

1. **Deduplication:** Check against existing questions in all `<plugin_root>/questions/*.yaml` files. Flag duplicates or near-duplicates.
2. **Category assignment:** Classify into behavioral, technical, system-design, leadership, or situational
3. **Metadata generation:** Generate required fields:
   - `id`: `ext-<source-hash>-<seq>`
   - `skills_tested`: inferred from question content
   - `level`: inferred from complexity
   - `stages`: inferred from question type
   - `interviewer_types`: inferred from category
   - `difficulty`: 1-5 scale
   - `expected_format`: narrative / whiteboard / coding
   - `time_budget_minutes`: estimated
   - `red_flags` and `green_flags`: generated from question intent
   - `source`: URL or "manual"
   - `added_date`: today

4. **Follow-up generation:** For questions without follow-ups, generate depth-2 and depth-3 follow-ups

### 5. Manual Entry Flow

If manual entry, use AskUserQuestion iteratively:

**Question text?** (free text)

**Category?**
- behavioral
- technical
- system-design
- leadership
- situational

**What skills does this test?** (comma-separated)

**Difficulty?** (1=easy, 5=very hard)

**Any follow-up questions?** (free text, or skip)

Generate the remaining metadata fields automatically.

### 6. Present for Review

Show the user the proposed additions:

> **Questions to Add:**
>
> 1. **"<question>"**
>    Category: <cat> | Skills: <skills> | Difficulty: <n>
>    Status: New / Duplicate of <existing-id>
>
> 2. **"<question>"**
>    ...

Use AskUserQuestion:

**Which questions should I add?**
- All of them
- Let me select which ones
- None — cancel

If selecting, present each question individually for yes/no.

### 7. Write Questions

For new questions, determine the target file:
- Built-in categories → `<things_path>/interview-prep/question-overrides/custom.yaml`
- User questions always go to the overrides directory, never modifying built-in files

Read the existing `custom.yaml`, append the new questions, and write it back.

### 8. Rebuild Index

Run: `bash <plugin_root>/scripts/rebuild-question-index.sh`

### 9. Confirm

> Added [N] new questions to your custom question bank.
>
> - <category>: <count>
> - <category>: <count>
>
> These questions will appear in your practice and mock sessions. Run `/what-did-you-do:practice` to try them out.
