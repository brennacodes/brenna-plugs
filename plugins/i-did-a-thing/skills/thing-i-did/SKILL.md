---
name: thing-i-did
description: "Log a professional experience through a guided interview — accomplishments, lessons, expertise, decisions, influence, or insights — creating a structured and searchable entry in your .things directory"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[brief description of what happened]"
---

# Log a Thing You Did

Walk the user through capturing a professional experience with enough depth and structure to be useful for resumes, interviews, and blog posts later. The interview adapts based on what kind of thing it is — lessons, expertise, decisions, influence, and insights each get their own question flow.

## Steps

### 1. Load Configuration

Read `.claude/i-did-a-thing.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

### 2. Load Professional Context

Read `<things_path>/targets/profile.md` to understand the user's professional goals. This context shapes which follow-up questions to ask and how to tag the entry.

### 3. Start the Interview

If the user provided an argument (brief description), use it as the starting point. Otherwise, ask:

> What's on your mind? Could be something you built, a lesson you learned, a topic you went deep on, a decision you shaped — anything worth remembering.

### 4. Classify the Evidence Type

After the user describes the headline, determine the type. Use AskUserQuestion:

**What kind of thing is this?**
- Something I accomplished — built, shipped, fixed, improved, delivered
- A lesson I learned — failure, surprise, mistake, hard-won insight
- Expertise I developed — went deep on a topic, became the go-to person
- A decision I made — weighed options, chose an approach, can explain why
- Something I influenced — changed someone's mind, drove adoption, mentored
- A pattern or insight I noticed — observation, thesis, perspective

Map the selection to an `evidence_type` value: `accomplishment`, `lesson`, `expertise`, `decision`, `influence`, or `insight`.

### 5. Conduct the Deep-Dive Interview

Ask follow-up questions one at a time using AskUserQuestion. Adapt questions based on previous answers and the evidence type. The goal is to extract a rich, specific log entry.

#### Accomplishment

1. **Context**: "What was the situation or problem that led to this?"
2. **Action**: "What specifically did you do? Walk me through your approach."
3. **Result**: "What was the outcome? Be as specific as possible — numbers, feedback, changes."
4. **Skills Used**: Present a multi-select based on their `building_skills` + `aspirational_skills` from profile, plus an "Other" option: "Which skills did you use or develop?"

**Situational follow-ups:**
- If the result mentions a team: "What was your specific role vs. the team's contribution?"
- If it sounds like a first-time thing: "Was this the first time you did something like this? What did you learn?"
- If it involved a decision: "What alternatives did you consider? Why did you choose this approach?"
- If it had measurable impact: "Can you quantify the impact? (time saved, revenue, users affected, etc.)"
- If it involved leadership: "Who did you influence or lead? How?"
- If it involved technical work: "What was the technical approach? Any interesting challenges?"

#### Lesson

1. **Situation**: "What was the situation? Set the scene."
2. **Attempt**: "What did you try? What was the plan or approach?"
3. **What went wrong**: "What went wrong, or what surprised you?"
4. **What you'd do differently**: "Knowing what you know now, what would you do differently?"
5. **Takeaway**: "What did you take from this? How has it changed how you work?"
6. **Skills**: Present skill multi-select: "Which skills does this lesson touch?"

**Situational follow-ups:**
- If it sounds costly: "How costly was the mistake? Time, money, trust, momentum?"
- If they mention applying the lesson: "Where have you applied this lesson since?"
- If the lesson is technical: "What was the technical root cause?"
- If it involved others: "How did the team handle it? Was there a post-mortem?"

#### Expertise

1. **Domain**: "What's the topic or domain?"
2. **How developed**: "How did you develop this expertise? What was the journey?"
3. **Application**: "How do you apply this knowledge day-to-day?"
4. **Teaching**: "How have you shared or taught this to others?"
5. **Non-obvious**: "What's something non-obvious about this area that most people get wrong?"
6. **Skills**: Present skill multi-select: "Which skills are central to this expertise?"

**Situational follow-ups:**
- If they teach others: "What questions do people most often come to you with?"
- If it's deep: "What resources or experiences were most valuable in building this?"
- If it's evolving: "How is this area changing? What's your current edge?"

#### Decision

1. **Problem**: "What was the problem or question you needed to resolve?"
2. **Options**: "What options did you consider?"
3. **Evaluation**: "How did you evaluate them? What were the tradeoffs, constraints, and priorities?"
4. **Choice**: "What did you choose and why?"
5. **Outcome**: "How did it play out? Would you make the same call again?"
6. **Skills**: Present skill multi-select: "Which skills did this decision exercise?"

**Situational follow-ups:**
- If the stakes were high: "What was the blast radius if you got it wrong?"
- If others disagreed: "Was there pushback? How did you handle it?"
- If it was reversible: "Did you build in a way to reverse course if needed?"
- If data was involved: "What data or evidence informed your choice?"

#### Influence

1. **Status quo**: "What was the existing state or direction before you got involved?"
2. **Your position**: "What was your position or what change were you advocating for?"
3. **Advocacy**: "How did you make your case? What tactics or approach did you use?"
4. **Outcome**: "What happened? Did the change stick?"
5. **Reflection**: "What would you do differently if you had to advocate for this again?"
6. **Skills**: Present skill multi-select: "Which skills did you draw on?"

**Situational follow-ups:**
- If they had no authority: "Did you have formal authority here, or was this influence without authority?"
- If it involved data: "Did you use data, a prototype, or a pilot to make your case?"
- If it took time: "How long did the change take to land? Was it gradual or a single moment?"
- If it involved mentoring: "How did the person or team grow from this?"

#### Insight

1. **Observation**: "What did you observe or notice?"
2. **Where and how often**: "Where did you see this? Was it a one-off or a pattern?"
3. **Thesis**: "What's your thesis? What do you think is going on?"
4. **Evidence**: "What evidence supports your thinking?"
5. **Recommendation**: "What do you recommend based on this? Have you acted on it?"
6. **Skills**: Present skill multi-select: "Which skills does this insight draw on?"

**Situational follow-ups:**
- If it's actionable: "Has anyone acted on this yet? What happened?"
- If it's contrarian: "Do others see this differently? What's the conventional view?"
- If it spans systems: "Does this pattern show up in other contexts too?"

### 6. Classify the Entry

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
- `expertise` — built deep domain knowledge, became a resource
- `decision-making` — evaluated tradeoffs, made judgment calls
- `influence` — shaped others' decisions, advocated for change

### 7. Generate Tags

Auto-generate tags by combining:
- User's `default_tags` from config
- Skills mentioned in the interview
- Category from classification
- Evidence type
- Any technologies or tools mentioned
- Professional target alignment (from profile)

Present the generated tags and let the user add, remove, or modify them.

### 8. Compose the Log Entry

Create the log file at `<things_path>/logs/<date>-<slugified-title>.md` using the format defined in `references/log-format.md`.

The log must include:
- Complete YAML frontmatter with all metadata (including `evidence_type`)
- Structured body sections adapted to the evidence type (see below)
- A "Resume Bullets" section with 2-3 pre-written bullet points in the type-appropriate format
- An "Interview Talking Points" section with key points structured for the type
- A "Blog Seed" section with a 1-2 sentence hook tailored to the type

**Body sections by evidence type:**

| Type | Sections |
|------|----------|
| Accomplishment | Context, Action, Result, Reflection |
| Lesson | Situation, What I Tried, What Went Wrong, What I'd Do Differently, What I Took From It |
| Expertise | The Domain, How I Developed It, How I Apply It, How I've Shared It, What's Non-Obvious |
| Decision | The Problem, Options Considered, How I Evaluated Them, What I Chose and Why, How It Played Out |
| Influence | The Status Quo, My Position, How I Advocated, What Happened, What I'd Do Differently |
| Insight | What I Observed, Where and How Often, My Thesis, The Evidence, My Recommendation |

**Resume bullets by evidence type:**

| Type | Format |
|------|--------|
| Accomplishment | `ACTION VERB <what you did> by <how>, resulting in <measurable outcome>` |
| Lesson | `Learned <X> from <Y>, now apply <Z> to <outcome>` |
| Expertise | `Deep expertise in <X>, demonstrated through <Y>, enabling <Z>` |
| Decision | `Evaluated <X, Y, Z>; chose <Z> based on <A, B, C>, resulting in <outcome>` |
| Influence | `Drove adoption of <X> by <method>, resulting in <Y>` |
| Insight | `Identified <pattern X>, proposed <Y>, leading to <Z>` |

**Interview talking points by evidence type:**

| Type | Structure |
|------|-----------|
| Accomplishment | Situation - Task - Action - Result - Lessons |
| Lesson | Situation - Mistake/Surprise - Learning - Application |
| Expertise | Domain - Depth - Application - Teaching |
| Decision | Problem - Options - Tradeoffs - Choice - Outcome |
| Influence | Status Quo - Position - Advocacy - Outcome |
| Insight | Observation - Evidence - Thesis - Recommendation |

**Blog seed hooks by evidence type:**

| Type | Hook style |
|------|-----------|
| Accomplishment | Current engaging hook style |
| Lesson | "The time I learned..." hook |
| Expertise | "Everything I know about..." hook |
| Decision | "Why I chose X over Y..." hook |
| Influence | "How I convinced my team to..." hook |
| Insight | "A pattern I keep seeing..." hook |

### 9. Update the Index

Read `<things_path>/index.md` and update it:
- Increment `total_entries` in frontmatter
- Add the new entry under "By Date" (most recent first)
- Add/update tags under "By Tag"
- Add under the appropriate impact level
- Add under the appropriate evidence type (create the grouping if it doesn't exist yet)

### 10. Update the Arsenal

Read `<things_path>/arsenal/` and check if a summary file exists for each skill used. If not, create one. If it exists, append this entry as supporting evidence.

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
- Type: <evidence type>
- [Full log](../logs/<filename>)
```

### 11. Handle Git Workflow

Based on the `git_workflow` config setting:
- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this log entry?"
- **`auto`**: Automatically `git add`, `git commit -m "log: <title>"`, and `git push`
- **`manual`**: Tell the user the file has been saved and they can commit when ready

### 12. Celebrate

End with an encouraging summary:

> Logged! Here's what you captured:
>
> **<Title>** (`<impact>`, `<evidence_type>`)
> Tags: `<tags>`
> Skills: `<skills>`
>
> This is your **<nth>** logged entry. <encouraging message based on count/streak>
>
> Resume bullets are ready in the log. Run `/what-did-you-do:practice` to practice talking about it in an interview.
