---
name: capture
description: Capture a screenshot - full screen, specific window, region, URL, or display - with resize, crop, delay, and format control.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[target] [--format png|jpg|heic|pdf] [--resize WxH|MAX] [--delay N] [--crop WxH] [--name filename] [--no-shadow] [--display N]"
---

<references>
  <reference name="screencapture-reference" path="references/screencapture-reference.md" />
  <reference name="sips-reference" path="references/sips-reference.md" />
</references>

<purpose>
Capture a screenshot for the user. Parse their arguments, resolve the target, run the capture, post-process if needed, and display the result.

Read <reference name="screencapture-reference"/> and <reference name="sips-reference"/> for detailed flag and option information.
</purpose>

<steps>

  <step id="load-config" number="1">
    <description>Load Config</description>

    <load-config>
      <action>Read `.claude/screenshotr.local.md` to get the user's settings.</action>
      <if condition="no-config">
        <action>Tell the user: No configuration found. Please run `/setup-ss` first.</action>
        <exit />
      </if>
    </load-config>
  </step>

  <step id="parse-arguments" number="2">
    <description>Parse Arguments</description>

    <action>Parse `$ARGUMENTS` to determine target type and options. Arguments can be positional or flags.</action>

    <phase name="target-types" number="1">
      Target types (first positional argument or inferred):
      - `screen`, `fullscreen`, or no target specified -- fullscreen capture
      - `window "App Name"` or `window AppName` -- capture a specific app's window
      - `region x,y,w,h` -- capture a rectangular region
      - `url "https://..."` -- open URL in browser, wait, capture the browser window
      - `display N` -- capture a specific display
    </phase>

    <phase name="flags" number="2">
      Flags (override config defaults):
      - `--format <fmt>` -- output format (png, jpg, heic, pdf, tiff, gif)
      - `--resize <WxH|MAX>` -- resize after capture. Single number = max dimension (aspect-preserving). WxH = exact dimensions.
      - `--crop <WxH>` -- center-crop after capture
      - `--delay <N>` -- seconds to wait before capturing
      - `--name <filename>` -- custom filename (without extension)
      - `--no-shadow` -- exclude window shadow
      - `--out <path>` -- custom output directory (overrides config `output_dir`)
    </phase>
  </step>

  <step id="resolve-output-path" number="3">
    <description>Resolve Output Path</description>

    <substep name="directory">
      <description>Determine output directory</description>
      <action>Use `--out` if provided, otherwise use `output_dir` from config.</action>
    </substep>

    <substep name="filename">
      <description>Determine filename</description>
      <if condition="name-flag-given">
        <action>Use it (append format extension).</action>
      </if>
      <if condition="no-name-flag">
        Generate based on the config's `naming` setting:
        - `descriptive`: Generate a kebab-case name from context -- the app name, window title, or what's being captured (e.g., `safari-github-homepage.png`, `fullscreen-desktop.png`)
        - `timestamp`: `screenshot-YYYY-MM-DD-HHMMSS.<ext>`
        - `both`: `<descriptive>-HHMMSS.<ext>`
      </if>
    </substep>

    <substep name="extension">
      <description>Determine file extension</description>
      <action>Match the format (png, jpg, heic, pdf, tiff, gif).</action>
    </substep>
  </step>

  <step id="execute-capture" number="4">
    <description>Execute Capture</description>

    <action>Use `${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh` for all captures.</action>

    <phase name="fullscreen" number="1">
      <description>Fullscreen</description>

      <command language="bash" tool="Bash">
      bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
        --target fullscreen \
        --format <fmt> \
        [--delay <N>] \
        [--no-shadow] \
        --silent \
        --output "<path>"
      </command>
    </phase>

    <phase name="window" number="2">
      <description>Window</description>

      <action>Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/get-window-id.sh" "<AppName>" --all` to find matching windows.</action>
      <action>If multiple windows are found, use AskUserQuestion to let the user pick which one. Show window titles and on-screen status.</action>
      <action>If no windows found, tell the user the app doesn't appear to have any open windows and suggest running `/list-windows`.</action>

      <if condition="window-id-is-zero">
        The system is using the AppleScript fallback (no Screen Recording permission or PyObjC not installed). In this case:
        <action>Bring the app to the front: `osascript -e 'tell application "<AppName>" to activate'`</action>
        <action>Wait 0.5 seconds for the app to come forward.</action>
        <action>Capture fullscreen instead (the app window will be in front).</action>
        <action>Tell the user that window-specific capture isn't available and you're capturing the frontmost window instead. Suggest granting Screen Recording permission for precise window capture.</action>
      </if>

      <action>Otherwise, capture with the resolved window ID:</action>

      <command language="bash" tool="Bash">
      bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
        --target window \
        --window-id <id> \
        --format <fmt> \
        [--delay <N>] \
        [--no-shadow] \
        --silent \
        --output "<path>"
      </command>
    </phase>

    <phase name="region" number="3">
      <description>Region</description>

      <command language="bash" tool="Bash">
      bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
        --target region \
        --region "<x,y,w,h>" \
        --format <fmt> \
        [--delay <N>] \
        --silent \
        --output "<path>"
      </command>
    </phase>

    <phase name="url" number="4">
      <description>URL</description>

      <action>Open the URL: `open "<url>"`</action>
      <action>Wait for the page to load: `sleep` for the greater of the configured delay or 3 seconds.</action>
      <action>Determine the default browser or use Safari. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/get-window-id.sh" "Safari" --all` (or the detected browser name).</action>
      <action>If multiple windows, pick the most recently opened one (first in the list).</action>
      <action>Capture the browser window using the window target.</action>
    </phase>

    <phase name="display" number="5">
      <description>Display</description>

      <command language="bash" tool="Bash">
      bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
        --target display \
        --display <N> \
        --format <fmt> \
        [--delay <N>] \
        --silent \
        --output "<path>"
      </command>
    </phase>
  </step>

  <step id="post-process" number="5">
    <description>Post-Process</description>

    <action>Apply post-processing flags if specified. The `capture.sh` script handles `--resize` and `--crop` internally.</action>

    <if condition="neither-resize-nor-crop-specified">
      <if condition="config-has-default-max-dimension">
        <if condition="is-number">
          <action>Add `--resize <number>` to the capture command.</action>
        </if>
        <if condition="is-ask">
          <ask-user-question>
            <question>Do you want to resize this screenshot, and to what dimension?</question>
          </ask-user-question>
        </if>
      </if>
    </if>
  </step>

  <step id="verify-and-report" number="6">
    <description>Verify and Report</description>

    The `capture.sh` script outputs `OK|<path>|<WxH>|<bytes>|<format>` on success.

    <action>Parse this and report to the user:</action>
    - File path
    - Dimensions (width x height)
    - File size (human-readable -- KB or MB)
    - Format

    <action>Then display the image using the Read tool so the user can see it directly.</action>

    <if condition="capture-failed">
      <action>Report the error and suggest troubleshooting:</action>
      - Window not found -- suggest `/list-windows`
      - Permission denied -- suggest granting Screen Recording permission in System Preferences > Privacy & Security
    </if>
  </step>

</steps>
