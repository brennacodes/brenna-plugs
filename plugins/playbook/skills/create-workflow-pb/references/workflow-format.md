# Workflow Format Reference

Workflows are **pure XML documents**. The only markdown permitted is a `# Title` and `> Description` at the top. Everything after is structured XML — unambiguous, machine-executable instructions for Claude.

## 1. Document Structure

```
# Title
> Description

<references>              ← OPTIONAL: reusable declarations
<steps>                   ← REQUIRED: the workflow
<verification-commands>   ← OPTIONAL: command quick-reference
<principles>              ← OPTIONAL: guiding philosophy
```

The `<steps>` element is the only required top-level element. All others are optional. No markdown (lists, headings, bold, code fences) is permitted after the description line.

## 2. Top-Level References

The `<references>` block declares values used repeatedly throughout the workflow, eliminating duplication.

```xml
<references>
  <ref id="test-cmd">cargo test --all-features</ref>
  <ref id="lint-cmd">cargo clippy --all-targets --all-features -- -D warnings</ref>
  <ref id="src">src/</ref>
</references>
```

Reference a declared value anywhere in the workflow via `<use ref="test-cmd" />`. This inlines the referenced value at that position. Example:

```xml
<instruction>
  <command><use ref="test-cmd" /></command>
  <expected>All tests pass</expected>
</instruction>
```

References are optional. Small workflows with no repeated values don't need them.

## 3. Complete Tag Hierarchy

### Structural Tags (step skeleton)

```
<step number="N" id="step-id">          REQUIRED attrs: number, id
  ├── <title>                            REQUIRED (1)
  ├── <goal>                             REQUIRED (1)
  ├── <inputs>                           OPTIONAL (0-1)
  │   └── <input>                          (1+)
  ├── <outputs>                          OPTIONAL (0-1)
  │   └── <output>                         (1+)
  ├── <prerequisite ref="step-id">       OPTIONAL (0+)
  ├── <instructions>                     OPTIONAL (0-1)
  │   └── <instruction>                    (1+)
  ├── <gate>                             OPTIONAL (0-1)
  │   ├── <condition>                      REQUIRED inside gate
  │   └── <on_fail goto="step-id">        OPTIONAL
  ├── <boundaries>                       OPTIONAL (0-1)
  │   └── <rule>                           (1+)
  ├── <anti-patterns>                    OPTIONAL (0-1)
  │   └── <anti-pattern>                   (1+)
  └── <critical>                         OPTIONAL (0-1)
```

### Execution Tags (inside `<instruction>` — what to DO)

```
<instruction>
  ├── (prose text)                       Free text describing the action
  ├── <action>                           Non-command work the executor must do
  ├── <command note="...">               Shell command to run
  ├── <expected>                         What output should look like (pairs with command)
  ├── <rationale>                        Why this instruction matters
  ├── <fix>                              How to recover if command fails (pairs with command)
  ├── <format>                           Expected output format
  │   └── <line>                           (1+)
  ├── <rules>                            Rules governing this instruction
  │   └── <rule>                           (1+)
  ├── <anti-pattern>                     Inline anti-pattern (also valid inside anti-patterns)
  └── <conditional>                      Runtime branching
      ├── <condition>                      REQUIRED
      └── <action>                         REQUIRED
```

### Input/Output Tags (optional per step)

```
<inputs>
  └── <input>          What the step needs before starting (data, state, files)

<outputs>
  └── <output>         What the step produces (artifacts, state changes)
```

Use when a workflow has data flowing between steps. Not needed for simple linear workflows.

### Constraint Tags (guardrails and checkpoints)

```
<gate>                                   Binary pass/fail checkpoint
  ├── <condition>                        REQUIRED: what must be true
  └── <on_fail goto="step-id">          OPTIONAL: recovery action + where to go

<prerequisite ref="step-id">             Step ordering dependency

<boundaries>                             Positive guardrails
  └── <rule>

<anti-patterns>                          Negative examples, non-obvious pitfalls
  └── <anti-pattern>

<critical>                               Data loss / security level warnings (use sparingly)
```

### Top-Level Tags (outside steps)

