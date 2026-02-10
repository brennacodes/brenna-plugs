#!/usr/bin/env bash
# list-windows.sh — List on-screen windows with app name, title, and window ID
# Output: APP_NAME|WINDOW_TITLE|WINDOW_ID|ON_SCREEN lines
# Falls back to System Events AppleScript if CGWindowList returns nothing
# (common when Screen Recording permission hasn't been granted)

set -euo pipefail

list_windows_python() {
  python3 << 'PYEOF'
import Quartz

windows = Quartz.CGWindowListCopyWindowInfo(
    Quartz.kCGWindowListOptionOnScreenOnly | Quartz.kCGWindowListExcludeDesktopElements,
    Quartz.kCGNullWindowID
)

seen = set()
for win in windows:
    layer = win.get(Quartz.kCGWindowLayer, -1)
    if layer != 0:
        continue

    owner = win.get(Quartz.kCGWindowOwnerName, "")
    title = win.get(Quartz.kCGWindowName, "")
    wid = win.get(Quartz.kCGWindowNumber, 0)
    on_screen = "yes" if win.get(Quartz.kCGWindowIsOnscreen, False) else "no"

    if not owner or wid == 0:
        continue

    key = f"{owner}|{title}"
    if key in seen:
        continue
    seen.add(key)

    print(f"{owner}|{title}|{wid}|{on_screen}")
PYEOF
}

list_windows_jxa() {
  osascript -l JavaScript << 'JSEOF'
ObjC.import('CoreGraphics');

const kOnScreenOnly = (1 << 0);
const kExcludeDesktop = (1 << 4);
const windows = $.CGWindowListCopyWindowInfo(kOnScreenOnly | kExcludeDesktop, 0);
const count = ObjC.unwrap(windows).length;
const seen = {};
const lines = [];

for (let i = 0; i < count; i++) {
  const win = ObjC.unwrap(windows)[i];
  const layer = ObjC.unwrap(win.kCGWindowLayer) || -1;
  if (layer !== 0) continue;

  const owner = ObjC.unwrap(win.kCGWindowOwnerName) || "";
  const title = ObjC.unwrap(win.kCGWindowName) || "";
  const wid = ObjC.unwrap(win.kCGWindowNumber) || 0;
  const onScreen = ObjC.unwrap(win.kCGWindowIsOnscreen) ? "yes" : "no";

  if (!owner || wid === 0) continue;

  const key = owner + "|" + title;
  if (seen[key]) continue;
  seen[key] = true;

  lines.push(owner + "|" + title + "|" + wid + "|" + onScreen);
}

lines.join("\n");
JSEOF
}

# Fallback: System Events AppleScript (no Screen Recording permission needed)
# Provides app name and window titles but no CGWindowID
list_windows_applescript() {
  osascript << 'ASEOF'
set output to ""
tell application "System Events"
  set visibleProcesses to every process whose visible is true
  repeat with proc in visibleProcesses
    set appName to name of proc
    try
      set wins to every window of proc
      repeat with w in wins
        set winTitle to ""
        try
          set winTitle to name of w
        end try
        set output to output & appName & "|" & winTitle & "|0|yes" & linefeed
      end repeat
      if (count of wins) = 0 then
        set output to output & appName & "||0|yes" & linefeed
      end if
    on error
      set output to output & appName & "||0|yes" & linefeed
    end try
  end repeat
end tell
return text 1 thru -2 of output
ASEOF
}

# Try Python/Quartz first, then JXA, then AppleScript fallback
RESULT=""

if python3 -c "import Quartz" 2>/dev/null; then
  RESULT=$(list_windows_python 2>/dev/null || true)
fi

if [ -z "$RESULT" ]; then
  RESULT=$(list_windows_jxa 2>/dev/null || true)
fi

if [ -z "$RESULT" ]; then
  RESULT=$(list_windows_applescript 2>/dev/null || true)
fi

if [ -n "$RESULT" ]; then
  echo "$RESULT"
else
  echo "No windows found. Ensure Screen Recording permission is granted in System Preferences > Privacy & Security." >&2
  exit 1
fi
