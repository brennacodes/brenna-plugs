---
name: thing-i-did
description: "Log an accomplishment through a guided interview, creating a structured and searchable entry in your .things directory"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[brief description of what you did]"
---

# Log a Thing You Did

Walk the user through capturing an accomplishment with enough depth and structure to be useful for resumes, interviews, and blog posts later.

## Steps

### 1. Load Configuration

Read `.claude/i-did-a-thing.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

### 2. Load Professional Context

Read `<things_path>/targets/profile.md` to understand the user's professional goals. This context shapes which follow-up questions to ask and how to tag the accomplishment.

### 3. Start the Interview

If the user provided an argument (brief description), use it as the starting point. Otherwise, ask:

> What did you do? Just give me the headline — we'll dig into the details together.

### 4. Conduct the Deep-Dive Interview

Ask follow-up questions one at a time using AskUserQuestion. Adapt questions based on previous answers. The goal is to extract a rich, specific log entry.

**Core questions (always ask):**

1. **Context**: "What was the situation or problem that led to this?"
2. **Action**: "What specifically did you do? Walk me through your approach."
3. **Result**: "What was the outcome? Be as specific as possible — numbers, feedback, changes."
4. **Skills Used**: Present a multi-select based on their `building_skills` + `aspirational_skills` from profile, plus an "Other" option:
   - "Which skills did you use or develop?"

**Situational questions (ask based on answers):**

- If the result mentions a team: "What was your specific role vs. the team's contribution?"
- If it sounds like a first-time thing: "Was this the first time you did something like this? What did you learn?"
- If it involved a decision: "What alternatives did you consider? Why did you choose this approach?"
- If it had measurable impact: "Can you quantify the impact? (time saved, revenue, users affected, etc.)"
- If it involved leadership: "Who did you influence or lead? How?"
- If it involved technical work: "What was the technical approach? Any interesting challenges?"

### 5. Classify the Accomplishment

Use AskUserQuestion to ask:

**What's the impact level?**
- `major` — significant outcome, career-defining, or organization-wide impact
- `notable` — meaningful result, team-level impact, or skill breakthrough
- `solid` — good work, worth remembering, builds on a pattern
- `learning` — didn't go perfectly but taught you something valuable

**Category?**
- `technical` — built, fixed, or improved something technical
- `leadership` — led, mentored, influenced, or organized people
- `communication` — presented, wrote, advocated, or facilitated
- `problem-solving` — diagnosed, analyzed, or resolved a complex issue
- `process` — improved workflow, created standards, or drove efficiency
- `growth` — learned something new, stretched into unfamiliar territory

### 6. Generate Tags

Auto-generate tags by combining:
- User's `default_tags` from config
- Skills mentioned in the interview
- Category from classification
- Any technologies or tools mentioned
- Professional target alignment (from profile)

Present the generated tags and let the user add, remove, or modify them.

### 7. Compose the Log Entry

Create the log file at `<things_path>/logs/<date>-<slugified-title>.md` using the format defined in `references/log-format.md`.

The log must include:
- Complete YAML frontmatter with all metadata
- Structured body sections (Context, Action, Result, Reflection)
- A "Resume Bullets" section with 2-3 pre-written bullet points in STAR format
- An "Interview Talking Points" section with key points to remember
- A "Blog Seed" section with a 1-2 sentence hook for potential blog posts

### 8. Update the Index

Read `<things_path>/index.md` and update it:
- Increment `total_entries` in frontmatter
- Add the new entry under "By Date" (most recent first)
- Add/update tags under "By Tag"
- Add under the appropriate impact level

### 9. Update the Arsenal

Read `<things_path>/arsenal/` and check if a summary file exists for each skill used. If not, create one. If it exists, append this accomplishment as supporting evidence.

Arsenal files live at `<things_path>/arsenal/<skill-slug>.md`:

```markdown
---
skill: "<Skill Name>"
evidence_count: <n>
last_demonstrated: <date>
proficiency_trend: "building" | "established" | "expert"
---

# <Skill Name>

## Evidence

### <date> — <log title>
- <1-line summary of how this skill was demonstrated>
- Impact: <impact level>
- [Full log](../logs/<filename>)
```

### 10. Handle Git Workflow

Based on the `git_workflow` config setting:
- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this log entry?"
- **`auto`**: Automatically `git add`, `git commit -m "log: <title>"`, and `git push`
- **`manual`**: Tell the user the file has been saved and they can commit when ready

### 11. Celebrate

End with an encouraging summary:

> Logged! Here's what you captured:
>
> **<Title>** (`<impact>`)
> Tags: `<tags>`
> Skills: `<skills>`
>
> This is your **<nth>** logged accomplishment. <encouraging message based on count/streak>
>
> Resume bullets are ready in the log. Run `/what-did-you-do:practice` to practice talking about it in an interview.
