---
name: explore
description: "Deep-dive into a topic using your arsenal evidence, with persona-driven probing questions and concept mapping"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<topic> [--persona staff-engineer|engineering-manager|...] [--depth exploratory|focused|deep]"
---

# Explore

Conduct a topic-driven deep dive that probes your understanding through conversation, maps what you know against what you've done, and identifies where your knowledge is strong, partial, or missing.

## Steps

### 1. Load Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Read `<home>/.claude/things.local.md` to get `things_path` (if `things_path` starts with `~`, replace with `<home>`). If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

Read `<things_path>/config.yml` for all settings. Extract `building_skills`, `aspirational_skills`, `current_role`, `target_roles` from the shared profile, and `default_depth`, `default_persona`, `session_length` from `learning:`. If config.yml is missing or `learning:` has only defaults, suggest running `/what-do-you-know:setup`.

### 2. Load the User's Arsenal

Read all files in `<things_path>/arsenal/` to understand logged skills and evidence. Read `<things_path>/index.json` for structured entry data.

If no logs exist:

> You haven't logged any entries yet. Run `/i-did-a-thing:thing-i-did` first so I have your experience to explore with. I can still probe your knowledge, but sessions are much richer when grounded in your actual work.

### 3. Select Topic

If the user provided a topic argument, use it. Otherwise, use AskUserQuestion:

**What topic do you want to explore?**
(Free text — e.g., "distributed systems", "API design", "observability")

### 4. Search Arsenal for Topic Evidence

Search `<things_path>/index.json` for entries matching the topic by:
- Tags that match or relate to the topic
- `skills_used` and `skills_developed` fields
- Entry titles and descriptions containing topic-related terms

Collect all matching entries as context for the session.

### 5. Load Session History

Run: `bash <plugin_root>/scripts/search-sessions.sh --topic <topic> --recent 5`

Use previous session data to avoid re-asking the same probing questions and to track progress on this topic.

### 6. Select Persona

If the user specified `--persona`, use it. Otherwise, use the `default_persona` from config. Load the selected persona from `<things_path>/personas/<persona>.md`.

Adopt the persona's voice, evaluation weights, and follow-up patterns — but adapt them for learning rather than interview coaching. The persona is probing to understand and deepen knowledge, not to evaluate interview readiness.

### 7. Select Depth

If the user specified `--depth`, use it. Otherwise, use `default_depth` from config.

- **exploratory** — Broad overview: "What do you know about X? Walk me through the landscape." Cover breadth, identify strong and weak areas.
- **focused** — Targeted deep-dive: "Let's go deep on X. Explain how it works under the hood." Probe internals, edge cases, tradeoffs.
- **deep** — Intensive probing: "You've worked with X. Let's stress-test your mental model." Challenge assumptions, explore failure modes, demand precision.

### 8. Begin Probing Dialogue

Use the persona's voice to begin exploring the topic. Ground questions in the user's actual experience from their arsenal:

**Probing patterns:**

- **Experience-grounded**: "You made an architecture decision about [X] in [project from arsenal]. Walk me through your reasoning."
- **Scale challenge**: "What would break first if you scaled this 10x?"
- **Comparison**: "How does your approach compare to [standard approach]?"
- **Edge cases**: "What happens when [edge case]? How would you handle it?"
- **Teaching test**: "If you had to explain [concept] to a junior engineer, where would you start?"
- **Connection probing**: "How does [concept A] relate to [concept B from their experience]?"
- **Gap detection**: "What's the difference between [similar concept A] and [similar concept B]?"

Adapt the probing based on depth level:
- **exploratory**: 4-6 questions, broad coverage, identify landscape
- **focused**: 6-8 questions, targeted depth in specific areas
- **deep**: 8-12 questions, intensive probing, challenge mental models

### 9. Probe Deeper Where Strong, Widen Where Thin

As the user responds:
- Where they demonstrate strong understanding → push deeper: "What's happening at the layer below that?" or "What are the tradeoffs of that approach vs. alternatives?"
- Where they show thin understanding → widen: "Let's set that aside for now. What about [related concept]?" or "That's a gap worth noting. Let me ask about something adjacent."
- Where they reference arsenal entries → connect: "You mentioned [entry]. How does that experience inform your understanding of the general principle?"

