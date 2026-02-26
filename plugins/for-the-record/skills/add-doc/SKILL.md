---
name: add-doc
description: "Capture structured documentation from conversation context - decisions, technical references, discussion summaries, how-to guides, and architecture docs. Auto-structures content, generates tags, and writes to .things/ for search and cross-reference."
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "<topic> [--detailed] [--tags tag1,tag2]"
---

<purpose>
Capture a structured document from the current conversation context. Automatically determines the best document structure (decision doc, technical reference, discussion summary, how-to guide, or architecture doc), generates tags for discoverability, and writes to `.things/for-the-record/docs/`. See `references/doc-format.md` for the frontmatter schema and document structures.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.<exit /></if>

      <read path="<home>/.things/for-the-record/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-ftr` first." Then stop.<exit /></if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    <action>Parse `$ARGUMENTS` for:</action>
    - **topic**: The subject to document (everything that isn't a flag)
    - **--detailed**: Override detail level to `detailed`
    - **--tags tag1,tag2**: Explicit tags to include (comma-separated)

    <action>Set `detail_level` from `--detailed` flag or fall back to `preferences.default_detail_level`.</action>
  </step>

  <step id="gather-context" number="3">
    <description>Gather Context from Conversation</description>

    <action>Search the conversation history for content relevant to the topic. Scope to the topic if one was provided.</action>

    <constraint>
    What counts as documentable context:
    - Technical discussions, decisions, architecture plans
    - Problem-solving sessions with conclusions
    - How-to walkthroughs or setup procedures
    - Design evaluations with tradeoffs
    - Configuration or integration details
    - Explanations of systems, patterns, or approaches
    </constraint>

    <if condition="no-useful-context">
      <ask-user-question>
        <question>I don't see relevant context in our conversation for "{topic}". What would you like to document?</question>
      </ask-user-question>
    </if>

    <if condition="topic-not-provided-and-context-ambiguous">
      <ask-user-question>
        <question>What would you like to capture as a document? I can see a few threads in our conversation.</question>
      </ask-user-question>
    </if>
  </step>

  <step id="choose-structure" number="4">
    <description>Choose Document Structure</description>

    <action>Based on the gathered context, auto-choose the best document structure:</action>

    | Content Pattern | Structure |
    |----------------|-----------|
    | Weighed options, chose an approach | Decision Doc: Context → Options → Evaluation → Decision → Rationale |
    | Explained a system, API, or tool | Technical Reference: Overview → Details → Usage → Caveats |
    | Discussed a topic, reached conclusions | Discussion Summary: Topic → Key Points → Conclusions → Open Questions |
    | Walked through steps to accomplish something | How-To Guide: Goal → Prerequisites → Steps → Verification |
    | Designed a system or component | Architecture Doc: Overview → Components → Data Flow → Constraints |

    <constraint>If the content doesn't clearly fit one structure, pick the closest match. Don't ask the user to choose — the auto-selection should be good enough. If genuinely ambiguous between two, briefly mention which you chose and why.</constraint>
  </step>

  <step id="compose-document" number="5">
    <description>Compose the Document</description>

    <action>Write the document body using the chosen structure.</action>

    <constraint>
    Detail level controls depth:
    - **concise**: Key points, decisions, outcomes. 1-2 paragraphs per section. Code blocks only when essential. Strip tangential discussion.
    - **detailed**: Full reasoning chains, all alternatives discussed, complete code blocks, edge cases, caveats, and context that future-you needs. Preserve the richness of the conversation.
    </constraint>

    <constraint>Preserve specificity. "Configured app's prompt routing to use XML workflow tags" is better than "set up the system." Capture project names, tool names, version numbers, file paths, and configuration details.</constraint>
  </step>

  <step id="generate-tags" number="6">
    <description>Generate Tags</description>

    <if condition="preferences.auto_tag == true">
      <action>Auto-generate tags by combining:</action>
      - Technologies and tools mentioned (e.g., `rust`, `python`, `claude-code`)
      - Domain keywords (e.g., `architecture`, `security`, `performance`)
      - Activity type (e.g., `decision`, `reference`, `how-to`)
      - Project names mentioned
      - Any explicit `--tags` from arguments

      <action>Read existing `<home>/.things/for-the-record/tags.json` and cross-reference for consistency. Prefer existing tag spellings over new variations (e.g., use `claude-code` if it exists rather than creating `claude_code`).</action>

      <action>Also check `<home>/.things/tags/index.json` (central tag index) for cross-plugin tag consistency.</action>
    </if>

    <if condition="preferences.auto_tag == false">
      <action>Use only explicit `--tags` from arguments. If none provided, ask.</action>
    </if>

    <ask-user-question>
      <question>Here are the generated tags for this document. Add, remove, or modify:</question>
      <option>Looks good</option>
      <option-with-text-input>Make changes</option-with-text-input>
    </ask-user-question>
  </step>

  <step id="generate-filename" number="7">
    <description>Generate Filename</description>

    <action>Generate filename: `<YYYY-MM-DD>-<slugified-topic>.md`</action>

    <constraint>Slugify: lowercase, replace spaces and special chars with hyphens, collapse multiple hyphens, trim to reasonable length (~60 chars max for the slug portion).</constraint>

    <action>Check if file already exists at `<home>/.things/for-the-record/docs/<filename>`.</action>
    <if condition="file-exists">
      <ask-user-question>
        <question>A document with this name already exists. What would you like to do?</question>
        <option>Replace it</option>
        <option-with-text-input>Use a different name</option-with-text-input>
      </ask-user-question>
    </if>
  </step>

  <step id="write-document" number="8">
    <description>Write Document</description>

    <write path="<home>/.things/for-the-record/docs/<filename>">

    <constraint>Use the frontmatter schema from `references/doc-format.md`.</constraint>

    <template name="document">
    ```markdown
    ---
    title: "<title>"
    date: <YYYY-MM-DD>
    description: "<1-2 sentence summary>"
    detail_level: "<concise|detailed>"
    source_type: "conversation"
    tags: [<tags>]
    ---

    <document body using chosen structure>
    ```
    </template>

    </write>
  </step>

  <step id="rebuild-index" number="9">
    <description>Rebuild Index</description>

    <constraint>The things PostToolUse hook automatically dispatches `rebuild-index.py` via the registry after writing a doc file. No manual rebuild needed.</constraint>

    <if condition="hook-did-not-fire">The rebuild can be run manually:
      <command language="bash" tool="Bash">python3 <plugin_root>/scripts/rebuild-index.py $HOME/.things</command>
    </if>
  </step>

  <step id="git-workflow" number="10">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Pull latest before committing.</action>
      <command language="bash" tool="Bash">git -C <home>/.things pull --rebase 2>/dev/null || true</command>

      <action>Read git workflow from `config.json` (`git.workflow`).</action>

      <if condition="workflow-auto">Automatically `git add`, `git commit -m "doc: <title>"`, and `git push`.</if>
      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push this document?</question>
          <option>Yes -- commit and push</option>
          <option>Commit only</option>
          <option>No -- I'll handle git myself</option>
        </ask-user-question>
      </if>
      <if condition="workflow-manual">Tell the user the file has been saved.</if>
    </git-workflow>
  </step>

  <step id="confirm" number="11">
    <description>Confirm</description>

    <completion-message>
    Captured: **<title>** (`<detail_level>`, `<structure_type>`)
    Location: `<home>/.things/for-the-record/docs/<filename>`
    Tags: `<tags>`

    Find it later: `/things:search-things --tag <tag>` or `/things:search-things <keyword>`
    </completion-message>
  </step>

</steps>
