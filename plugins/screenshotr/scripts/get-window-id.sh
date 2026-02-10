#!/usr/bin/env bash
# get-window-id.sh — Resolve an app name to a CGWindowID
# Usage: get-window-id.sh <app-name> [--all]
# Single mode: prints the CGWindowID of the best-matching window
# --all mode: prints ID|TITLE|ON_SCREEN lines for all matching windows
# Falls back to System Events if CGWindowList is unavailable
# Exit codes: 0 = found, 1 = not found, 2 = usage error

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: get-window-id.sh <app-name> [--all]" >&2
  exit 2
fi

APP_NAME="$1"
ALL_MODE=false
if [ "${2:-}" = "--all" ]; then
  ALL_MODE=true
fi

get_windows_python() {
  local app_name="$1"
  local all_mode="$2"

  python3 << PYEOF
import Quartz
import sys

app_name = "$app_name"
all_mode = "$all_mode" == "true"

windows = Quartz.CGWindowListCopyWindowInfo(
    Quartz.kCGWindowListOptionAll,
    Quartz.kCGNullWindowID
)

matches = []
for win in windows:
    layer = win.get(Quartz.kCGWindowLayer, -1)
    if layer != 0:
        continue

    owner = win.get(Quartz.kCGWindowOwnerName, "")
    wid = win.get(Quartz.kCGWindowNumber, 0)
    if not owner or wid == 0:
        continue

    title = win.get(Quartz.kCGWindowName, "")
    on_screen = win.get(Quartz.kCGWindowIsOnscreen, False)

    # Case-insensitive exact match first
    if owner.lower() == app_name.lower():
        matches.append((wid, title, on_screen, True))
    # Partial match fallback
    elif app_name.lower() in owner.lower():
        matches.append((wid, title, on_screen, False))

if not matches:
    sys.exit(1)

# Sort: exact matches first, then on-screen windows first
matches.sort(key=lambda m: (not m[3], not m[2]))

if all_mode:
    for wid, title, on_screen, _ in matches:
        status = "yes" if on_screen else "no"
        print(f"{wid}|{title}|{status}")
else:
    print(matches[0][0])
PYEOF
}

get_windows_jxa() {
  local app_name="$1"
  local all_mode="$2"

  osascript -l JavaScript << JSEOF
ObjC.import('CoreGraphics');

const appName = "$app_name";
const allMode = "$all_mode" === "true";
const windows = $.CGWindowListCopyWindowInfo(0, 0);  // kCGWindowListOptionAll
const count = ObjC.unwrap(windows).length;
const matches = [];

for (let i = 0; i < count; i++) {
  const win = ObjC.unwrap(windows)[i];
  const layer = ObjC.unwrap(win.kCGWindowLayer) || -1;
  if (layer !== 0) continue;

  const owner = ObjC.unwrap(win.kCGWindowOwnerName) || "";
  const wid = ObjC.unwrap(win.kCGWindowNumber) || 0;
  if (!owner || wid === 0) continue;

  const title = ObjC.unwrap(win.kCGWindowName) || "";
  const onScreen = ObjC.unwrap(win.kCGWindowIsOnscreen) || false;

  const exactMatch = owner.toLowerCase() === appName.toLowerCase();
  const partialMatch = owner.toLowerCase().includes(appName.toLowerCase());

  if (exactMatch || partialMatch) {
    matches.push({ wid, title, onScreen, exact: exactMatch });
  }
}

if (matches.length === 0) {
  ObjC.import('stdlib');
  $.exit(1);
}

// Sort: exact first, then on-screen first
matches.sort((a, b) => {
  if (a.exact !== b.exact) return b.exact - a.exact;
  return b.onScreen - a.onScreen;
});

if (allMode) {
  matches.map(m => m.wid + "|" + m.title + "|" + (m.onScreen ? "yes" : "no")).join("\\n");
} else {
  "" + matches[0].wid;
}
JSEOF
}

# Fallback: System Events AppleScript (no CGWindowID, returns 0 as placeholder)
# When this fallback is used, window capture by ID won't work — capture by app name instead
get_windows_applescript() {
  local app_name="$1"
  local all_mode="$2"

  local result
  result=$(osascript << ASEOF
set output to ""
tell application "System Events"
  set matchedProcesses to every process whose name contains "$app_name"
  repeat with proc in matchedProcesses
    if visible of proc then
      set appName to name of proc
      try
        set wins to every window of proc
        repeat with w in wins
          set winTitle to ""
          try
            set winTitle to name of w
          end try
          set output to output & "0|" & winTitle & "|yes" & linefeed
        end repeat
        if (count of wins) = 0 then
          set output to output & "0||yes" & linefeed
        end if
      on error
        set output to output & "0||yes" & linefeed
      end try
    end if
  end repeat
end tell
if length of output > 0 then
  return text 1 thru -2 of output
else
  return ""
end if
ASEOF
  ) || true

  if [ -z "$result" ]; then
    return 1
  fi

  if [ "$all_mode" = "true" ]; then
    echo "$result"
  else
    # Return just "0" — caller will need to capture by app name instead
    echo "0"
  fi
}

# Try Python/Quartz first, then JXA, then AppleScript fallback
RESULT=""
EXIT_CODE=1

if python3 -c "import Quartz" 2>/dev/null; then
  RESULT=$(get_windows_python "$APP_NAME" "$ALL_MODE" 2>/dev/null) && EXIT_CODE=0 || true
fi

if [ -z "$RESULT" ] || [ $EXIT_CODE -ne 0 ]; then
  RESULT=$(get_windows_jxa "$APP_NAME" "$ALL_MODE" 2>/dev/null) && EXIT_CODE=0 || true
fi

if [ -z "$RESULT" ] || [ $EXIT_CODE -ne 0 ]; then
  RESULT=$(get_windows_applescript "$APP_NAME" "$ALL_MODE" 2>/dev/null) && EXIT_CODE=0 || EXIT_CODE=1
fi

if [ -n "$RESULT" ] && [ $EXIT_CODE -eq 0 ]; then
  echo "$RESULT"
  exit 0
else
  echo "No windows found for '$APP_NAME'" >&2
  exit 1
fi
