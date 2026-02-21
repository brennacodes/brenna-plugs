---
name: update-voice
description: "Refine an existing voice profile - add samples, adjust sections, or regenerate"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[voice name]"
---

<references>
  <reference name="voice-profile-format" path="../create-voice/references/voice-profile-format.md" />
</references>

<purpose>
You are helping the user refine an existing voice profile. They might want to add new writing samples, manually adjust sections, or regenerate the whole profile.
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
  </step>

  <step id="list-voices" number="2">
    <description>List Available Voices</description>

    <validate name="voices-exist">
      <action>Use Glob to find all `.md` files in `<home>/.things/mark-my-words/voices/`.</action>
      <if condition="no-voices-exist">Tell the user: "No voice profiles found. Run `/create-voice` to create one." Then stop.</if>
    </validate>
  </step>

  <step id="select-voice" number="3">
    <description>Select Voice</description>

    <if condition="arguments-provided">
      <action>Look for a matching profile in `<home>/.things/mark-my-words/voices/<argument>.md`.</action>
      <if condition="no-exact-match">Try fuzzy matching against available voice names.</if>
    </if>

    <if condition="no-arguments-or-no-match">
      <ask-user-question>
        <question>Which voice profile?</question>
        Show each voice's name and description (read from frontmatter).
      </ask-user-question>
    </if>
  </step>

  <step id="show-current-profile" number="4">
    <description>Show Current Profile</description>

    <read path="<home>/.things/mark-my-words/voices/<name>.md" output="profile" />
    <action>Display it to the user in full -- frontmatter and all body sections.</action>
  </step>

  <step id="choose-update-mode" number="5">
    <description>Choose Update Mode</description>

    <ask-user-question>
      <question>How do you want to update this voice?</question>
      <option>Add samples -- feed in more writing to sharpen the profile</option>
      <option>Manual adjust -- edit specific sections yourself</option>
      <option>Regenerate -- rebuild from scratch using all sources (existing + new)</option>
    </ask-user-question>
  </step>

  <step id="apply-update" number="6">
    <description>Apply Update</description>

    <if condition="user-add-samples">
      <phase name="add-samples" number="1">
        <action>Follow the same sample-gathering flow as create-voice Step 6 (file paths, paste, or both -- no URLs).</action>

        <action>After gathering new samples, re-analyze all sections in the context of both the existing profile and the new samples. The profile should evolve, not be replaced -- new patterns get added, existing ones get refined or confirmed.</action>

        <action>Update the `sample_sources` list in frontmatter to include the new sources. Update `last_updated` to today's date.</action>

        <constraint>Use Edit to update changed sections. Preserve sections that didn't change.</constraint>
      </phase>
    </if>

    <if condition="user-manual-adjust">
      <phase name="manual-adjust" number="2">
        <ask-user-question>
          <question>Which section(s) to update?</question>
          <option>1. Tone and Register</option>
          <option>2. Sentence Patterns</option>
          <option>3. Vocabulary and Diction</option>
          <option>4. Rhetorical Habits</option>
          <option>5. Structural Preferences</option>
          <option>6. Things to Avoid</option>
        </ask-user-question>

        <action>For each selected section, show the current content and use AskUserQuestion to get the user's changes. They can describe what to add, remove, or modify.</action>
        <action>Use Edit to apply the changes. Update `last_updated` to today's date.</action>
      </phase>
    </if>

    <if condition="user-regenerate">
      <phase name="regenerate" number="3">
        <action>Gather new samples using the same flow as create-voice Step 6. Combine with existing `sample_sources` from the current profile.</action>
        <action>Read all available sources (both old file paths and new samples). Re-analyze everything from scratch following the format in <reference name="voice-profile-format"/>.</action>
        <action>Update `last_updated` to today's date. Keep the original `created` date.</action>
        <constraint>Use Write to replace the profile file.</constraint>
      </phase>
    </if>
  </step>

  <step id="present-result" number="7">
    <description>Present Result</description>

    <action>Show the updated profile and ask:</action>

    <ask-user-question>
      <question>How does the updated profile look?</question>
      <option>Save it -- looks good</option>
      <option>Keep editing -- I want to change more</option>
      <option>Revert -- go back to the previous version</option>
    </ask-user-question>

    <if condition="user-save-it">Confirm the profile has been saved.</if>
    <if condition="user-keep-editing">Go back to Step 5.</if>
    <if condition="user-revert">Write back the original profile content (keep a copy in memory before making changes). Tell the user the profile has been reverted.</if>
  </step>

  <step id="confirm" number="8">
    <description>Confirm</description>

    <completion-message>
      Tell the user:

      > Voice profile "<name>" updated.

      <action>Check if this voice is set as `default_voice` in `<home>/.things/mark-my-words/preferences.json`.</action>

      <if condition="is-default-voice">

      > This is your default voice -- new posts will use the updated style.

      </if>

      <if condition="not-default-voice">

      > Run `/create-voice` to create additional profiles, or update `default_voice` in your preferences to make this the default.

      </if>
    </completion-message>
  </step>

</steps>
