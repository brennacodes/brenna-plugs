---
name: prep-for
description: "Build a company-specific interview preparation plan with value mapping, stage walkthroughs, and targeted practice recommendations"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
argument-hint: "<company: amazon|google|meta|custom> [--role <target role>] [--level <level>]"
---

# Prep For

Generate a tailored preparation plan for a specific company's interview process, mapping the user's arsenal to company values and identifying gaps.

## Steps

### 1. Load Configuration

Read `.claude/what-did-you-do.local.md` and `.claude/i-did-a-thing.local.md`. If either is missing, direct to setup.

### 2. Load Company Profile

If the user provided a company argument, load from `<plugin_root>/companies/<company>.yaml` (built-in) or `<things_path>/interview-prep/companies/<company>.yaml` (custom).

If no company specified, use AskUserQuestion:

**Which company are you preparing for?**
- Amazon
- Google
- Meta
- Custom — I have a job listing or company info to share

If "Custom", ask the user to paste a job listing or company information. Use it to build an ad-hoc company profile, referencing `references/prep-strategy.md` for structure.

### 3. Determine Target Role and Level

If `--role` and `--level` were provided, use them. Otherwise, check the user's profile for `target_roles`. If still unclear, ask:

**What role and level are you targeting?**
(Free text — e.g., "Senior Software Engineer" or "Staff Engineer, L6")

Map the stated level to the company's `level_expectations` if available.

### 4. Load Arsenal and Session History

Read all arsenal files and session history. This powers the gap analysis.

### 5. Map Arsenal to Company Values

For each company value:

1. Identify the value's `interview_signals` and `question_themes`
2. Search arsenal files for accomplishments that demonstrate these signals
3. Search session history for relevant question answers
4. Classify each value as:
   - **Strong:** Multiple arsenal entries with high relevance + strong session scores
   - **Partial:** Some evidence but gaps in depth or variety
   - **Gap:** Little or no evidence in arsenal or sessions

Present the mapping:

> **[Company] Values Alignment**
>
> | Value | Status | Evidence | Gap |
> |-------|--------|----------|-----|
> | <value> | Strong/Partial/Gap | <best arsenal entry> | <what's missing> |

### 6. Stage-by-Stage Preparation Guide

For each stage in the company's `interview_process`:

> **Stage: [Stage Name]** ([format], [duration] min)
>
> **What they're evaluating:** <evaluation_focus>
> **Your interviewer type:** <persona role>
>
> **Your readiness:** <based on mock/practice session scores for this stage>
>
> **Preparation checklist:**
> - [ ] Prepare [N] stories that demonstrate <values tested in this stage>
> - [ ] Practice with [persona] persona: `/what-did-you-do:practice --persona <persona>`
> - [ ] Run a mock for this stage: `/what-did-you-do:mock <company> --stage <stage>`
>
> **Key stories to prepare:** (from arsenal)
> - <story from arsenal that maps to this stage's focus>
>
> **Anti-patterns to avoid:** (from company values)
> - <anti-pattern from company profile>

### 7. Question Prediction

Based on company values and target level, predict likely questions:

> **Questions to Expect**
>
> **High probability** (directly maps to company values):
> - "<question>" — tests <value>
> - "<question>" — tests <value>
>
> **Medium probability** (common at this level):
> - "<question>" — tests <skill>
>
> **Curveball potential** (bar raiser / unique to this company):
> - "<question>" — tests <unusual skill or value>

### 8. Build Preparation Timeline

Ask the user:

**When is your interview?**
- This week
- Next week
- 2-4 weeks out
- 1+ month out
- Not scheduled yet

Generate a preparation plan scaled to the timeline:

> **Preparation Plan: [Company] [Role] — [Timeline]**
>
> **Week 1:**
> - Day 1-2: Log any unlogged accomplishments that map to [company] values
> - Day 3-4: Practice [weakest category] with [persona] (2-3 questions/day)
> - Day 5: Mock [first stage] round
>
> **Week 2:** (if applicable)
> - Continue practice focus areas
> - Mock [next stage] round
> - Review progress and adjust
>
> [etc.]

### 9. Write Preparation Plan

Write the full plan to `<things_path>/interview-prep/companies/<company>-prep-plan.md` with frontmatter:

```yaml
---
company: "<company>"
target_role: "<role>"
target_level: "<level>"
interview_date: "<date or null>"
created: <today>
values_coverage: <strong>/<total>
stage_readiness:
  <stage>: <ready|developing|gap>
arsenal_gaps:
  - "<skill or value>"
---
```

### 10. Offer Next Steps

Use AskUserQuestion:

**Where do you want to start?**
- Log accomplishments for my biggest gaps
- Practice my weakest value area
- Run a mock for the first stage
- Review my full readiness
- Done for now — I'll follow the plan
