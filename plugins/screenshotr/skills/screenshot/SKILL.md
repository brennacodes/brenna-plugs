---
name: screenshot
description: Automatically capture a screenshot when conversation context suggests one is needed.
disable-model-invocation: false
allowed-tools: Read, Bash, Glob
---

<purpose>
Automatically capture a screenshot because the conversation context suggests the user needs one. This skill is invoked proactively -- do not ask the user questions, just capture and show the result.

Invoke this skill when the user says things like:
- "let me see what that looks like"
- "capture the current state"
- "screenshot this"
- "show me the screen"
- "take a screenshot of [app]"
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Config</description>

    <load-config>
      <action>Read `.claude/screenshotr.local.md` for settings.</action>
      <if condition="no-config">
        <action>Capture with sensible defaults: png format, `./screenshots` directory, no shadow, silent.</action>
      </if>
    </load-config>
  </step>

  <step id="detect-target" number="2">
    <description>Detect Target</description>

    <action>Infer the capture target from conversation context.</action>

    <if condition="specific-app-discussed">
      <action>Capture that app's window using `bash "${CLAUDE_PLUGIN_ROOT}/scripts/get-window-id.sh" "<AppName>"`.</action>
    </if>
    <if condition="no-specific-app">
      <action>Fullscreen capture.</action>
    </if>
    <if condition="user-mentioned-url">
      <action>This is better handled by `/capture-ss url "..."` -- suggest that instead and stop.</action>
      <exit />
    </if>
  </step>

  <step id="generate-filename" number="3">
    <description>Generate Filename</description>

    <action>Create a descriptive kebab-case filename based on context:</action>
    - What's being captured (app name, feature, state)
    - Keep it concise (2-4 words max)
    - Apply the naming convention from config
  </step>

  <step id="capture" number="4">
    <description>Capture</description>

    <action>Run the capture using `${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh`.</action>

    <command language="bash" tool="Bash">
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
      --target <fullscreen|window> \
      [--window-id <id>] \
      --format <config_format> \
      --silent \
      [--no-shadow] \
      [--resize <config_max_dimension>] \
      --output "<output_dir>/<filename>.<ext>"
    </command>

    <constraint>Apply `default_max_dimension` from config if set (and it's a number, not "ask").</constraint>
  </step>

  <step id="display-result" number="5">
    <description>Display Result</description>

    <action>Parse the `OK|path|WxH|bytes|format` output from `capture.sh`.</action>

    <action>Report the file path and dimensions briefly, then use the Read tool to display the image so the user can see it inline.</action>

    <if condition="capture-failed">
      <action>Report the error without being verbose. Suggest running `/setup-ss` if config is missing, or `/list-windows` if window detection failed.</action>
    </if>
  </step>

</steps>
