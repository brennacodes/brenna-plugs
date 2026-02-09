---
name: interview-me
description: "Practice interview questions with coaching powered by your personal arsenal of accomplishments"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[category: behavioral|technical|leadership|situational]"
---

# Interview Me

Select a random interview question, let the user answer it, then give feedback and coaching based on their logged accomplishments.

## Steps

### 1. Load Configuration

Read `.claude/i-did-a-thing.local.md` to get settings. If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

### 2. Load the User's Arsenal

Read all files in `<things_path>/arsenal/` to understand what skills and evidence the user has logged. Also read `<things_path>/targets/profile.md` for their professional goals.

If no logs exist yet:

> You haven't logged any accomplishments yet. Run `/i-did-a-thing:thing-i-did` first so I have your arsenal to coach you with. I can still ask questions, but my feedback will be much more useful once I know your wins.

### 3. Select a Question Category

If the user provided an argument (category), use it. Otherwise, use AskUserQuestion:

**What kind of question do you want to practice?**
- `behavioral` — "Tell me about a time when..."
- `technical` — Scenario-based technical questions
- `leadership` — Influence, mentorship, decision-making
- `situational` — "What would you do if..."
- `surprise` — Random from any category

### 4. Select and Ask the Question

Use the question bank in `references/question-bank.md` to select a question. Selection should be:
- **Random** within the chosen category
- **Weighted toward gaps** — prefer questions related to skills in `aspirational_skills` or areas with fewer logged accomplishments
- **Non-repeating** — check `<things_path>/targets/interview-history.md` to avoid recently asked questions

Present the question conversationally:

> Here's your question:
>
> **"<question>"**
>
> Take your time. Answer as if you're in an actual interview.

### 5. Receive and Analyze the Answer

After the user answers, analyze it against their arsenal:

**Evaluate the answer on:**
1. **Specificity** — Did they give concrete details or stay vague?
2. **Structure** — Did they follow a clear narrative (STAR/CAR format)?
3. **Impact** — Did they quantify or clearly state the outcome?
4. **Relevance** — Does the answer actually address the question?
5. **Self-advocacy** — Did they own their contribution, or deflect credit?

**Cross-reference with arsenal:**
- Find logged accomplishments that could strengthen or replace their answer
- Identify skills they demonstrated but didn't mention
- Note metrics from their logs they could have cited

### 6. Deliver Feedback

Adjust depth based on `interview_depth` config setting:

#### If `concise`:

> **Score: <Strong / Good / Needs Work>**
>
> What worked: <1 line>
> To strengthen: <1 line>
> From your arsenal: You could also reference [<log title>](link) which shows <relevant detail>.

#### If `detailed`:

> **Assessment**
>
> **Structure** (x/5): <feedback>
> **Specificity** (x/5): <feedback>
> **Impact** (x/5): <feedback>
> **Self-advocacy** (x/5): <feedback>
>
> **Stronger answer using your arsenal:**
> Here's how you could restructure using your logged accomplishments:
> - Start with: <suggested opening referencing a specific log>
> - Evidence: <specific metric or outcome from their logs>
> - Close with: <suggested takeaway>
>
> **Gap spotted:** <if the question exposed a skill gap, note it>

#### If `coaching`:

Provide the detailed feedback above, plus:

> **Action items:**
> 1. <specific thing to practice or prepare>
> 2. <accomplishment to log that would fill a gap>
> 3. <skill to develop based on this question area>
>
> **Follow-up question** (to dig deeper):
> "<follow-up question>"

If in coaching mode, continue the conversation until the user is satisfied.

### 7. Log the Practice Session

Append to `<things_path>/targets/interview-history.md`:

```markdown
### <date> — <category>

**Question:** <question>
**Assessment:** <Strong/Good/Needs Work>
**Key feedback:** <1-line summary>
**Gaps identified:** <skills or areas to work on>
**Arsenal entries referenced:** <links to relevant logs>
```

### 8. Update Gap Analysis

Read `<things_path>/targets/profile.md` and update the "Gap Analysis" section based on patterns across interview sessions:

- Skills that come up in questions but lack logged evidence
- Categories where answers are consistently weaker
- Target role requirements that aren't yet demonstrated

### 9. Offer Next Steps

Use AskUserQuestion:

**What do you want to do next?**
- Ask me another question
- Log an accomplishment that fills a gap I identified
- Review my interview history and progress
- Done for now

If they choose another question, go back to Step 3.
If they choose to log an accomplishment, tell them to run `/i-did-a-thing:thing-i-did`.
If they choose to review history, display a summary from `interview-history.md`.
