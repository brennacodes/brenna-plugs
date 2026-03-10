#!/usr/bin/env python3
"""Rebuild index.json from snapshot-log.json, parsed.json, and dep-map.json.

Scans claude-scout/ subdirectories across all targets and writes
a unified index.json with by_type counts.

Usage:
    python3 rebuild-index.py <things_path>
"""

import json
import os
import sys
from datetime import date


def write_atomic(filepath, content):
    """Write content atomically via tmp + rename."""
    tmp = filepath + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, filepath)


def load_json(filepath):
    """Load a JSON file, returning None on failure."""
    if not os.path.isfile(filepath):
        return None
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <things_path>", file=sys.stderr)
        sys.exit(1)

    things_path = os.path.expanduser(sys.argv[1])
    plugin_dir = os.path.join(things_path, "claude-scout")

    if not os.path.isdir(plugin_dir):
        print(f"claude-scout directory not found at {plugin_dir}", file=sys.stderr)
        sys.exit(1)

    targets_data = load_json(os.path.join(plugin_dir, "targets.json"))
    if not targets_data:
        targets_data = {"targets": {}}

    items = []
    type_counts = {"snapshot": 0, "changelog": 0, "dep_scan": 0}

    for target_id, target in targets_data.get("targets", {}).items():
        # Snapshot logs
        snapshot_log_path = os.path.join(
            plugin_dir, "snapshots", target_id, "snapshot-log.json"
        )
        snapshot_log = load_json(snapshot_log_path)
        if snapshot_log:
            count = len(snapshot_log.get("entries", []))
            type_counts["snapshot"] += count
            items.append(
                {
                    "target_id": target_id,
                    "doc_type": "snapshot",
                    "display_name": target.get("display_name", target_id),
                    "count": count,
                    "last_updated": snapshot_log.get("last_updated", ""),
                    "path": f"snapshots/{target_id}/snapshot-log.json",
                }
            )

        # Parsed changelogs
        parsed_path = os.path.join(
            plugin_dir, "changelogs", target_id, "parsed.json"
        )
        parsed = load_json(parsed_path)
        if parsed:
            count = parsed.get("total_entries", 0)
            type_counts["changelog"] += count
            items.append(
                {
                    "target_id": target_id,
                    "doc_type": "changelog",
                    "display_name": target.get("display_name", target_id),
                    "count": count,
                    "last_updated": parsed.get("parsed_date", ""),
                    "path": f"changelogs/{target_id}/parsed.json",
                }
            )

        # Dependency maps
        dep_path = os.path.join(plugin_dir, "deps", target_id, "dep-map.json")
        dep_map = load_json(dep_path)
        if dep_map:
            count = dep_map.get("plugins_with_deps", 0)
            type_counts["dep_scan"] += 1
            items.append(
                {
                    "target_id": target_id,
                    "doc_type": "dep_scan",
                    "display_name": target.get("display_name", target_id),
                    "plugins_scanned": dep_map.get("plugins_scanned", 0),
                    "plugins_with_deps": count,
                    "last_updated": dep_map.get("last_scanned", ""),
                    "path": f"deps/{target_id}/dep-map.json",
                }
            )

    today = date.today().isoformat()
    index_data = {
        "version": 1,
        "last_updated": today,
        "total_targets": len(targets_data.get("targets", {})),
        "by_type": type_counts,
        "items": items,
    }

    index_path = os.path.join(plugin_dir, "index.json")
    write_atomic(
        index_path, json.dumps(index_data, indent=2, ensure_ascii=False) + "\n"
    )

    print(f"Rebuilt: {len(items)} items, {type_counts}")


if __name__ == "__main__":
    main()
