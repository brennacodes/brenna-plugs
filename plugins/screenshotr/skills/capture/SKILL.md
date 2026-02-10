---
name: capture
description: Capture a screenshot — full screen, specific window, region, URL, or display — with resize, crop, delay, and format control.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
argument-hint: "[target] [--format png|jpg|heic|pdf] [--resize WxH|MAX] [--delay N] [--crop WxH] [--name filename] [--no-shadow] [--display N]"
---

# Capture Screenshot

You are capturing a screenshot for the user. Parse their arguments, resolve the target, run the capture, post-process if needed, and display the result.

## Reference Docs

Read `references/screencapture-reference.md` and `references/sips-reference.md` from this skill's directory for detailed flag and option information.

## Steps

### 1. Load Config

Read `.claude/screenshotr.local.md` to get the user's settings. If the file doesn't exist, tell the user:

> No configuration found. Please run `/screenshotr:setup` first.

Then stop.

### 2. Parse Arguments

Parse `$ARGUMENTS` to determine target type and options. Arguments can be positional or flags:

**Target types** (first positional argument or inferred):
- `screen`, `fullscreen`, or no target specified → fullscreen capture
- `window "App Name"` or `window AppName` → capture a specific app's window
- `region x,y,w,h` → capture a rectangular region
- `url "https://..."` → open URL in browser, wait, capture the browser window
- `display N` → capture a specific display

**Flags** (override config defaults):
- `--format <fmt>` — output format (png, jpg, heic, pdf, tiff, gif)
- `--resize <WxH|MAX>` — resize after capture. Single number = max dimension (aspect-preserving). WxH = exact dimensions.
- `--crop <WxH>` — center-crop after capture
- `--delay <N>` — seconds to wait before capturing
- `--name <filename>` — custom filename (without extension)
- `--no-shadow` — exclude window shadow
- `--out <path>` — custom output directory (overrides config `output_dir`)

### 3. Resolve Output Path

1. **Directory**: Use `--out` if provided, otherwise use `output_dir` from config.
2. **Filename**:
   - If `--name` was given, use it (append format extension).
   - Otherwise, generate based on the config's `naming` setting:
     - `descriptive`: Generate a kebab-case name from context — the app name, window title, or what's being captured (e.g., `safari-github-homepage.png`, `fullscreen-desktop.png`)
     - `timestamp`: `screenshot-YYYY-MM-DD-HHMMSS.<ext>`
     - `both`: `<descriptive>-HHMMSS.<ext>`
3. **Extension**: Match the format (png, jpg, heic, pdf, tiff, gif).

### 4. Execute Capture

Use `${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh` for all captures.

#### Fullscreen
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
  --target fullscreen \
  --format <fmt> \
  [--delay <N>] \
  [--no-shadow] \
  --silent \
  --output "<path>"
```

#### Window
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/get-window-id.sh" "<AppName>" --all` to find matching windows.
2. If multiple windows are found, use AskUserQuestion to let the user pick which one. Show window titles and on-screen status.
3. If no windows found, tell the user the app doesn't appear to have any open windows and suggest running `/screenshotr:list-windows`.
4. If the returned window ID is `0`, the system is using the AppleScript fallback (no Screen Recording permission or PyObjC not installed). In this case:
   - Bring the app to the front: `osascript -e 'tell application "<AppName>" to activate'`
   - Wait 0.5 seconds for the app to come forward.
   - Capture fullscreen instead (the app window will be in front).
   - Tell the user that window-specific capture isn't available and you're capturing the frontmost window instead. Suggest granting Screen Recording permission for precise window capture.
5. Otherwise, capture with the resolved window ID:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
  --target window \
  --window-id <id> \
  --format <fmt> \
  [--delay <N>] \
  [--no-shadow] \
  --silent \
  --output "<path>"
```

#### Region
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
  --target region \
  --region "<x,y,w,h>" \
  --format <fmt> \
  [--delay <N>] \
  --silent \
  --output "<path>"
```

#### URL
1. Open the URL: `open "<url>"`
2. Wait for the page to load: `sleep` for the greater of the configured delay or 3 seconds.
3. Determine the default browser or use Safari. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/get-window-id.sh" "Safari" --all` (or the detected browser name).
4. If multiple windows, pick the most recently opened one (first in the list).
5. Capture the browser window using the window target.

#### Display
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh" \
  --target display \
  --display <N> \
  --format <fmt> \
  [--delay <N>] \
  --silent \
  --output "<path>"
```

### 5. Post-Process

Apply post-processing flags if specified. The `capture.sh` script handles `--resize` and `--crop` internally.

If neither was specified but the config has `default_max_dimension` set:
- If it's a number, add `--resize <number>` to the capture command.
- If it's `"ask"`, use AskUserQuestion to ask the user if they want to resize, and to what dimension.

### 6. Verify and Report

The `capture.sh` script outputs `OK|<path>|<WxH>|<bytes>|<format>` on success.

Parse this and report to the user:
- File path
- Dimensions (width x height)
- File size (human-readable — KB or MB)
- Format

Then display the image using the Read tool so the user can see it directly.

If capture failed, report the error and suggest troubleshooting:
- Window not found → suggest `/screenshotr:list-windows`
- Permission denied → suggest granting Screen Recording permission in System Preferences > Privacy & Security
