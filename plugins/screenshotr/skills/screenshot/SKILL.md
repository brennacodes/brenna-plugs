---
name: screenshot
description: Automatically capture a screenshot when conversation context suggests one is needed.
disable-model-invocation: false
allowed-tools: Read, Bash, Glob
---

# Auto Screenshot

You are automatically capturing a screenshot because the conversation context suggests the user needs one. This skill is invoked proactively — do not ask the user questions, just capture and show the result.

## When to Use This

Invoke this skill when the user says things like:
- "let me see what that looks like"
- "capture the current state"
- "screenshot this"
- "show me the screen"
- "take a screenshot of [app]"

## Steps

### 1. Load Config

Read `.claude/screenshotr.local.md` for settings. If no config exists, capture with sensible defaults: png format, `./screenshots` directory, no shadow, silent.

### 2. Detect Target

Infer the capture target from conversation context:

- If a specific app is being discussed (e.g., the user is working with Xcode, or just opened a browser) → capture that app's window using `bash "${CLAUDE_PLUGIN_ROOT}/scripts/get-window-id.sh" "<AppName>"`
- If no specific app context → fullscreen capture
- If the user mentioned a URL → this is better handled by `/screenshotr:capture url "..."` — suggest that instead and stop

### 3. Generate Filename

Create a descriptive kebab-case filename based on context:
- What's being captured (app name, feature, state)
- Keep it concise (2-4 words max)
- Apply the naming convention from config

### 4. Capture

Run the capture using `${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
  --target <fullscreen|window> \
  [--window-id <id>] \
  --format <config_format> \
  --silent \
  [--no-shadow] \
  [--resize <config_max_dimension>] \
  --output "<output_dir>/<filename>.<ext>"
```

Apply `default_max_dimension` from config if set (and it's a number, not "ask").

### 5. Display Result

Parse the `OK|path|WxH|bytes|format` output from `capture.sh`.

Report the file path and dimensions briefly, then use the Read tool to display the image so the user can see it inline.

If capture fails, report the error without being verbose. Suggest running `/screenshotr:setup` if config is missing, or `/screenshotr:list-windows` if window detection failed.
