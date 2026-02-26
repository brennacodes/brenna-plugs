---
name: review
description: "Cross-campaign analysis -- find patterns in what works, with whom, and in what medium. Use when user says 'review campaigns', 'what works', 'show me patterns', 'how am I doing'."
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[--audience <name>] [--medium <type>] [--tag <tag>] [--goal-type <short_term|long_term>]"
---

<purpose>
Analyze patterns across all campaigns and outcomes. Surface insights about what communication strategies work, with which audiences, in which mediums, and for which kinds of goals. Uses outcome data, audience profiles, and professional profile to generate actionable insights.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
    Resolve the user's home directory (run `echo $HOME` via Bash). Use this absolute path for all file operations below -- never pass `~` to the Read tool.

    1. Read `<home>/.things/config.json`
       <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>

    2. Read `<home>/.things/shared/professional-profile.json`
    </load-config>
  </step>

  <step id="load-data" number="2">
    <description>Load All Campaign Data</description>

    <phase name="campaigns" number="1">
    Scan `<home>/.things/heres-the-thing/campaigns/*/campaign.json`. Read all campaigns.
    </phase>

    <phase name="outcomes" number="2">
    Scan `<home>/.things/heres-the-thing/campaigns/*/outcomes/*.json`. Read all outcomes.
    </phase>

    <if condition="no-campaigns">
    Tell the user: "No campaigns found. Create one with `/heres-the-thing:pitch`." Then stop.
    </if>

    <if condition="no-outcomes">
    Note: "No outcomes logged yet. Campaign data available for structure analysis only."
    </if>
  </step>

  <step id="parse-filters" number="3">
    <description>Parse Filters</description>

    Parse `$ARGUMENTS` for optional filters:
    - `--audience <name>`: Filter to campaigns/outcomes involving this person or segment
    - `--medium <type>`: Filter to goals using this medium
    - `--tag <tag>`: Filter to campaigns/outcomes with this tag
    - `--goal-type <type>`: Filter to short_term or long_term goals

    Apply filters to the loaded data set.
  </step>

  <step id="analyze" number="4">
    <description>Generate Analysis</description>

    <phase name="overview" number="1">
    **Campaign Overview**:
    - Total campaigns: <n>
    - Active: <n>, Delivered: <n>, Closed: <n>
    - Total goals: <n> (succeeded: <n>, failed: <n>, active: <n>, pivoted: <n>)
    - Total outcomes logged: <n>
    </phase>

    <phase name="success-patterns" number="2">
    **Success Patterns** (from outcomes where result = succeeded or approved_with_conditions):
    - What framings/approaches appear in `what_landed` across successful outcomes?
    - Common threads in successful strategies
    - Which mediums have the best success rate?
    </phase>

    <phase name="failure-patterns" number="3">
    **Failure Patterns** (from outcomes where result = failed):
    - What appears in `what_didnt` across failed outcomes?
    - Common pitfalls
    - Which audience types are hardest to reach?
    </phase>

    <phase name="audience-insights" number="4">
    **Audience Insights**:
    - For each person/segment with multiple outcomes:
      - Success rate
      - What works with them (aggregated from what_landed)
      - What doesn't work (aggregated from what_didnt)
      - Receptiveness accuracy (predicted vs. actual)
    </phase>

    <phase name="medium-effectiveness" number="5">
    **Medium Effectiveness**:
    - Success rate by medium type
    - Average prep level at delivery by medium
    - Which mediums the user seems strongest in
    </phase>

    <phase name="skill-progression" number="6">
    **Skill Progression** (from feedback_to_system across all outcomes):
    - Strengths trending: appearing in recent what_landed
    - Weaknesses trending: appearing in recent what_didnt or user_reflections
    - Comparison with professional profile strengths/weaknesses
    </phase>

    <phase name="tag-analysis" number="7">
    **Tag Analysis** (if --tag filter or general):
    - Most common tags across campaigns
    - Tag-specific success rates
    - Tag co-occurrence patterns
    </phase>
  </step>

  <step id="present" number="5">
    <description>Present Results</description>

    Present the analysis in a structured format. Highlight:
    - Top 3 actionable insights
    - Recommended focus areas
    - Suggested next campaigns or prep activities

    <template name="review-output">
    ```
    heres-the-thing Review
    ═══════════════════════

    Overview:
      Campaigns: <n> (active: <n>, delivered: <n>, closed: <n>)
      Goals: <n> total (succeeded: <n>, failed: <n>, pivoted: <n>)
      Outcomes: <n> logged

    Top Insights:
      1. <insight with evidence>
      2. <insight with evidence>
      3. <insight with evidence>

    Success Patterns:
      <patterns>

    Audience Insights:
      <per-audience analysis>

    Medium Effectiveness:
      <medium> -- <success_rate>% success (<n> goals)
      <medium> -- <success_rate>% success (<n> goals)

    Skill Progression:
      Strengths: <trending strengths>
      Areas to work on: <trending weaknesses>

    Recommendations:
      <actionable next steps>
    ```
    </template>
  </step>

</steps>