```
<verification-commands>                  Command quick-reference
  ├── <description>
  ├── <command-sequence>
  │   └── <command note="...">             (1+)
  └── <critical>

<principles>                             Guiding philosophy
  └── <principle name="...">               (1+)
```

## 4. Tag Decision Trees

### Choosing Execution Tags (inside `<instruction>`)

| When you need to... | Use | Example |
|---|---|---|
| Run a shell command | `<command>` | `<command>cargo test</command>` |
| Describe expected output | `<expected>` | `<expected>All tests pass</expected>` |
| Explain WHY an instruction matters | `<rationale>` | `<rationale>Warnings become bugs</rationale>` |
| Show how to recover from failure | `<fix>` | `<fix>cargo fmt</fix>` |
| Describe non-command work | `<action>` | `<action>Review the diff for unintended changes</action>` |
| Specify output format | `<format>` + `<line>` | Commit message format, file naming |
| Set rules for this instruction | `<rules>` + `<rule>` | Imperative mood, character limits |
| Branch on a runtime condition | `<conditional>` | `<condition>` + `<action>` children |

### Choosing Constraint Tags (step level)

| When you need to... | Use | Key distinction |
|---|---|---|
| Block step completion until verified | `<gate>` + `<condition>` | Runtime checkpoint, binary pass/fail |
| Declare step ordering | `<prerequisite ref="">` | Dependency, not verification |
| Constrain HOW a step is performed | `<boundaries>` + `<rule>` | Positive guardrails |
| Warn about common mistakes | `<anti-patterns>` + `<anti-pattern>` | Negative examples, non-obvious pitfalls |
| Flag a show-stopper | `<critical>` | Data loss / security level only, use sparingly |
| Express workflow-wide philosophy | `<principles>` + `<principle>` | Top-level, not per-step |

### Key Distinctions

- **gate vs boundaries**: A gate is a binary checkpoint that blocks progress. Boundaries are rules that constrain how work is done but don't block completion.
- **boundaries vs anti-patterns**: Boundaries say what TO do (positive). Anti-patterns say what NOT to do (negative). Use anti-patterns for non-obvious mistakes that someone would reasonably make.
- **critical vs boundaries**: Critical is for data-loss or security-level warnings only. If you have 3+ `<critical>` elements in a step, most of them should be `<boundaries>` rules.
- **prerequisite vs gate**: A prerequisite declares that another step must be done first (ordering). A gate verifies that a condition is true before proceeding (quality check).

## 5. Attribute Reference

| Tag | Attribute | Required | Description |
|---|---|---|---|
| `<step>` | `number` | Yes | Step sequence number (integer) |
| `<step>` | `id` | Yes | Unique identifier for cross-referencing |
| `<command>` | `note` | No | Important note about the command |
| `<prerequisite>` | `ref` | Yes | Step id that must be completed first |
| `<on_fail>` | `goto` | No | Step id to return to on failure |
| `<principle>` | `name` | Yes | Short principle name |
| `<ref>` | `id` | Yes | Unique reference identifier |
| `<use>` | `ref` | Yes | References a declared `<ref id="">` |
| `<instruction>` | `goto` | No | Step id for transition instructions |

## 6. Anti-Examples

### WRONG: Markdown lists inside instructions

```xml
<!-- WRONG -->
<instructions>
  - Write the tests first
  - Run cargo test
  - Check the output
</instructions>

<!-- RIGHT -->
<instructions>
  <instruction>
    <action>Write the tests first</action>
  </instruction>
  <instruction>
    <command>cargo test</command>
    <expected>New tests fail for the right reasons</expected>
  </instruction>
</instructions>
```

### WRONG: Prose where structured tags belong

```xml
<!-- WRONG -->
<instruction>
  Run cargo test and make sure all tests pass. If they don't, run cargo fmt to fix formatting.
</instruction>

<!-- RIGHT -->
<instruction>
  <command>cargo test</command>
  <expected>All tests pass</expected>
  <fix>cargo fmt</fix>
</instruction>
```

### WRONG: Missing goal on a step

