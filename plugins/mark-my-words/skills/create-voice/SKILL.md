---
name: create-voice
description: "Create a voice profile from writing samples - teach mark-my-words how you actually write"
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[voice name]"
---

<references>
  <reference name="voice-profile-format" path="references/voice-profile-format.md" />
</references>

<purpose>
You are creating a voice profile from the user's writing samples. The profile will be a compact style guide that captures how they write -- not generic AI voice, their actual voice.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Configuration</description>

    <load-config>
      <action>Resolve the user's home directory.</action>
      <command language="bash" output="home" tool="Bash">echo $HOME</command>
      <constraint>Never pass `~` to the Read tool.</constraint>

      <read path="<home>/.things/config.json" output="config" />
      <if condition="config-missing">Tell the user: "Run `/things:setup` first." Then stop.</if>

      <read path="<home>/.things/mark-my-words/preferences.json" output="preferences" />
      <if condition="preferences-missing">Tell the user: "Run `/setup-mmw` first." Then stop.</if>
    </load-config>
  </step>

  <step id="ensure-voices-dir" number="2">
    <description>Ensure Voices Directory</description>

    <action>Check if `<home>/.things/mark-my-words/voices/` exists.</action>
    <if condition="voices-dir-missing">Create it.</if>
  </step>

  <step id="get-voice-name" number="3">
    <description>Get Voice Name</description>

    <if condition="arguments-provided">Use it as the voice name (convert to kebab-case: lowercase, hyphens for spaces, no special characters).</if>

    <if condition="no-arguments">
      <ask-user-question>
        <question>What should this voice profile be called?</question>
      </ask-user-question>
    </if>

    <constraint>Suggest names based on common patterns: `casual-tech`, `professional`, `personal-blog`, `tutorial-voice`. The name becomes the filename and identifier.</constraint>
  </step>

  <step id="check-existing-profile" number="4">
    <description>Check for Existing Profile</description>

    <validate name="profile-uniqueness">
      <action>Check if `<home>/.things/mark-my-words/voices/<name>.md` already exists.</action>

      <if condition="profile-exists">
        Tell the user:

        > A voice profile named "<name>" already exists. Use `/update-voice <name>` to refine it, or choose a different name.

        <ask-user-question>
          <question>What would you like to do?</question>
          <option>Choose a different name</option>
          <option>Overwrite the existing profile</option>
        </ask-user-question>

        <if condition="user-picks-different-name">Go back to Step 3.</if>
      </if>
    </validate>
  </step>

  <step id="get-description" number="5">
    <description>Get Description</description>

    <ask-user-question>
      <question>Describe this voice in one sentence. What does it sound like? (e.g., "Conversational technical writing with dry humor" or "Direct and opinionated, like explaining something to a friend")</question>
    </ask-user-question>
  </step>

  <step id="gather-writing-samples" number="6">
    <description>Gather Writing Samples</description>

    <ask-user-question>
      <question>How would you like to provide writing samples?</question>
      <option>Point to files -- I'll give you file paths or a glob pattern</option>
      <option>Paste text -- I'll paste samples directly into the chat</option>
      <option>Both -- files and pasted text</option>
    </ask-user-question>

    <constraint>You need enough samples to identify patterns. Aim for at least 2-3 samples, ideally 1000+ words total.</constraint>

    <if condition="user-point-to-files">
      <action>Use AskUserQuestion to get file paths or a glob pattern (e.g., `content/blog/*.md`, or specific paths).</action>
      <action>Use Glob to find matching files. Read each file.</action>

      <action>Track the source info:</action>
      <schema name="file-source">
      ```yaml
      - type: file
        path: <absolute path>
      ```
      </schema>

      For glob patterns, track as:
      <schema name="glob-source">
      ```yaml
      - type: glob
        pattern: "<pattern>"
        count: <number of files matched>
      ```
      </schema>
    </if>

    <if condition="user-paste-text">
      <action>Use AskUserQuestion to ask for their writing sample.</action>
      <ask-user-question>
        <question>What's this sample from? (e.g., "Blog post about React hooks", "README I wrote last week")</question>
      </ask-user-question>

      <schema name="paste-source">
      ```yaml
      - type: paste
        label: "<user's label>"
      ```
      </schema>

      <action>Ask if they have more samples. Repeat until they're done.</action>
    </if>

    <if condition="user-both">Do both flows above.</if>

    <constraint name="no-url-fetching">Do not fetch URLs.</constraint>
    <if condition="user-provides-url">Tell them:

    > Voice profiles work with local files and pasted text only -- no URL fetching. You can paste the content directly or save it to a file first.
    </if>
  </step>

  <step id="analyze-and-distill" number="7">
    <description>Analyze and Distill</description>

    <action>Read all the gathered samples carefully. Analyze the writing for patterns across the six profile sections defined in <reference name="voice-profile-format"/>:</action>

    1. Tone and Register -- formality, emotional range, reader relationship
    2. Sentence Patterns -- rhythm, length, distinctive structures
    3. Vocabulary and Diction -- word choice, technical level, characteristic phrases
    4. Rhetorical Habits -- how they explain, persuade, use humor
    5. Structural Preferences -- intros, sections, conclusions, formatting
    6. Things to Avoid -- anti-patterns that would break the voice

    <constraint>Be specific and concrete. Pull actual examples from the samples. Don't be generic -- "uses humor" is useless, "drops self-deprecating asides in parentheses after technical claims" is useful.</constraint>
  </step>

  <step id="present-for-review" number="8">
    <description>Present for Review</description>

    <action>Show the user the generated profile and ask:</action>

    <ask-user-question>
      <question>How does this look?</question>
      <option>Save it -- looks good</option>
      <option>Adjust it -- I want to tweak some sections</option>
      <option>Start over -- try again with different samples</option>
    </ask-user-question>

    <if condition="user-save-it">Continue to Step 9.</if>
    <if condition="user-adjust-it">Use AskUserQuestion to find out what to change. Update the profile and present again.</if>
    <if condition="user-start-over">Go back to Step 6.</if>
  </step>

  <step id="save-profile" number="9">
    <description>Save the Profile</description>

    <action>Write the profile to `<home>/.things/mark-my-words/voices/<name>.md` using the format from <reference name="voice-profile-format"/>.</action>

    Include:
    - Frontmatter with name, description, created date (today), last_updated (today), and sample_sources
    - All six body sections with the distilled analysis
  </step>

  <step id="set-as-default" number="10">
    <description>Set as Default?</description>

    <ask-user-question>
      <question>Should "<name>" be your default voice for new posts?</question>
      <option>Yes -- use this voice by default</option>
      <option>No -- I'll pick a voice when I need one</option>
    </ask-user-question>

    <if condition="user-yes-default">Read `<home>/.things/mark-my-words/preferences.json`, update `default_voice` to `<name>`, and write the file back.</if>
  </step>

  <step id="confirm" number="11">
    <description>Confirm</description>

    <completion-message>
      Tell the user:

      > Voice profile "<name>" saved to `<home>/.things/mark-my-words/voices/<name>.md`.

      <if condition="set-as-default">

      > It's now your default voice -- new posts will use this style automatically.

      </if>

      <if condition="not-set-as-default">

      > You can use it by picking it when creating a post, or set it as default later by updating `default_voice` in your preferences.
      >
      > Run `/update-voice <name>` to refine it with more samples.

      </if>
    </completion-message>
  </step>

</steps>
