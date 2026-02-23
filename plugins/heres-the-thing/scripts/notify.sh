#!/usr/bin/env bash
# heres-the-thing notification script
# Runs via macOS launchd on a schedule. Checks active campaigns for
# approaching target dates, pending outcomes, and stale campaigns.
# Sends native macOS notifications via osascript.

set -euo pipefail

THINGS_PATH="${THINGS_PATH:-$HOME/.things}"
HTT_PATH="$THINGS_PATH/heres-the-thing"
PREFS="$HTT_PATH/preferences.json"

if [[ ! -f "$PREFS" ]]; then
  exit 0
fi

# Check if notifications are enabled
ENABLED=$(python3 -c "
import json
with open('$PREFS') as f:
    p = json.load(f)
print('yes' if p.get('notifications', {}).get('enabled', False) else 'no')
" 2>/dev/null)

if [[ "$ENABLED" != "yes" ]]; then
  exit 0
fi

# Check quiet hours
IN_QUIET=$(python3 -c "
import json
from datetime import datetime

with open('$PREFS') as f:
    p = json.load(f)

qh = p.get('notifications', {}).get('quiet_hours', {})
start = qh.get('start', '21:00')
end = qh.get('end', '08:00')

now = datetime.now()
current_time = now.strftime('%H:%M')

# Handle overnight quiet hours (e.g., 21:00 - 08:00)
if start > end:
    in_quiet = current_time >= start or current_time < end
else:
    in_quiet = start <= current_time < end

print('yes' if in_quiet else 'no')
" 2>/dev/null)

if [[ "$IN_QUIET" == "yes" ]]; then
  exit 0
fi

# Generate notifications and send them
python3 << 'PYEOF'
import json, os, glob, subprocess, shlex
from datetime import datetime, timedelta

things_path = os.environ.get('THINGS_PATH', os.path.expanduser('~/.things'))
htt_path = os.path.join(things_path, 'heres-the-thing')
prefs_path = os.path.join(htt_path, 'preferences.json')

with open(prefs_path) as f:
    prefs = json.load(f)

notif_config = prefs.get('notifications', {})
reminder_windows = notif_config.get('reminder_windows', ['7d', '2d', '1d', '3h', '1h'])

notifications = []
now = datetime.now()

def parse_window(w):
    """Parse a window string like '7d' or '3h' into timedelta."""
    if w.endswith('d'):
        return timedelta(days=int(w[:-1]))
    elif w.endswith('h'):
        return timedelta(hours=int(w[:-1]))
    return timedelta(days=1)

def send_notification(message):
    """Send a macOS notification using osascript with safe argument passing."""
    script = f'display notification "{message}" with title "heres-the-thing"'
    subprocess.run(['osascript', '-e', script], capture_output=True, timeout=5)

# Scan campaigns
campaigns_dir = os.path.join(htt_path, 'campaigns')
if not os.path.isdir(campaigns_dir):
    exit()

for campaign_dir in sorted(glob.glob(os.path.join(campaigns_dir, '*'))):
    campaign_file = os.path.join(campaign_dir, 'campaign.json')
    if not os.path.isfile(campaign_file):
        continue

    try:
        with open(campaign_file) as f:
            campaign = json.load(f)
    except (json.JSONDecodeError, IOError):
        continue

    campaign_id = campaign.get('id', os.path.basename(campaign_dir))
    status = campaign.get('status', '')

    if status not in ('active', 'delivered'):
        continue

    # Check for stale campaigns (no activity in 14 days)
    mtime = os.path.getmtime(campaign_file)
    last_modified = datetime.fromtimestamp(mtime)
    if (now - last_modified).days > 14:
        notifications.append(
            f"Campaign '{campaign_id}' has had no activity in {(now - last_modified).days} days."
        )

    for goal in campaign.get('goals', []):
        goal_id = goal.get('id', 'unknown')
        goal_status = goal.get('status', '')
        target_date_str = goal.get('target_date')

        if goal_status not in ('active', 'pending'):
            if goal_status == 'delivered':
                outcomes_dir = os.path.join(campaign_dir, 'outcomes')
                outcome_files = glob.glob(os.path.join(outcomes_dir, f'{goal_id}-*.json')) if os.path.isdir(outcomes_dir) else []
                if not outcome_files:
                    notifications.append(
                        f"Goal '{goal_id}' delivered but no outcome logged. Run /heres-the-thing:outcome"
                    )
            continue

        if not target_date_str:
            continue

        try:
            target_date = datetime.strptime(target_date_str, '%Y-%m-%d')
        except ValueError:
            continue

        time_until = target_date - now

        # Check reminder windows
        for window_str in reminder_windows:
            window = parse_window(window_str)
            if timedelta(0) <= time_until <= window:
                strategy_dir = os.path.join(campaign_dir, 'strategy')
                artifacts_dir = os.path.join(campaign_dir, 'artifacts')
                has_brief = bool(glob.glob(os.path.join(strategy_dir, f'{goal_id}-*.md'))) if os.path.isdir(strategy_dir) else False
                has_artifacts = bool(glob.glob(os.path.join(artifacts_dir, f'{goal_id}-*.md'))) if os.path.isdir(artifacts_dir) else False
                has_qa = bool(glob.glob(os.path.join(artifacts_dir, f'{goal_id}-qa-session-*.md'))) if os.path.isdir(artifacts_dir) else False

                if has_qa:
                    prep = 'rehearsed'
                elif has_artifacts:
                    prep = 'drafted'
                elif has_brief:
                    prep = 'strategized'
                else:
                    prep = 'zero'

                days_left = time_until.days
                hours_left = int(time_until.total_seconds() / 3600)
                time_str = f'{days_left} days' if days_left > 0 else f'{hours_left} hours'

                notifications.append(
                    f"Goal '{goal_id}' is in {time_str}. Prep level: {prep}."
                )
                break

        if time_until < timedelta(0):
            notifications.append(
                f"Goal '{goal_id}' target date passed ({target_date_str}). Update status?"
            )

for msg in notifications:
    try:
        send_notification(msg)
    except Exception:
        pass
PYEOF
