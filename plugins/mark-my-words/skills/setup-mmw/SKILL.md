---
name: setup-mmw
description: Configure mark-my-words for your blog. Sets up platform, source location, and preferences.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

<purpose>
You are configuring the mark-my-words plugin for the user's blog. Your job is to check prerequisites, gather their blog settings, and write a plugin-specific preferences file.
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
    </load-config>

    <validate name="existing-preferences">
      <action>Check if `<home>/.things/mark-my-words/preferences.json` already exists.</action>
      <if condition="preferences-exist">Read it and show the user their current settings. Ask if they want to reconfigure.</if>
    </validate>
  </step>

  <step id="select-platform" number="2">
    <description>Select Platform</description>

    <ask-user-question>
      <question>Which blogging platform do you use?</question>
      <option>Quartz -- Obsidian-compatible static site (wikilinks, callouts, Mermaid)</option>
      <option>Hugo -- Popular Go-based static site generator</option>
      <option>Jekyll -- Ruby-based, GitHub Pages default</option>
      <option>Astro -- Modern web framework with content collections</option>
      <option>Eleventy (11ty) -- Flexible JavaScript-based static site generator</option>
      <option>Docusaurus -- React-based docs and blog platform (admonitions, MDX)</option>
      <option>Zola -- Fast Rust-based static site generator (TOML frontmatter)</option>
    </ask-user-question>

    <constraint>Store the selection as the `platform` value (lowercase: `quartz`, `hugo`, `jekyll`, `astro`, `eleventy`, `docusaurus`, `zola`).</constraint>

    <action>Read the platform template from `<plugin_root>/platforms/<platform>.md` to get platform-specific defaults for the steps below. Use the "Platform Info" table and "Frontmatter" section to inform your suggestions.</action>
  </step>

  <step id="gather-source-info" number="3">
    <description>Gather Blog Source Info</description>

    <ask-user-question>
      <question>Where does your blog content live?</question>
      <option>Remote git repo -- I'll provide a repo URL and branch</option>
      <option>Local directory -- I'll provide a path to my content root</option>
    </ask-user-question>
  </step>

  <step id="source-details" number="4">
    <description>Source Details</description>

    <if condition="source-type-remote">
      <ask-user-question>
        <question>Remote repo details</question>
        <option-with-text-input>Repository URL (e.g., `git@github.com:user/blog.git` or HTTPS URL)</option-with-text-input>
        <option-with-text-input>Branch name (suggest `main` as default)</option-with-text-input>
      </ask-user-question>
    </if>

    <if condition="source-type-local">
      <ask-user-question>
        <question>Path to your content root directory</question>
      </ask-user-question>
    </if>
  </step>

  <step id="content-preferences" number="5">
    <description>Gather Content Preferences</description>

    <constraint>Use the platform template's "Platform Info" table to suggest sensible defaults.</constraint>

    <ask-user-question>
      <question>Content directory name (the root content directory)</question>
      <platform-specific platform="quartz">`content`</platform-specific>
      <platform-specific platform="hugo">`content`</platform-specific>
      <platform-specific platform="jekyll">`_posts` (note: Jekyll also uses `_drafts` for draft posts)</platform-specific>
      <platform-specific platform="astro">`src/content/blog`</platform-specific>
      <platform-specific platform="eleventy">varies -- ask the user (common: `src/posts`, `content`, `posts`)</platform-specific>
      <platform-specific platform="docusaurus">`blog`</platform-specific>
      <platform-specific platform="zola">`content`</platform-specific>
    </ask-user-question>

    <ask-user-question>
      <question>Default subdirectory (where new posts go within the content directory)</question>
      <platform-specific platform="quartz">flexible (`blog/`, `notes/`, or empty)</platform-specific>
      <platform-specific platform="hugo">`posts/` or `blog/`</platform-specific>
      <platform-specific platform="jekyll">empty (posts go directly in `_posts/`)</platform-specific>
      <platform-specific platform="astro">empty (posts go directly in blog collection)</platform-specific>
      <platform-specific platform="eleventy">empty (posts go directly in posts directory)</platform-specific>
      <platform-specific platform="docusaurus">empty (posts go directly in `blog/`)</platform-specific>
      <platform-specific platform="zola">`blog/` (organized as sections)</platform-specific>
    </ask-user-question>

    <ask-user-question>
      <question>Default tags (comma-separated list of tags you commonly use, suggested when creating posts)</question>
    </ask-user-question>
  </step>

  <step id="git-workflow-preference" number="6">
    <description>Git Workflow Preference</description>

    <ask-user-question>
      <question>Git workflow for blog changes</question>
      <option>Always ask -- prompt before each commit/push</option>
      <option>Auto-commit -- automatically commit and push after changes</option>
      <option>Manual -- never auto-commit, I handle git myself</option>
    </ask-user-question>
  </step>

  <step id="media-preferences" number="7">
    <description>Media Preferences</description>

    <ask-user-question>
      <question>Where should images and media files be stored? (path relative to your content directory)</question>
      <platform-specific platform="quartz">`assets/images`</platform-specific>
      <platform-specific platform="hugo">`static/images` (note: Hugo serves `static/` at site root)</platform-specific>
      <platform-specific platform="jekyll">`assets/images`</platform-specific>
      <platform-specific platform="astro">`public/images`</platform-specific>
      <platform-specific platform="eleventy">`img` or `images`</platform-specific>
      <platform-specific platform="docusaurus">`static/img`</platform-specific>
      <platform-specific platform="zola">`static/images`</platform-specific>
      <option>Skip -- no local media management</option>
    </ask-user-question>
    <if condition="user-skips-media">Set `media_dir: null`.</if>

    <ask-user-question>
      <question>Should mark-my-words proactively suggest diagrams and images as it writes?</question>
      <option>Yes -> `auto_suggest_visuals: true`</option>
      <option>No -> `auto_suggest_visuals: false`</option>
    </ask-user-question>

    <ask-user-question>
      <question>Do you want the option to generate images with AI tools?</question>
      <option>Yes -> `ai_image_generation: true`</option>
      <option>No -> `ai_image_generation: false`</option>
    </ask-user-question>
  </step>

  <step id="write-preferences" number="8">
    <description>Create Plugin Directory and Write Preferences</description>

    <action>Create the plugin directory structure.</action>
    <command language="bash" tool="Bash">mkdir -p <home>/.things/mark-my-words/voices</command>

    <action>Write `<home>/.things/mark-my-words/preferences.json` with all blog settings.</action>
    <schema name="preferences">
    ```json
    {
      "platform": "<platform>",
      "source_type": "<remote|local>",
      "repo_url": "<url or null>",
      "repo_branch": "<branch or null>",
      "local_path": "<path or null>",
      "content_dir": "<dir>",
      "default_subdirectory": "<subdir>",
      "default_tags": ["<tag>", ...],
      "git_workflow": "<ask|auto|manual>",
      "workdir": "<home>/.mark-my-words",
      "default_voice": null,
      "media_dir": "<path or null>",
      "auto_suggest_visuals": <true|false>,
      "ai_image_generation": <true|false>
    }
    ```
    </schema>
  </step>

  <step id="register-voices" number="9">
    <description>Register Voice Collection</description>

    <read path="<home>/.things/registry.json" output="registry" />

    <if condition="registry-exists">
      <action>Add (or update) the `mark-my-words/voices` entry in the `collections` object.</action>
    </if>

    <schema name="voice-registry">
    ```json
    {
      "collections": {
        "mark-my-words/voices": {
          "type": "voices",
          "path": "mark-my-words/voices",
          "description": "Blog writing voice profiles"
        }
      }
    }
    ```
    </schema>

    <if condition="registry-missing">Create it with the above structure.</if>
    <constraint>Preserve any existing entries.</constraint>
  </step>

  <step id="update-environment" number="10">
    <description>Update Environment Tracking</description>

    <action>Read `<home>/.things/config.json` and update the `plugins` object to record that mark-my-words is set up.</action>

    <schema name="plugin-registration">
    ```json
    {
      "plugins": {
        "mark-my-words": {
          "version": "4.0.1",
          "setup_at": "<ISO date>"
        }
      }
    }
    ```
    </schema>

    <constraint>Use Edit to merge this into the existing `plugins` object, preserving other plugin entries.</constraint>
  </step>

  <step id="git-workflow" number="11">
    <description>Handle Git Workflow</description>

    <git-workflow>
      <action>Read `git.workflow` from `<home>/.things/config.json` for the .things repo git workflow.</action>

      <if condition="workflow-ask">
        <ask-user-question>
          <question>Commit preferences to .things repo?</question>
          <option>Yes (commit + push)</option>
          <option>Commit only</option>
          <option>No</option>
        </ask-user-question>
      </if>
      <if condition="workflow-auto">Automatically `git -C <home>/.things add mark-my-words/ registry.json config.json && git -C <home>/.things commit -m "Set up mark-my-words plugin" && git -C <home>/.things push`.</if>
      <if condition="workflow-manual">Tell the user their preferences have been saved and they can commit when ready.</if>
    </git-workflow>
  </step>

  <step id="voice-profile" number="12">
    <description>Voice Profile (optional)</description>

    <ask-user-question>
      <question>Would you like to create a voice profile? Voice profiles teach mark-my-words how you actually write, so posts sound like you instead of generic AI.</question>
      <option>Yes -- set one up now</option>
      <option>Later -- I'll run `/create-voice` when I'm ready</option>
      <option>No thanks -- I'll skip voice profiles</option>
    </ask-user-question>

    <if condition="user-yes-voice">Tell the user to run `/create-voice` after setup completes -- it needs writing samples and works best as its own step. Note that they can create multiple voice profiles and switch between them.</if>
    <if condition="user-later-or-no-thanks">Move on.</if>
  </step>

  <step id="confirm" number="13">
    <description>Confirm</description>

    <completion-message>
      Tell the user their config has been saved and they can now use `/new-post`, `/update-post`, `/manage-post`, and `/add-media`.

      <if condition="user-said-yes-to-voice">Remind them:

      > Run `/create-voice` to set up your writing voice. Voice profiles are stored in `<home>/.things/mark-my-words/voices/` for cross-machine sync.

      </if>
    </completion-message>
  </step>

</steps>