```xml
<!-- WRONG -->
<step number="1" id="setup">
  <title>Setup</title>
  <instructions>...</instructions>
</step>

<!-- RIGHT -->
<step number="1" id="setup">
  <title>Setup</title>
  <goal>Prepare the development environment with all dependencies.</goal>
  <instructions>...</instructions>
</step>
```

### WRONG: Overusing critical

```xml
<!-- WRONG — most of these are boundaries, not critical -->
<critical>Always use --all-features</critical>
<critical>Never skip tests</critical>
<critical>Use imperative mood in commit messages</critical>

<!-- RIGHT — one critical, rest are boundaries/rules -->
<critical>ALWAYS run cargo test --all-features without filters. Filtered tests hide failures.</critical>
<boundaries>
  <rule>Use imperative mood in commit messages</rule>
</boundaries>
```

### WRONG: Markdown headings inside steps

```xml
<!-- WRONG -->
<steps>
  <step number="1" id="setup">
    <title>Setup</title>
    <goal>Get ready.</goal>

    ## Configuration
    Set up the config file...

    ## Dependencies
    Install the deps...
  </step>
</steps>

<!-- RIGHT -->
<steps>
  <step number="1" id="setup">
    <title>Setup</title>
    <goal>Get ready.</goal>
    <instructions>
      <instruction>
        <action>Set up the config file</action>
      </instruction>
      <instruction>
        <action>Install the dependencies</action>
      </instruction>
    </instructions>
  </step>
</steps>
```

## 7. CLAUDE.md Workflow Summary Format

When referencing a workflow from CLAUDE.md, include a step index so Claude can see the workflow structure at a glance without reading the full file:

```xml
<workflow path=".claude/workflows/dev-workflow.md">
  <summary>Atomic, test-driven development workflow</summary>
  <step-index>
    <step ref="specification">Define behavior through failing tests</step>
    <step ref="implementation">Write minimum code to pass</step>
    <step ref="linting">Static quality gate</step>
    <step ref="testing">Full test suite verification</step>
    <step ref="commit">Atomic commit</step>
  </step-index>
</workflow>
```

This replaces a bare `<reference path="">` pointer. The `ref` attributes match step `id` values in the workflow file.

## 8. SKILL.md Integration Patterns

### Reference Mode

Copy the workflow to the skill's `references/` directory and add a reference tag:

```xml
<reference name="workflow" path="references/my-workflow.md" />
```

The workflow file remains pure XML. The skill reads it as a reference document.

### Embed Mode

Convert `<step>` elements into SKILL.md `<steps>` format, translating tag types:

