---
name: new-post
description: Create a new blog post via guided interview.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion, WebSearch, WebFetch
argument-hint: "[topic or idea]"
---

<references>
  <reference name="media-guide" path="../add-media/references/media-guide.md" />
</references>

<purpose>
You are creating a new blog post for the user. Use a structured interview to gather requirements, then generate a well-crafted post following their platform's conventions.
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

    <action>Read `platform` from preferences.json (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines all platform-specific formatting rules -- frontmatter fields, content syntax, image format, callouts, code blocks, and file naming conventions. Follow the template's rules throughout post generation.</action>

    <action>Load voice profile.</action>
    <if condition="default-voice-set">
      <read path="<home>/.things/mark-my-words/voices/<default_voice>.md" output="voice" />
      <if condition="voice-file-missing">Warn the user that their default voice profile is missing and continue without a voice.</if>
    </if>
    <action>Also check if any voice profiles exist in `<home>/.things/mark-my-words/voices/` using Glob. Store this for the interview step.</action>

    <action>Resolve media directory.</action>
    <if condition="media-dir-set">Resolve the full media path as `<content_root>/<media_dir>` and ensure the directory exists (`mkdir -p`). Store this path for use in the writing and media processing steps.</if>
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

  <step id="scan-existing-posts" number="3">
    <description>Scan Existing Posts</description>

    <action>Use Glob and Grep to scan the content directory:</action>
    - Find all `.md` files in the target subdirectory
    - Extract existing tags from frontmatter across posts (look for `tags:` in YAML frontmatter, or `tags = [` for TOML platforms like Zola)
    - Note the directory structure for suggesting where to place the new post
    - This informs tag suggestions and helps maintain consistency
  </step>

  <step id="interview-user" number="4">
    <description>Interview the User</description>

    Use AskUserQuestion for each of these, adapting based on `$ARGUMENTS` if provided:

    <ask-user-question>
      <question>Post title</question>
      <if condition="arguments-provided">Suggest a title based on it.</if>
      Let the user accept, modify, or provide their own. Keep it concise and engaging.
    </ask-user-question>

    <ask-user-question>
      <question>Target length</question>
      <option>Short (~500 words) -- quick tip, TIL, brief note</option>
      <option>Medium (~1000 words) -- tutorial, explanation, walkthrough</option>
      <option>Long (~2000+ words) -- deep dive, comprehensive guide</option>
    </ask-user-question>

    <ask-user-question>
      <question>Key points/sections: What should the post cover? What are the main things the reader should learn or take away?</question>
      Let the user describe in their own words.
    </ask-user-question>

    <ask-user-question>
      <question>Tags</question>
      Present a combined list of:
      - Tags found in existing posts
      - The user's `default_tags` from preferences.json
      - Allow the user to pick multiple and/or add custom tags
    </ask-user-question>

    <ask-user-question>
      <question>Target directory</question>
      Show the default from preferences.json (`default_subdirectory`). Let them override if they want to put it elsewhere.
    </ask-user-question>

    <action>Voice selection (only if voice profiles exist in `<home>/.things/mark-my-words/voices/`).</action>
    <if condition="default-voice-set">Show it and ask if they want to use it, pick a different one, or skip voice for this post.</if>
    <if condition="no-default-voice">List available voices and let them pick one or skip.</if>
    <if condition="only-one-voice">Just confirm they want to use it.</if>

    <ask-user-question>
      <question>Draft status</question>
      <option>Publish immediately (`draft: false`, or platform-specific equivalent like `published: true` for Jekyll)</option>
      <option>Save as draft (`draft: true`, or place in `_drafts/` for Jekyll)</option>
    </ask-user-question>

    <if condition="media-dir-configured">
      <ask-user-question>
        <question>Visuals</question>
        <option>I have specific images (file paths or URLs)</option>
        <option>Find relevant images for me</option>
        <option>Generate Mermaid diagrams for visual concepts (only if the platform template indicates Mermaid support)</option>
        <option>No visuals for this post</option>
        <option>Decide as we write</option>
      </ask-user-question>
      <if condition="user-provides-images">Collect paths/URLs and descriptions for processing in Step 5.5.</if>
      <if condition="user-web-search">Note topics to search during writing.</if>
      <if condition="user-mermaid">Actively generate diagrams where they fit during Step 5.</if>
      <if condition="user-decide-as-we-write">Activate auto-suggest behavior for this post regardless of the `auto_suggest_visuals` config setting.</if>
    </if>
  </step>

  <step id="write-post" number="5">
    <description>Write the Post</description>

    <action>Generate the blog post following the platform template loaded in Step 1.</action>

    <action>Generate platform-compatible frontmatter following the template:</action>
    - Use the platform's frontmatter format (YAML `---` or TOML `+++`)
    - Use the platform's field names (e.g., `pubDate` for Astro, `date` for most others)
    - `title`: From the interview
    - Date: Today's date in the platform's expected format
    - `description`: 1-2 sentence preview for SEO/social
    - Tags: From the interview, using the platform's tag format
    - Draft status: From the interview (or platform equivalent)
    - Author: From professional profile or config.json

    <if condition="voice-profile-selected">Follow its guidance for tone, sentence patterns, vocabulary, rhetorical habits, structure, and things to avoid. The voice profile takes precedence over generic style defaults -- write as the profile describes, not in a generic "natural, engaging" voice.</if>
    <if condition="no-voice-profile">Write in a natural, engaging voice.</if>
    <action>Use clear heading hierarchy (h2 for sections, h3 for subsections). Include code blocks with language identifiers when relevant.</action>

    <action>Use the platform's native content features as documented in the template.</action>
    <if condition="platform-supports-callouts">Use them where they add value.</if>
    <if condition="platform-no-callouts">Use emphasized text or blockquotes instead.</if>
    <action>Use the platform's native code block features (title, line highlighting) where appropriate.</action>

    <constraint name="length">Match the target length the user selected.</constraint>
    <constraint name="structure">Start with a brief intro, organize into logical sections based on the user's key points, end with a conclusion or summary.</constraint>

    <phase name="inline-visual-integration" number="1">
      <constraint>When `auto_suggest_visuals` is true in preferences.json or the user chose "Decide as we write", integrate visuals as you draft each section. Consult <reference name="media-guide"/> for detection patterns and placement rules.</constraint>

      <action>Auto-detection: As you write each section, detect:</action>
      - Architecture descriptions -> Mermaid flowchart with subgraphs (only if platform supports Mermaid)
      - Workflows and processes -> Mermaid flowchart or sequence diagram (only if platform supports Mermaid)
      - Comparisons -> table or side-by-side diagram
      - Data and metrics -> formatted table or chart description
      - Visual concepts that need an actual image -> placeholder comment: `<!-- TODO: add image of [description] -->`

      <if condition="user-gave-file-paths-or-urls">Reference user-provided images using the platform's image syntax (from the template). Place images after the text that introduces the concept.</if>
      <if condition="user-asked-to-find-images">Use WebSearch (try `site:unsplash.com <topic>` or `creative commons <topic> photo`), then use WebFetch to verify the image URL works. Download with `curl -L -o` to the media dir using a descriptive kebab-case filename. Always include alt text.</if>

      <if condition="ai-image-generation-enabled">
        <action>Check for available image generation tools.</action>
        <if condition="generation-tools-available">Ask the user to confirm before generating.</if>
        <if condition="no-generation-tools">Gracefully skip and suggest a web search or placeholder instead.</if>
      </if>
    </phase>

    <phase name="inline-links" number="2">
      <action>Use WebSearch to find accurate URLs as you write. Link things inline where a reader would genuinely benefit from the reference:</action>

      <constraint name="quoted-text">Quoted or cited text -- always link to the original source. If you're quoting a person, article, talk, book, tweet, or documentation, the quote gets a link.</constraint>
      <constraint name="tools-and-libs">Tools, libraries, frameworks, protocols, specs -- link on first mention when the reader might want to explore them. A post about building with Astro should link to Astro's site; a post mentioning HTTP doesn't need a link to the HTTP spec.</constraint>
      <constraint name="people">People -- link when who they are matters to the post. If you're referencing someone's specific work, opinion, or contribution, link to their relevant page (personal site, talk, paper). Don't link household names just because they exist.</constraint>
      <constraint name="companies">Companies and products -- only link when they're directly relevant to the post's substance, not just mentioned in passing.</constraint>
      <constraint name="papers-and-posts">Papers, blog posts, docs -- link when you're drawing on them or recommending them.</constraint>
      <constraint name="link-philosophy">The goal is useful links, not comprehensive ones. When in doubt, skip it.</constraint>
    </phase>

    <phase name="mentioned-in-post" number="3">
      <template name="mentioned-in-post">
        After the post's conclusion, add a `---` horizontal rule followed by a section:

        ```markdown
        ---

        ## Mentioned in this post

        - [Thing Name](https://example.com) - one-line description of what it is and why it's relevant
        - [Another Thing](https://example.com) - brief context
        ```
      </template>

      <constraint>Include items that a reader might want to explore further -- tools, libraries, articles, people's work, specs, or projects that played a meaningful role in the post. This is a curated list, not an exhaustive index.</constraint>
      <constraint>Skip anything that was only mentioned in passing or that everyone already knows how to find. Aim for 3-8 items; if the post only has 1-2, skip the section entirely.</constraint>
    </phase>
  </step>

  <step id="process-media-files" number="5.5">
    <description>Process Media Files</description>

    <constraint>Only run this step if the user requested images (provided files, web search, or AI generation) and `media_dir` is configured.</constraint>

    <action>Ensure media directory exists.</action>
    <command language="bash" tool="Bash">mkdir -p <content_root>/<media_dir></command>

    <action>Copy local files: For each user-provided local file, copy it to the media dir. Rename generic filenames (like `IMG_4523.png`, `Screenshot 2025-01-15.png`) to descriptive kebab-case names based on the image content or context.</action>
    <action>Download remote images: For each URL collected during writing, download with `curl -L -o <media_dir>/<descriptive-filename> <url>`.</action>
    <action>Update image references: Ensure all image references in the post use the platform's image syntax from the template (e.g., wikilinks for Quartz, standard markdown for others).</action>
    <action>Summarize: Tell the user what was processed -- files copied, images downloaded, references updated.</action>
  </step>

  <step id="save-file" number="6">
    <description>Save the File</description>

    <action>Generate a filename following the platform's naming convention from the template:</action>
    <platform-specific platform="jekyll">`YYYY-MM-DD-slug.md` (date prefix required)</platform-specific>
    <platform-specific platform="all-others">`slug.md` (lowercase, hyphens for spaces, no special characters)</platform-specific>

    <write path="<content_root>/<target_subdirectory>/<filename>.md" />
    <if condition="jekyll-draft">Write to `<content_root>/../_drafts/<slug>.md` (no date prefix needed in `_drafts/`).</if>

    <action>Tell the user the file path.</action>
  </step>

  <step id="git-workflow" number="7">
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
      <if condition="workflow-auto">Automatically `git add`, `git commit -m "Add post: <title>"`, and `git push`.</if>
      <if condition="workflow-manual">Tell the user the file has been written and they can commit when ready.</if>

      <constraint>When committing, `git add` both the post file and any media files added to the media directory.</constraint>
      <if condition="content-not-in-git-repo">Skip git operations.</if>
    </git-workflow>
  </step>

</steps>
