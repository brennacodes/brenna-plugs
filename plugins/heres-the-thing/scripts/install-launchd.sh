#!/usr/bin/env bash
# heres-the-thing launchd installer
# Creates and loads a macOS launchd agent for scheduled notifications.
# Usage: bash install-launchd.sh [uninstall]

set -euo pipefail

THINGS_PATH="${THINGS_PATH:-$HOME/.things}"
LABEL="com.brennacodes.heres-the-thing.notify"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/$LABEL.plist"
NOTIFY_SCRIPT="$THINGS_PATH/heres-the-thing/scripts/notify.sh"
LOG_DIR="$THINGS_PATH/heres-the-thing/logs"

if [[ "${1:-}" == "uninstall" ]]; then
  echo "Uninstalling launchd agent..."
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$PLIST_PATH"
  echo "Done. Agent removed."
  exit 0
fi

if [[ ! -x "$NOTIFY_SCRIPT" ]]; then
  echo "Error: notify.sh not found or not executable at $NOTIFY_SCRIPT"
  echo "Run /heres-the-thing:setup-htt first."
  exit 1
fi

mkdir -p "$PLIST_DIR"
mkdir -p "$LOG_DIR"

# Unload existing agent if present
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$NOTIFY_SCRIPT</string>
  </array>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>EnvironmentVariables</key>
  <dict>
    <key>THINGS_PATH</key>
    <string>$THINGS_PATH</string>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/notify-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/notify-stderr.log</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "Launchd agent installed and loaded."
echo "  Label: $LABEL"
echo "  Interval: every hour"
echo "  Logs: $LOG_DIR/"
echo ""
echo "To uninstall: bash $0 uninstall"
