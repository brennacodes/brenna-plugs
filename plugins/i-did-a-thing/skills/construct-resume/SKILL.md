---
name: construct-resume
description: "Build a tailored resume from your logged evidence — accomplishments, lessons, expertise, decisions, and insights — matched against a specific job listing"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
argument-hint: "[job listing URL or paste the listing]"
---

# Construct a Resume

Analyze a job listing, match it against the user's logged evidence, and produce a tailored resume that speaks directly to what the role demands. Evidence comes in different types — accomplishments, lessons, expertise, decisions, influence, and insights — and the resume should draw on all of them.

## Steps

### 1. Load Configuration

Read `.claude/i-did-a-thing.local.md` to get settings. If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

### 2. Load the Arsenal

Read all files in:
- `<things_path>/arsenal/` — skill summaries with evidence
- `<things_path>/targets/profile.md` — professional profile
- `<things_path>/logs/` — all log entries (read frontmatter of each to build an index)

If fewer than 3 logs exist:

> You only have <n> logged entries. I can work with this, but your resume will be stronger with more evidence. Consider running `/i-did-a-thing:thing-i-did` a few more times to build your arsenal.

### 3. Get the Job Listing

If the user provided a URL as an argument, use WebFetch to retrieve it. If they pasted text, use that directly. If neither:

> Paste the job listing or give me a URL and I'll pull it for you.

### 4. Analyze the Job Listing

Parse the listing to extract:
- **Role title** and level
- **Required skills** (hard and soft)
- **Preferred/nice-to-have skills**
- **Key responsibilities**
- **Company values or culture signals**
- **Industry/domain context**

Present the analysis:

> Here's what I see in this listing:
>
> **Role:** <title>
> **Must-haves:** <skills>
> **Nice-to-haves:** <skills>
> **Key themes:** <themes>
>
> Let me match this against your arsenal.

### 5. Match Against Arsenal

For each required and preferred skill in the listing:
1. Search arsenal files for matching skills
2. Search log frontmatter for matching `skills_used`, `tags`, `category`, and `evidence_type`
3. Score each log's relevance to the listing, weighting evidence types by what the listing emphasizes:
   - Listing asks for "learning agility," "growth mindset," or "adaptability" → weight `lesson` entries higher
   - Listing asks for "technical depth," "domain expertise," or "subject matter expert" → weight `expertise` entries higher
   - Listing asks for "sound judgment," "strategic thinking," or "architectural decisions" → weight `decision` entries higher
   - Listing asks for "influence," "leadership without authority," or "mentorship" → weight `influence` entries higher
   - Listing asks for "vision," "innovation," or "strategic direction" → weight `insight` entries higher
   - Standard behavioral requirements → weight `accomplishment` entries as default
4. Identify **strong matches** (direct evidence), **partial matches** (related evidence), and **gaps** (no evidence)

Present the match analysis:

> **Strong matches** (you have direct evidence):
> - <skill>: <n> entries, best example: "<log title>" (`<evidence_type>`)
>
> **Partial matches** (related experience):
> - <skill>: closest evidence is <description>
>
> **Gaps** (no logged evidence):
> - <skill>: consider logging relevant experience or highlighting transferable skills

### 6. Build the Resume

Use the template in `references/resume-format.md` to construct the resume.

**Resume construction rules:**
1. **Tailor the summary** to echo the listing's language and priorities
2. **Order experience sections** by relevance to this role, not chronologically
3. **Pull resume bullets** directly from log files' "Resume Bullets" sections, using the type-appropriate format:
   - Accomplishment entries → STAR-format bullets
   - Lesson entries → "Learned X from Y, now apply Z" format
   - Expertise entries → "Deep expertise in X, demonstrated through Y" format
   - Decision entries → "Evaluated X, Y, Z; chose Z based on A, B, C" format
   - Influence entries → "Drove adoption of X, resulting in Y" format
   - Insight entries → "Identified pattern X, proposed Y" format
4. **Adapt bullets** to use keywords from the job listing where truthful
5. **Quantify everything possible** using metrics from logs
6. **Include skills section** ordered by listing priority, only including skills with evidence
7. **Match tone** to the company's culture signals

Use AskUserQuestion to ask:

**Resume format preference?**
- `traditional` — clean, professional, ATS-friendly
- `narrative` — summary-driven with accomplishment highlights
- `technical` — skills-forward with project details

### 7. Write the Resume

Write the resume to `<things_path>/resumes/<date>-<company-slug>.md`.

Include a metadata header (not part of the resume itself):

```yaml
---
target_role: "<role title>"
target_company: "<company>"
listing_url: "<url if provided>"
date_generated: <date>
match_score: "<strong_matches>/<total_requirements>"
evidence_types_used:
  accomplishment: <n>
  lesson: <n>
  expertise: <n>
  decision: <n>
  influence: <n>
  insight: <n>
logs_referenced:
  - "<log filename>"
  - "<log filename>"
gaps_identified:
  - "<skill>"
---
```

### 8. Review with User

Present the resume and ask:

**How does this look?**
- Looks great — save it
- I want to adjust some sections
- Regenerate with a different format
- Let me add more evidence first

If they want adjustments, use AskUserQuestion to identify which sections, then Edit the file.

### 9. Generate a Cover Letter Seed (Optional)

Use AskUserQuestion:

**Want me to draft cover letter talking points too?**
- Yes — give me bullet points I can use
- Yes — draft a full cover letter
- No — just the resume

If yes, generate talking points or a full draft that:
- References specific entries from logs (not just accomplishments)
- Connects the user's trajectory to the role
- Uses the company's own language from the listing
- Emphasizes the strongest matches

Write to `<things_path>/resumes/<date>-<company-slug>-cover.md`.

### 10. Gap Action Plan

End with actionable advice:

> **To strengthen your candidacy for this role:**
>
> 1. **Log these existing experiences** (you probably have them, just haven't documented them):
>    - <suggested entries to log, specifying evidence type>
>    - e.g., "Log an expertise entry about your distributed systems knowledge"
>    - e.g., "Log a decision entry about the database migration approach you chose"
>
> 2. **Build these skills** (gaps you could fill):
>    - <skill>: <suggestion for how to build evidence>
>
> 3. **Diversify your evidence** (types you're missing):
>    - <e.g., "You have strong accomplishments in distributed systems but no logged expertise entries — consider logging your deep knowledge as an expertise entry">
>    - <e.g., "For 'sound judgment,' a decision entry would be more compelling than another accomplishment">
>
> 4. **Practice these interview questions** (likely to come up for this role):
>    - "<question from question bank that tests a key requirement>"
>
> Run `/what-did-you-do:practice` to drill specific questions, or `/what-did-you-do:prep-for` to build a full preparation plan for this company.
