---
name: add-media
description: Add images, diagrams, and video embeds to an existing blog post.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[post filename or search term]"
---

<references>
  <reference name="media-guide" path="references/media-guide.md" />
</references>

<purpose>
You are adding rich media -- diagrams, images, and video embeds -- to an existing blog post. Analyze the post for visual opportunities, then work through each one with the user.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/setup-htt` first." Then stop.</if>

      <read path="<home>/.things/mark-my-words/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-mmw` first." Then stop.</if>
    </load-config>

    <action>Read `platform` from preferences.json (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines the platform's image syntax, diagram support, and video embed conventions. Use it for all media insertion.</action>

    <action>Resolve `media_dir`.</action>
    <if condition="media-dir-configured">Compute the full path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`).</if>
    <if condition="media-dir-null">
      <ask-user-question>
        <question>No media directory is configured. You can still add inline content like Mermaid diagrams and video embeds. For images, would you like to:</question>
        <option>Provide a one-time media directory path for this session</option>
        <option>Continue without image support (diagrams and embeds only)</option>
      </ask-user-question>
      <if condition="user-provides-path">Use it for this session but don't update the preferences file.</if>
    </if>
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
        Show title, date, and filename for each.
      </ask-user-question>
    </if>

    <if condition="no-matches">Tell the user and suggest checking the filename or trying a different search term.</if>
  </step>

  <step id="analyze-post" number="4">
    <description>Analyze the Post</description>

    <action>Read the full post content and scan for visual opportunities using the detection patterns from <reference name="media-guide"/>.</action>

    <validate name="diagram-candidates">Processes, architectures, workflows, decision logic, state changes, request/response flows, data models (only suggest Mermaid diagrams if the platform template indicates Mermaid support).</validate>
    <validate name="image-candidates">UI references, visual concepts, results/screenshots, before/after comparisons.</validate>
    <validate name="table-candidates">Comparisons, structured data, feature lists.</validate>
    <validate name="video-candidates">References to talks, demos, tutorials, recordings.</validate>

    <template name="visual-opportunities-output">

    > **Visual opportunities found:**
    >
    > **"How Authentication Works" (line 24)**
    > - Diagram: the login flow described here would work well as a sequence diagram
    >
    > **"Architecture Overview" (line 45)**
    > - Diagram: the three-service architecture could be a flowchart with subgraphs
    > - Image: the system diagram mentioned could be a screenshot or architecture image
    >
    > **"Results" (line 78)**
    > - Image: before/after comparison of the dashboard redesign
    >
    > **"Demo" (line 92)**
    > - Video: the conference talk mentioned could be embedded

    </template>

    <ask-user-question>
      <question>What would you like to do?</question>
      <option>Accept all suggestions</option>
      <option>Pick and choose which ones to add</option>
      <option>Add my own images/media instead</option>
      <option>Skip specific suggestions</option>
    </ask-user-question>
  </step>

  <step id="process-media" number="5">
    <description>Process Media</description>

    Work through each selected item one at a time.

    <phase name="mermaid-diagrams" number="1">
      <constraint>Only available if the platform template indicates Mermaid support (native or plugin-based).</constraint>

      <action>Read the relevant section carefully.</action>
      <action>Generate Mermaid diagram code following the syntax in <reference name="media-guide"/>.</action>
      <action>Show the diagram code to the user for review.</action>

      <ask-user-question>
        <question>Does this diagram look right?</question>
        <option>Looks good</option>
        <option>Revise it</option>
        <option>Skip this one</option>
      </ask-user-question>

      <if condition="diagram-approved">Use Edit to insert the diagram after the text that introduces the concept.</if>
      <if condition="diagram-revision-requested">Adjust and show again.</if>
    </phase>

    <phase name="user-provided-images" number="2">
      <action>Ask for the file path or URL and a description.</action>
      <action>Generate a descriptive kebab-case filename if the original name is generic.</action>
      <action>Generate concise alt text from the description.</action>
      <if condition="local-file">Copy to media dir with `cp`.</if>
      <if condition="remote-url">
        <command language="bash" tool="Bash">curl -L -o <media_dir>/<filename> <url></command>
      </if>
      <action>Insert the image reference using the platform's syntax from the template (e.g., `![[filename|alt text]]` for Quartz, `![alt text](path/filename)` for others).</action>
      <action>Place it following the placement rules in <reference name="media-guide"/>.</action>
    </phase>

    <phase name="web-search-images" number="3">
      <action>Ask the user for the topic or description of what they're looking for.</action>
      <action>Use WebSearch to find relevant images (search `site:unsplash.com <topic>` or `creative commons <topic> photo`).</action>
      <action>Present 2-3 options with descriptions.</action>
      <action>Download the selected image.</action>
      <command language="bash" tool="Bash">curl -L -o <media_dir>/<descriptive-filename> <url></command>
      <action>Generate alt text and insert the reference using the platform's image syntax.</action>
      <constraint>Always include alt text describing the image content.</constraint>
    </phase>

    <phase name="ai-generated-images" number="4">
      <constraint>Only offer this if `ai_image_generation: true` in preferences.json.</constraint>

      <action>Check if image generation tools are available (e.g., Hugging Face MCP tools).</action>
      <if condition="no-generation-tools">Tell the user and offer alternatives (web search, placeholder, skip).</if>
      <if condition="generation-tools-available">Ask the user to describe what they want.</if>

      <ask-user-question>
        <question>Generate an image of [description]?</question>
        <option>Yes</option>
        <option>No</option>
      </ask-user-question>

      <action>Generate the image and save to media dir.</action>
      <action>Insert the reference with alt text using the platform's image syntax.</action>

      <if condition="ai-image-generation-disabled">Do not offer this option.</if>
    </phase>

    <phase name="video-embeds" number="5">
      <action>Ask for the video URL (YouTube or Vimeo).</action>
      <action>Extract the video ID from the URL.</action>
      <action>Resolve the embed syntax from the platform template:</action>
      <platform-specific platform="hugo">`{{</* youtube VIDEO_ID */>}}` or `{{</* vimeo VIDEO_ID */>}}`</platform-specific>
      <platform-specific platform="zola">`{{ youtube(id="VIDEO_ID") }}` or `{{ vimeo(id="VIDEO_ID") }}`</platform-specific>
      <platform-specific platform="all-others">Use HTML iframe embed.</platform-specific>
      <action>Ask the user for a title/description for the video.</action>
      <action>Insert a context sentence before the embed and a fallback link after it.</action>
      <action>Use Edit to place the embed in the post.</action>
    </phase>
  </step>

  <step id="review-changes" number="6">
    <description>Review Changes</description>

    <action>After processing all selected media, read the updated post and show the user a summary.</action>

    <template name="media-summary">

    > **Media added:**
    > - Sequence diagram in "How Authentication Works" (line 26)
    > - Architecture flowchart in "Architecture Overview" (line 48)
    > - Downloaded `dashboard-before-after.png` (from unsplash.com)
    > - YouTube embed in "Demo" section

    </template>

    <ask-user-question>
      <question>What next?</question>
      <option>Done -- I'm happy with the changes</option>
      <option>Add more -- I want to add additional media</option>
      <option>Undo last -- remove the last media item added</option>
      <option>Start over -- revert all changes and try again</option>
    </ask-user-question>

    <if condition="user-add-more">Go back to Step 4 to re-analyze (the post now has some media, so the analysis will be different).</if>
    <if condition="user-undo-last">Use Edit to remove the last inserted media item and offer to continue or stop.</if>
    <if condition="user-start-over">Re-read the original post content (from git or backup) and return to Step 4.</if>
  </step>

  <step id="git-workflow" number="7">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Before committing, pull latest changes from the remote (if one exists) to avoid conflicts.</action>
      <command language="bash" tool="Bash">git -C <content_root> pull --rebase 2>/dev/null || true</command>

      Based on the `git_workflow` setting from preferences.json (for the blog repo):

      <if condition="workflow-ask">
        <ask-user-question>
          <question>Would you like to commit and push these media changes?</question>
          <option>Yes (commit + push)</option>
          <option>Commit only</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow-auto">Automatically `git add` the post and any media files, `git commit -m "Add media to post: <title>"`, and `git push`.</if>
      <if condition="workflow-manual">Tell the user the files have been updated and they can commit when ready.</if>

      <constraint>When committing, include both the updated post file and any new files in the media directory.</constraint>
    </git-workflow>
  </step>

</steps>