Use the `session_length` config to pace the conversation:
- **short**: ~15 min, 4-5 exchanges
- **medium**: ~30 min, 7-8 exchanges
- **deep**: ~60 min, 12+ exchanges

### 10. Score on Learning Dimensions

After the dialogue, score the user on five dimensions (from `references/exploration-framework.md`):

1. **Depth** (1-5) — How far below the surface can they explain? Internals vs. buzzwords
2. **Accuracy** (1-5) — Are their mental models technically correct?
3. **Connections** (1-5) — Can they relate this to adjacent concepts and their own experiences?
4. **Application** (1-5) — Can they apply the knowledge to new situations?
5. **Articulation** (1-5) — Can they explain it clearly to someone else?

### 11. Produce Concept Map

Classify concepts discussed into:
- **Strong** — demonstrated depth, accuracy, and ability to teach
- **Partial** — understands the basics but gaps in depth or precision
- **Gap** — couldn't explain or had significant misconceptions

Present the map:

> **Concept Map: [Topic]**
>
> **Strong:**
> - [concept] — [evidence of strength]
>
> **Partial:**
> - [concept] — [what's missing]
>
> **Gap:**
> - [concept] — [what to learn]

### 12. Deliver Feedback

Use the persona's voice to deliver feedback:

> **[Persona Name]'s Assessment**
>
> | Dimension | Score | Notes |
> |-----------|-------|-------|
> | Depth | x/5 | <brief note> |
> | Accuracy | x/5 | <brief note> |
> | Connections | x/5 | <brief note> |
> | Application | x/5 | <brief note> |
> | Articulation | x/5 | <brief note> |
>
> **Strongest area:** <what they demonstrated well>
>
> **Biggest opportunity:** <most impactful area to deepen>
>
> **From your arsenal:** <connections to logged experiences that could ground further learning>

### 13. Log the Session

Write a session file at `<things_path>/learning/sessions/<date>-explore-<topic-slug>.md`:

```markdown
---
type: explore
date: <date>
topic: <topic>
persona: <persona>
depth: <exploratory|focused|deep>
scores:
  depth: <1-5>
  accuracy: <1-5>
  connections: <1-5>
  application: <1-5>
  articulation: <1-5>
  overall: <average>
strong_concepts:
  - <concept>
partial_concepts:
  - <concept>
gap_concepts:
  - <concept>
arsenal_references:
  - file: "<log filename>"
    relevance: "<how it was used>"
---

# Explore Session: <topic> — <date>

## Topic
<topic>

## Concept Map
<strong / partial / gap breakdown>

## Key Exchanges
<summary of most revealing Q&A moments>

## Feedback
<summary of feedback given>

## Recommended Next Steps
<what to explore, quiz, or bridge next>
```

### 14. Update Knowledge Map and Progress

Read and update `<things_path>/learning/knowledge-map.md`:
- Add or update topic entries under Strong / Building / Gap / Blind Spot based on scores
- Note specific concepts in each category

Read and update `<things_path>/learning/progress.md`:
- Update dimension averages with new scores
- Update topic breakdown
- Add to recent sessions list

### 15. Handle Git Workflow

Before committing, pull latest changes from the remote (if one exists) to avoid conflicts:

```bash
git -C <things_path> pull --rebase 2>/dev/null || true
```

Based on the `git_workflow` config setting:
- **`ask`**: Use AskUserQuestion — "Would you like to commit and push this explore session?"
- **`auto`**: Automatically `git add` the session file, knowledge-map.md, and progress.md, `git commit -m "explore: <topic>"`, and `git push`
- **`manual`**: Tell the user the session has been saved and they can commit when ready

### 16. Suggest Next Steps

> **Next steps for [topic]:**
> - Quiz yourself: `/what-do-you-know:quiz --topic <topic>` — test retention with spaced repetition
> - Bridge a gap: `/what-do-you-know:bridge <gap-concept>` — build a learning plan from existing knowledge
> - Explore adjacent: `/what-do-you-know:explore <related-topic>` — broaden your map
> - Log an experience: `/i-did-a-thing:thing-i-did` — capture what you just learned

Use AskUserQuestion:

**What next?**
- Explore another topic
- Quiz this topic
- Bridge a gap from this session
- Done for now