| Workflow tag | SKILL.md equivalent |
|---|---|
| `<step number="" id="">` | `<step id="" number="">` |
| `<title>` | `<description>` |
| `<gate>` + `<condition>` | `<if condition="gate-condition">` |
| `<command>` | `<command language="bash" tool="Bash">` |
| `<action>` | `<action>` (same) |
| `<prerequisite ref="">` | Dependency note in step description |
| `<references>` | Inline the referenced values (SKILL files don't use `<references>`) |
| `<boundaries>` + `<rule>` | `<constraint>` |
| `<anti-patterns>` | `<constraint>` (reframe as positive rule) |
| `<critical>` | `<constraint>` with strong language |
| `<expected>` | Text inside `<action>` or as a comment |

## 9. Minimal Complete Example

A 3-step workflow demonstrating structural, execution, and constraint tags together:

```xml
# Database Migration Workflow
> Safe, verified database migration process with rollback planning.

<references>
  <ref id="migrate-cmd">bin/rails db:migrate</ref>
  <ref id="rollback-cmd">bin/rails db:rollback</ref>
  <ref id="schema-file">db/schema.rb</ref>
</references>

<steps>
  <step number="1" id="prepare">
    <title>Prepare Migration</title>
    <goal>Create and validate the migration file before touching the database.</goal>
    <outputs>
      <output>Migration file in db/migrate/</output>
      <output>Rollback plan documented</output>
    </outputs>
    <instructions>
      <instruction>
        <action>Generate the migration file</action>
        <command>bin/rails generate migration AddStatusToOrders status:integer</command>
      </instruction>
      <instruction>
        <action>Review the generated migration for correctness</action>
        <rationale>Auto-generated migrations may need index additions or default values.</rationale>
      </instruction>
      <instruction>
        <action>Document the rollback plan: what command reverses this migration and what data implications exist</action>
      </instruction>
    </instructions>
    <boundaries>
      <rule>One logical change per migration file</rule>
      <rule>Always add indexes for columns used in WHERE clauses</rule>
    </boundaries>
    <gate>
      <condition>Migration file exists, has been reviewed, and rollback plan is documented</condition>
      <on_fail>Revise migration or document rollback before proceeding</on_fail>
    </gate>
  </step>

  <step number="2" id="execute">
    <title>Execute Migration</title>
    <goal>Apply the migration and verify the schema change.</goal>
    <prerequisite ref="prepare">Migration file reviewed and rollback plan documented</prerequisite>
    <inputs>
      <input>Reviewed migration file from prepare step</input>
    </inputs>
    <outputs>
      <output>Updated <use ref="schema-file" /></output>
    </outputs>
    <instructions>
      <instruction>
        <command><use ref="migrate-cmd" /></command>
        <expected>Migration runs without errors</expected>
        <fix><use ref="rollback-cmd" /></fix>
      </instruction>
      <instruction>
        <command>bin/rails db:migrate:status</command>
        <expected>All migrations show "up" status</expected>
      </instruction>
    </instructions>
    <critical>Never run migrations on production without a tested rollback path.</critical>
    <gate>
      <condition>Schema updated correctly and migration status shows all up</condition>
      <on_fail goto="prepare">Rollback and fix the migration file</on_fail>
    </gate>
  </step>

  <step number="3" id="verify">
    <title>Verify Application</title>
    <goal>Confirm the application works correctly with the new schema.</goal>
    <prerequisite ref="execute">Migration applied successfully</prerequisite>
    <inputs>
      <input>Updated schema from execute step</input>
    </inputs>
    <instructions>
      <instruction>
        <command>bin/rails test</command>
        <expected>All tests pass</expected>
      </instruction>
      <instruction>
        <command><use ref="rollback-cmd" /> && <use ref="migrate-cmd" /></command>
        <expected>Rollback and re-migrate succeed cleanly</expected>
        <rationale>Proves the migration is reversible.</rationale>
      </instruction>
    </instructions>
    <gate>
      <condition>Tests pass and rollback/re-migrate cycle succeeds</condition>
      <on_fail goto="prepare">Fix migration and re-run from prepare step</on_fail>
    </gate>
  </step>
</steps>

<verification-commands>
  <description>Quick reference for migration verification:</description>
  <command-sequence>
    <command><use ref="migrate-cmd" /></command>
    <command>bin/rails db:migrate:status</command>
    <command>bin/rails test</command>
    <command><use ref="rollback-cmd" /> && <use ref="migrate-cmd" /></command>
  </command-sequence>
</verification-commands>

<principles>
  <principle name="Reversible">Every migration must have a tested rollback path</principle>
  <principle name="Atomic">One logical schema change per migration</principle>
  <principle name="Verified">Test suite must pass after every schema change</principle>
</principles>
```

## 10. Frontmatter Schema (Archive Copy)

The archive copy in `playbook/workflows/` includes YAML frontmatter. The working copy (placed in `.claude/workflows/`) does NOT include frontmatter — it's pure workflow content ready for Claude Code to execute.

```yaml
---
title: "Workflow title"
date: YYYY-MM-DD
description: "What this workflow covers"
doc_type: "workflow"
scope: "development|release|review|testing|custom"
target_path: ".claude/workflows/my-workflow.md"
step_count: N
referenced_from: ["CLAUDE.md", "plugins/x/skills/y/SKILL.md"]
tags: [tag1, tag2]
---
```

### Scope Types

| Scope | Description |
|---|---|
| `development` | Build/implement features (spec, implement, test, commit) |
| `release` | Release process (version bump, changelog, tag, publish) |
| `review` | Code review process (gather context, review, report) |
| `testing` | Test strategy (unit, integration, e2e, coverage) |
| `custom` | Any other workflow type |
