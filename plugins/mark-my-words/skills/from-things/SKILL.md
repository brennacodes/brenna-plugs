---
name: from-things
description: "Create a blog post from i-did-a-thing evidence logs - turn your wins into stories"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[log filename or search query]"
---

<references>
  <reference name="things-bridge" path="references/things-bridge.md" />
  <reference name="media-guide" path="../add-media/references/media-guide.md" />
</references>

<purpose>
Source a blog post from one or more i-did-a-thing evidence logs. Each log already contains a Blog Seed, narrative structure, and potential angles -- this skill transforms them into engaging posts.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup-things` first." Then stop.</if>

      <read path="<home>/.things/mark-my-words/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-mmw` first." Then stop.</if>
    </load-config>

    <action>Read `platform` from preferences.json (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines all platform-specific formatting rules -- frontmatter fields, content syntax, image format, callouts, code blocks, and file naming conventions.</action>

    <action>Load voice profile.</action>
    <if condition="default-voice-set">
      <read path="<home>/.things/mark-my-words/voices/<default_voice>.md" output="voice" />
      <if condition="voice-file-missing">Warn the user that their default voice profile is missing and continue without a voice.</if>
    </if>
    <action>Also check if any voice profiles exist in `<home>/.things/mark-my-words/voices/` using Glob. Store this for the interview step.</action>

    <action>Load professional profile.</action>
    <read path="<home>/.things/shared/professional-profile.json" output="professional-profile" />
    <if condition="professional-profile-missing">Fall back to `author_name` from config.json.</if>

    <action>Resolve media directory.</action>
    <if condition="media-dir-set">Resolve the full media path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`). Store this path for use in visual planning and post generation.</if>
  </step>

  <step id="resolve-content-location" number="2">
    <description>Resolve Content Location</description>

    <if condition="source-type-remote">
      <action>Check if the repo is already cloned at `<workdir>` (read `workdir` from preferences.json, default `<home>/.mark-my-words`).</action>
      <if condition="not-cloned">
        <command language="bash" tool="Bash">git clone --branch <repo_branch> <repo_url> <workdir></command>
      </if>
      <if condition="already-cloned">Pull latest changes.</if>
      The content root is `<workdir>/<content_dir>/`.
    </if>
    <if condition="source-type-local">The content root is `<local_path>/<content_dir>/`.</if>
  </step>

  <step id="select-logs" number="3">
    <description>Select Logs</description>

    <action>Read `<home>/.things/i-did-a-thing/index.json` to get the full index of all logs with their metadata, blog seeds, and blog_potential ratings.</action>

    <if condition="arguments-provided">Find matching entries in the index.</if>
    <if condition="no-arguments">
      <ask-user-question>
        <question>What do you want to write about?</question>
        <option>Browse recent logs (last 10)</option>
        <option>Search by tag or skill</option>
        <option>Find entries marked high blog potential</option>
        <option>Combine multiple logs into one post</option>
      </ask-user-question>
    </if>

    <if condition="user-browse-recent">Show the first 10 entries from `index.json` (already sorted by date descending) with title, date, impact, and `blog_potential`. Let the user select one.</if>
    <if condition="user-search">Ask for search criteria (tag, skill, or keyword). Filter entries in `index.json` by matching tags, skills_used, or title/description. Present matching results and let the user select.</if>
    <if condition="user-high-blog-potential">Filter entries in `index.json` where `blog_potential` is `"high"`. Present results.</if>
    <if condition="user-combine-multiple">Let the user select 2-5 logs to weave into a single narrative post. See <reference name="things-bridge"/> for multi-log strategies.</if>
  </step>

  <step id="read-selected-logs" number="4">
    <description>Read Selected Logs</description>

    <action>Read the full content of selected log(s). Extract:</action>
    - Blog Seed section -- the opening hook
    - Potential angles -- narrative direction options
    - Context / Action / Result -- the substance
    - Reflection -- personal voice and takeaway
    - Metrics -- concrete numbers from frontmatter
    - Tags and skills -- for post categorization
  </step>

  <step id="choose-narrative-angle" number="5">
    <description>Choose the Narrative Angle</description>

    <ask-user-question>
      <question>What angle should this post take?</question>
      Present the potential angles from the log(s), plus standard options:
      <option><Angle 1 from log's "Potential angles"></option>
      <option><Angle 2 from log's "Potential angles"></option>
      <option>Tutorial/how-to (teach what you learned)</option>
      <option>Retrospective (reflect on the journey)</option>
    </ask-user-question>
  </step>

  <step id="select-voice" number="6">
    <description>Select Voice</description>

    <if condition="voice-profiles-exist">
      <if condition="default-voice-set">Show it and ask if they want to use it, pick a different one, or skip voice for this post.</if>
      <if condition="no-default-voice">List available voices and let them pick one or skip.</if>
    </if>
  </step>

  <step id="scan-existing-posts" number="7">
    <description>Scan Existing Posts</description>

    <action>Use Glob and Grep to scan the blog content directory:</action>
    - Find all `.md` files in the target subdirectory
    - Extract existing tags from frontmatter across posts
    - This informs tag suggestions and maintains consistency
  </step>

  <step id="plan-visuals" number="7.5">
    <description>Plan Visuals</description>

    <constraint>Only run this step if `media_dir` is configured.</constraint>

    <action>Analyze the selected log(s) for visual content opportunities:</action>
    <validate name="architecture">Architecture in Action section -- flowcharts or system diagrams (only if platform supports Mermaid)</validate>
    <validate name="process-flows">Process flows (deployment pipelines, workflows, data flows) -- sequence diagrams or flowcharts</validate>
    <validate name="comparisons">Before/after comparisons -- side-by-side images or diagrams</validate>
    <validate name="metrics">Metrics and results -- tables or formatted data presentations</validate>

    <ask-user-question>
      <question>How should we handle visuals?</question>
      <option>Generate diagrams where they fit -- create Mermaid diagrams for architecture and flow content (only offered if platform supports Mermaid)</option>
      <option>Also find relevant images -- diagrams plus web-searched images for visual concepts</option>
      <option>Keep it text-only -- skip visuals entirely</option>
      <option>Decide as we write -- suggest visuals inline during generation</option>
    </ask-user-question>

    <action>Store the user's choice for Step 8.</action>
  </step>

  <step id="generate-post" number="8">
    <description>Generate the Post</description>

    <action>Transform the log into a blog post following the platform template loaded in Step 1 and the transformation guide in <reference name="things-bridge"/>.</action>

    <constraint name="transformation-rules">
      1. Open with the Blog Seed hook, adapted to the chosen angle
      2. Rewrite the title -- engaging and blog-appropriate, not resume-like
      3. Transform Context / Action / Result into narrative prose with a natural, first-person voice
      4. Include code/technical details if the log has them, using proper code blocks with language identifiers and any platform-specific code block features (titles, line highlighting) where appropriate
      5. Pull metrics from frontmatter and contextualize them (not just numbers, but why they matter)
      6. Expand the Reflection into a genuine takeaway for readers
    </constraint>

    <action>Generate platform-compatible frontmatter following the template:</action>
    - Use the platform's frontmatter format (YAML `---` or TOML `+++`)
    - Use the platform's field names (e.g., `pubDate` for Astro, `date` for most others)
    - `title`: Rewritten for a blog audience
    - Date: Today's date (when the post is written)
    - `description`: 1-2 sentence preview for SEO/social
    - Tags: Adapted from log tags, blended with existing blog tags, using platform format
    - Draft: `true` initially (or platform equivalent)
    - Author: From professional profile or config.json

    <action>Add visuals if planned in Step 7.5 -- generate Mermaid diagrams for architecture and flow content from the log's Action section (only if platform supports Mermaid), insert image references using the platform's image syntax, place visuals after the text that introduces the concept. Follow placement rules from <reference name="media-guide"/>.</action>
    <if condition="user-decide-as-we-write">Suggest visuals inline and ask before adding each one.</if>
    <if condition="user-also-find-images">Use WebSearch to find and download relevant images to the media dir.</if>

    <if condition="voice-profile-selected">Follow its guidance for tone, sentence patterns, vocabulary, rhetorical habits, and things to avoid. The voice shapes how you write -- the transformation rules still control what you write (Blog Seed hook, narrative structure, metrics integration). Voice and transformation rules are complementary, not competing.</if>
    <if condition="no-voice-profile">Write in a natural, engaging voice -- personal blog, not documentation.</if>

    <constraint name="content-quality">
      - Use H2 for major sections, H3 for subsections (no H1 in body)
      - One idea per paragraph
      - Use the platform's native callout/admonition syntax if supported, sparingly and where they add value
      - If platform doesn't support callouts, use blockquotes or emphasized text
      - End with a clear takeaway
    </constraint>
  </step>

  <step id="present-for-review" number="9">
    <description>Present for Review</description>

    <action>Show the generated post and ask:</action>

    <ask-user-question>
      <question>How's this draft?</question>
      <option>Save it -- I'll review and publish later</option>
      <option>Edit it first -- I want to refine some sections</option>
      <option>Change the angle -- try a different approach</option>
      <option>Start over -- pick different logs</option>
    </ask-user-question>

    <if condition="user-save-it">Continue to Step 10.</if>
    <if condition="user-edit">Use AskUserQuestion to identify which sections to revise, then Edit the draft and present again.</if>
    <if condition="user-change-angle">Go back to Step 5.</if>
    <if condition="user-start-over">Go back to Step 3.</if>
  </step>

  <step id="save-file" number="10">
    <description>Save the File</description>

    <action>Generate a filename following the platform's naming convention:</action>
    <platform-specific platform="jekyll">`YYYY-MM-DD-slug.md` (date prefix required)</platform-specific>
    <platform-specific platform="all-others">`slug.md` (lowercase, hyphens for spaces, no special characters)</platform-specific>

    <write path="<content_root>/<default_subdirectory>/<filename>.md" />
    <platform-specific platform="jekyll-drafts">For Jekyll drafts: write to `<content_root>/../_drafts/<slug>.md` (no date prefix needed in `_drafts/`).</platform-specific>

    <action>Tell the user the file path.</action>
  </step>

  <step id="update-source-logs" number="11">
    <description>Update Source Log Metadata</description>

    <action>Edit the source log(s) in `<home>/.things/i-did-a-thing/logs/` to record that a post was created. Add to the log's frontmatter:</action>

    <schema name="blog-post-metadata">
    ```yaml
    blog_post: "<path to generated post>"
    blog_post_date: <today's date>
    ```
    </schema>

    <constraint>This prevents the same log from being surfaced as "unused" in future runs.</constraint>
  </step>

  <step id="git-workflow" number="12">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Before committing, pull latest changes from the remote (if one exists) to avoid conflicts.</action>
      <command language="bash" tool="Bash">git -C <content_root> pull --rebase 2>/dev/null || true</command>

      Based on the `git_workflow` setting from preferences.json (for the blog repo):

      <if condition="workflow-ask">
        <ask-user-question>
          <question>Would you like to commit and push this post?</question>
          <option>Yes (commit + push)</option>
          <option>Commit only (no push)</option>
          <option>No (skip git)</option>
        </ask-user-question>
      </if>
      <if condition="workflow-auto">Automatically `git add`, `git commit -m "Add post: <title> (from things)"`, and `git push`.</if>
      <if condition="workflow-manual">Tell the user the file has been written and they can commit when ready.</if>

      <constraint>When committing, `git add` both the post file and any media files added to the media directory.</constraint>
      <if condition="content-not-in-git-repo">Skip git operations.</if>
    </git-workflow>
  </step>

  <step id="suggest-related" number="13">
    <description>Suggest Related Posts</description>

    <completion-message>
      Based on the source log's tags and skills, check if other logs could make good companion posts:

      > Based on your tags, these logs could make good follow-up posts:
      > - "<log title>" -- <potential angle>
      > - "<log title>" -- <potential angle>
      >
      > Run `/from-things <filename>` to draft one.
    </completion-message>
  </step>

</steps>
