---
name: manage-post-mmw
description: List, search, and manage your blog posts - drafts, tags, and metadata.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[action: list, drafts, publish, tags]"
---

<purpose>
You are helping the user manage their blog posts. This includes listing posts, managing drafts, publishing, and organizing tags.
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

    <action>Read `platform` from preferences.json (default to `quartz` if not set). Read the platform template from `../../platforms/<platform>.md` (relative to this skill's directory). This template defines how drafts work and frontmatter field names for the user's platform.</action>
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

  <step id="determine-action" number="3">
    <description>Determine Action</description>

    <action>Check `$ARGUMENTS` for the requested action.</action>
    <if condition="action-not-provided">
      <ask-user-question>
        <question>What would you like to do?</question>
        <option>list -- Show all posts with metadata</option>
        <option>drafts -- Show draft posts and offer to publish</option>
        <option>publish -- Publish a specific draft post</option>
        <option>tags -- View and manage tags across all posts</option>
      </ask-user-question>
    </if>
  </step>

  <step id="execute-action" number="4">
    <description>Execute the Action</description>

    <phase name="list-posts" number="1">
      <description>Action: list</description>

      <action>Scan all `.md` files in the content directory. For each post, extract from frontmatter:</action>
      - Title
      - Date (field name varies by platform -- check template)
      - Draft status (varies by platform -- see draft detection below)
      - Tags (YAML `tags:` list, or TOML `tags = []` for Zola, or `[taxonomies]` table)
      - Calculate word count from content body

      <action>Detect draft status by platform:</action>
      <platform-specific platform="jekyll">A post is a draft if it's in the `_drafts/` directory OR has `published: false` in frontmatter.</platform-specific>
      <platform-specific platform="zola-hugo-quartz-astro-eleventy">`draft: true` in frontmatter (or `draft = true` for TOML).</platform-specific>
      <platform-specific platform="docusaurus">`draft: true` in frontmatter.</platform-specific>

      <template name="post-list-output">
        Display as a formatted table or list, sorted by date (newest first):

        ```
        | Title                    | Date       | Status    | Tags                  | Words |
        |--------------------------|------------|-----------|-----------------------|-------|
        | Building a CLI in Go     | 2025-01-15 | published | go, cli, tutorial     | 1,245 |
        | Learning Rust            | 2025-01-10 | draft     | rust, learning        |   832 |
        ```
      </template>

      <action>Show summary stats: total posts, published count, draft count.</action>
    </phase>

    <phase name="manage-drafts" number="2">
      <description>Action: drafts</description>

      <action>Scan all `.md` files and identify drafts using the platform-specific draft detection described above. For Jekyll, also scan the `_drafts/` directory.</action>
      <action>Display the drafts with title, date, tags, and word count.</action>

      <if condition="drafts-exist">
        <ask-user-question>
          <question>Would you like to publish any of these drafts?</question>
          List each draft by title, plus "No, just looking."
        </ask-user-question>
      </if>

      <if condition="user-selects-draft">Apply the platform-specific publish action:</if>

      <platform-specific platform="jekyll-in-drafts">
        1. Read the file
        2. Add a `date` field in frontmatter if not present (today's date)
        3. Move the file to `_posts/` with the date-prefixed filename: `YYYY-MM-DD-slug.md`
        4. Handle git workflow per preferences.json
      </platform-specific>

      <platform-specific platform="jekyll-published-false">
        1. Read the file
        2. Change `published: false` to `published: true`
        3. Ask about date update
        4. Handle git workflow per preferences.json
      </platform-specific>

      <platform-specific platform="not-jekyll">
        1. Read the file
        2. Change `draft: true` to `draft: false` (or `draft = false` for TOML)
        3. Ask: "Update the date to today?" -- Yes or Keep original date
        4. If yes, update the date field (using the platform's field name)
        5. Write the changes
        6. Handle git workflow per preferences.json
      </platform-specific>
    </phase>

    <phase name="publish-post" number="3">
      <description>Action: publish</description>

      <if condition="arguments-include-post-identifier">Search for matching draft posts.</if>
      <if condition="no-specific-post">Behave like `drafts` action above.</if>

      <if condition="specific-post-found">
        <ask-user-question>
          <question>Publish '<title>'?</question>
          <option>Yes</option>
          <option>No</option>
        </ask-user-question>
        <action>Apply the platform-specific publish action (same as drafts above).</action>
      </if>

      <if condition="post-already-published">Tell the user.</if>
    </phase>

    <phase name="manage-tags" number="4">
      <description>Action: tags</description>

      <action>Scan all `.md` files and extract all tags from frontmatter. For TOML-based platforms (Zola), look for tags in the `[taxonomies]` table.</action>

      <template name="tag-summary-output">
        Display tag summary: List each unique tag with how many posts use it, sorted by count:

        ```
        | Tag          | Posts |
        |--------------|-------|
        | programming  |    12 |
        | tutorial     |     8 |
        | python       |     6 |
        | learning     |     3 |
        ```
      </template>

      <ask-user-question>
        <question>What would you like to do with tags?</question>
        <option>Add a tag to posts -- select a tag, then select which posts to add it to</option>
        <option>Remove a tag from posts -- select a tag, show which posts have it, select which to remove from</option>
        <option>Rename a tag -- rename a tag across all posts that use it</option>
        <option>Done -- exit</option>
      </ask-user-question>

      <action>For tag modifications:</action>
      1. Read each affected file
      2. Update the tags in frontmatter using the platform's format (YAML list or TOML array)
      3. Write the changes
      4. Handle git workflow per preferences.json (batch all tag changes into one commit if auto)
    </phase>
  </step>

  <step id="git-workflow" number="5">
    <description>Git Workflow</description>

    <git-workflow>
      <action>Before committing, pull latest changes from the remote (if one exists) to avoid conflicts.</action>
      <command language="bash" tool="Bash">git -C <content_root> pull --rebase 2>/dev/null || true</command>

      After any modifications, handle git based on `git_workflow` from preferences.json (for the blog repo):

      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit and push these changes?</question>
          <option>Yes (commit + push)</option>
          <option>Commit only</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow-auto">Auto commit with descriptive message and push.</if>
      <if condition="workflow-manual">Inform user that changes are saved locally.</if>
    </git-workflow>
  </step>

</steps>
