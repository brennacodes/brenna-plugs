---
name: bridge
description: "Build a personalized learning plan that bridges from existing knowledge to a target topic, grounded in your actual experience"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<gap-topic> [--from <existing-strength>] [--timeline 1-week|2-weeks|1-month]"
---

# Bridge

Build a concrete learning plan that bridges from what you already know to a gap topic. Plans are grounded in your arsenal evidence and include checkpoints using explore and quiz sessions.

## Steps

### 1. Load Configuration

Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below — never pass `~` to the Read tool.

Read `<home>/.claude/things.local.md` to get `things_path` (if `things_path` starts with `~`, replace with `<home>`). If missing:

> No configuration found. Please run `/i-did-a-thing:setup` first.

Then stop.

Read `<things_path>/config.yml` for all settings.

### 2. Load All Data

Read:
- `<things_path>/index.json` — all log data
- `<things_path>/arsenal/` — all skill evidence files
- `<things_path>/learning/knowledge-map.md` — current knowledge classifications
- `<things_path>/learning/progress.md` — learning scores

Run: `bash <plugin_root>/scripts/search-sessions.sh --recent 20`

### 3. Identify the Gap

If the user provided a gap topic as an argument, use it. Otherwise, use AskUserQuestion:

**What topic do you want to build a learning plan for?**
(Free text — e.g., "distributed consensus", "observability", "API design patterns")

If the user recently ran `/what-do-you-know:gaps`, reference the gap report to suggest options.

### 4. Find the Bridge

If `--from` was provided, use that as the starting strength. Otherwise, search the arsenal and learning sessions for the closest existing knowledge:

1. Search `index.json` for entries with skills that relate to the gap topic
2. Check `knowledge-map.md` for strong topics adjacent to the gap
3. Check learning session scores for related topics

Present the bridge connection:

> **Bridging to: [gap topic]**
>
> **Starting from:** [existing strength] — based on [evidence]
>
> You understand [existing concept] from your experience with [project/entry from arsenal]. To get to [gap topic], you can build on that foundation:
> - [connection point 1]
> - [connection point 2]

If no clear connection exists:

> I don't see a strong bridge from your existing knowledge. This is more of a greenfield learning area. The plan will start from fundamentals.

### 5. Select Timeline

If `--timeline` was provided, use it. Otherwise, use AskUserQuestion:

**How much time do you want to invest?**
- 1 week — focused sprint, ~30 min/day
- 2 weeks — steady pace, ~20 min/day (Recommended)
- 1 month — deep investment, ~15 min/day

### 6. Build the Plan

Generate a structured learning plan with milestones and checkpoints. Reference `references/learning-plan-framework.md` for plan structure.

Each plan section should:
- Start from what the user already knows (grounded in arsenal)
- Include exercises tied to actual projects where possible
- Have checkpoints using quiz and explore skills
- Build incrementally toward the target understanding

**Plan structure:**

> **Learning Plan: [Gap Topic]**
>
> **Starting from:** [existing strength]
> **Timeline:** [duration]
> **Goal:** [what "understanding this topic" means concretely]
>
> ### Phase 1: Foundation (Days 1-N)
> **Objective:** [what you'll understand after this phase]
>
> **Building from:** Your experience with [arsenal reference] gives you a foundation in [related concept].
>
> **Activities:**
> - [ ] Read/research: [specific resource or concept]
> - [ ] Reflect: How does [concept] relate to your [arsenal entry]?
> - [ ] Checkpoint: `/what-do-you-know:explore <sub-topic> --depth exploratory`
>
> ### Phase 2: Depth (Days N-M)
> **Objective:** [deeper understanding target]
>
> **Activities:**
> - [ ] Hands-on: [exercise tied to their projects]
> - [ ] Connect: [concept] ↔ [related concept from their work]
> - [ ] Checkpoint: `/what-do-you-know:quiz --topic <topic> --count 5`
>
> ### Phase 3: Integration (Days M-End)
> **Objective:** [ability to apply and teach]
>
> **Activities:**
> - [ ] Apply: How would [concept] change your approach to [past project]?
> - [ ] Teach: Explain [concept] as if writing a blog post
> - [ ] Checkpoint: `/what-do-you-know:explore <topic> --depth deep`
> - [ ] Log it: `/i-did-a-thing:thing-i-did` — capture what you learned as an expertise entry
>
> ### Success Criteria
> - [ ] Can explain [topic] to a peer without notes
> - [ ] Can identify tradeoffs between [approach A] and [approach B]
> - [ ] Score ≥ 4/5 on quiz for [topic]

### 7. Write the Plan

Write the plan to `<things_path>/learning/study-plans/<topic-slug>.md`:

```yaml
---
topic: "<gap topic>"
bridge_from: "<existing strength>"
timeline: "<1-week|2-weeks|1-month>"
created: <date>
status: active
phases:
  - name: "Foundation"
    target_date: "<date>"
    status: pending
  - name: "Depth"
    target_date: "<date>"
    status: pending
  - name: "Integration"
    target_date: "<date>"
    status: pending
arsenal_references:
  - file: "<log filename>"
    relevance: "<bridge connection>"
---
```

Followed by the full plan content in markdown.

### 8. Offer to Start

Use AskUserQuestion:

**Ready to start?**
- Yes — begin with an explore session on [topic]
- Not now — I'll follow the plan on my own
- Adjust the plan — I want to change something
