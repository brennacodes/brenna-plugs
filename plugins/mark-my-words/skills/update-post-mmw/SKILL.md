---
name: update-post-mmw
description: Update an existing blog post.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[post filename or search term]"
---

<references>
  <reference name="update-strategies" path="references/update-strategies.md" />
  <reference name="media-guide" path="../add-media/references/media-guide.md" />
</references>

<purpose>
You are helping the user update an existing blog post. Find the post, understand what they want to change, and apply the updates carefully.
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

    <action>Read `platform` from preferences.json (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines frontmatter field names, content syntax, and formatting conventions. Follow it for all content modifications.</action>

    <action>Load voice profile.</action>
    <if condition="default-voice-set">
      <read path="<home>/.things/mark-my-words/voices/<default_voice>.md" output="voice" />
      <if condition="voice-file-missing">Warn the user and continue without a voice.</if>
    </if>
    <action>Also check if any voice profiles exist in `<home>/.things/mark-my-words/voices/` using Glob. Store this for use in full rewrites.</action>

    <action>Resolve media directory.</action>
    <if condition="media-dir-set">Resolve the full media path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`). Store this path for use in the "Add visuals" mode.</if>
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

  <step id="find-post" number="3">
    <description>Find the Post</description>

    <if condition="arguments-provided">
      <action>Search for matching posts by:</action>
      - Filename match (glob for `*<argument>*.md`)
      - Title match (grep for the argument in frontmatter `title:` fields)
      - Content match if no filename/title hits
    </if>

    <if condition="no-arguments">List the 10 most recently modified `.md` files in the content directory with their titles and dates.</if>

    <if condition="multiple-matches">
      <ask-user-question>
        <question>Which post?</question>
        Show title, date, and filename for each option.
      </ask-user-question>
    </if>

    <if condition="no-matches">Tell the user and suggest they check the filename or try a different search term.</if>
  </step>

  <step id="read-post" number="4">
    <description>Read the Post</description>

    <action>Read the full content of the selected post. Display a summary to the user:</action>
    - Title
    - Date
    - Tags
    - Draft status
    - Word count
    - First few lines of content (or section headings)
  </step>

  <step id="interview-for-changes" number="5">
    <description>Interview for Changes</description>

    <action>Use AskUserQuestion to determine what the user wants to change. Consult <reference name="update-strategies"/> for guidance on each approach.</action>

    <ask-user-question>
      <question>Update mode</question>
      <option>Edit specific sections -- modify particular parts while keeping the rest intact</option>
      <option>Append new content -- add a new section or content to the end</option>
      <option>Full rewrite -- rewrite the entire post with new content</option>
      <option>Frontmatter only -- just update metadata (tags, title, date, draft status)</option>
      <option>Add visuals -- add diagrams, images, and media (only shown if `media_dir` is configured)</option>
    </ask-user-question>

    <if condition="mode-edit-sections">
      <action>Ask which section(s) to modify and what the changes should be. List the current headings so the user can reference them.</action>
    </if>

    <if condition="mode-append">
      <action>Ask what new section/content to add and where it should go (end of post, before conclusion, after a specific section).</action>
    </if>

    <if condition="mode-full-rewrite">
      <action>Ask for the new direction/focus. Confirm that they want to replace all existing content.</action>
      <if condition="voice-profiles-exist">
        <ask-user-question>
          <question>Which voice to use for the rewrite?</question>
          <if condition="default-voice-set">Offer it as the default choice.</if>
          List other available voices.
          <option>No voice -- write naturally</option>
        </ask-user-question>
      </if>
    </if>

    <if condition="mode-frontmatter-only">
      <ask-user-question>
        <question>What to update?</question>
        <option>Title</option>
        <option>Tags (add/remove)</option>
        <option>Draft status (publish/unpublish)</option>
        <option>Description</option>
        <option>Date</option>
      </ask-user-question>
    </if>

    <if condition="mode-add-visuals">
      <action>Analyze the post for visual opportunities using the detection patterns from <reference name="media-guide"/>.</action>

      <action>Scan the post for diagram candidates (processes -> flowcharts, architectures -> subgraph diagrams, request flows -> sequence diagrams, state changes -> state diagrams), image candidates (UI references, visual concepts, results), and table candidates (comparisons, structured data). Only suggest Mermaid diagrams if the platform template indicates Mermaid support.</action>

      <action>Present findings organized by section name and line number, with a suggested visual type for each.</action>

      <ask-user-question>
        <question>What would you like to do?</question>
        <option>Accept all suggestions</option>
        <option>Pick and choose which ones to add</option>
        <option>Add my own images instead</option>
        <option>Search for images on the web</option>
      </ask-user-question>

      <action>For each accepted item:</action>
      - Mermaid diagrams: Generate the diagram code, show it for approval, then use Edit to insert it after the text that introduces the concept
      - User-provided images: Get the path/URL and description, copy/download to media dir, insert image reference using the platform's syntax from the template
      - Web-searched images: Use WebSearch to find relevant images, present options, download selected image to media dir, insert reference
      - Video embeds: Get the URL, generate iframe embed (or platform shortcode if available), insert with a context sentence
    </if>

    <action>Frontmatter date handling: Use the platform's field names from the template. Ask if they want to:</action>
    - Keep the original date
    - Update to today's date
    - Add an "updated" field with today's date (field name varies by platform: `lastmod` for Quartz/Hugo, `last_modified_at` for Jekyll, `updatedDate` for Astro, `updated` for Zola, `last_update` object for Docusaurus)
  </step>

  <step id="apply-changes" number="6">
    <description>Apply Changes</description>

    <constraint>Use the Edit tool for targeted changes to preserve the rest of the file.</constraint>
    <constraint>Use Write only for full rewrites.</constraint>
    <if condition="voice-profile-selected">Follow its guidance for tone, sentence patterns, vocabulary, rhetorical habits, structure, and things to avoid.</if>
    <constraint>Preserve any frontmatter fields the user didn't ask to change.</constraint>
    <constraint>When adding an updated-date field, keep the original date field intact.</constraint>
    <constraint>Maintain the post's existing voice and style unless the user asked for a tone change.</constraint>
  </step>

  <step id="show-result" number="7">
    <description>Show the Result</description>

    <action>After making changes, read the updated file and show the user:</action>
    - Updated frontmatter
    - A brief summary of what changed
    - The file path
  </step>

  <step id="git-workflow" number="8">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Before committing, pull latest changes from the remote (if one exists) to avoid conflicts.</action>
      <command language="bash" tool="Bash">git -C <content_root> pull --rebase 2>/dev/null || true</command>

      Based on the `git_workflow` setting from preferences.json (for the blog repo):

      <if condition="workflow-ask">
        <ask-user-question>
          <question>Would you like to commit and push this update?</question>
          <option>Yes (commit + push)</option>
          <option>Commit only</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow-auto">Automatically `git add`, `git commit -m "Update post: <title>"`, and `git push`.</if>
      <if condition="workflow-manual">Tell the user the file has been updated and they can commit when ready.</if>
    </git-workflow>
  </step>

</steps>
