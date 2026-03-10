#!/usr/bin/env python3
"""Scan installed plugins for path dependencies on a target directory.

Reads installed_plugins.json to discover all plugins across all marketplaces,
then scans each plugin's cached install path for path references matching
the target directory (e.g., ~/.claude/).

Usage:
    python3 scan-deps.py <target_id> <target_path> <output_path> [installed_plugins_json]
"""

import json
import os
import re
import sys
from datetime import datetime

# File extensions to scan
SCAN_EXTENSIONS = {".md", ".sh", ".py", ".json"}

# Directories to skip
SKIP_DIRS = {".git", "node_modules", "__pycache__", ".claude-plugin"}

# Max file size to scan (1MB)
MAX_FILE_SIZE = 1024 * 1024


def build_patterns(target_path):
    """Build regex patterns for detecting path references."""
    # Normalize path for pattern building
    path = target_path.rstrip("/")
    basename = os.path.basename(path)

    patterns = [
        # Literal path references
        re.compile(re.escape(path)),
        # Home-relative references like ~/.claude/
        re.compile(r"~/\." + re.escape(basename) + r"/"),
        # $HOME references
        re.compile(r"\$HOME/\." + re.escape(basename) + r"/"),
        re.compile(r"\$\{HOME\}/\." + re.escape(basename) + r"/"),
    ]

    # Also look for specific structural file names that are unique to the target
    structural_files = [
        "installed_plugins.json",
        "settings.json",
        "keybindings.json",
        "permissions.json",
    ]
    for sf in structural_files:
        patterns.append(re.compile(r"\b" + re.escape(sf) + r"\b"))

    return patterns


def scan_file(filepath, patterns):
    """Scan a single file for path references. Returns list of matches."""
    try:
        if os.path.getsize(filepath) > MAX_FILE_SIZE:
            return []
    except OSError:
        return []

    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
    except (OSError, PermissionError):
        return []

    matches = []
    for line_num, line in enumerate(lines, 1):
        for pattern in patterns:
            if pattern.search(line):
                matches.append(
                    {
                        "pattern": pattern.pattern,
                        "line": line_num,
                        "context": line.strip()[:200],
                    }
                )
                break  # One match per line is enough

    return matches


def scan_plugin(plugin_path, patterns):
    """Scan a plugin directory for path references."""
    all_matches = []

    if not os.path.isdir(plugin_path):
        return all_matches

    for root, dirs, files in os.walk(plugin_path):
        # Filter out skip dirs
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for filename in files:
            ext = os.path.splitext(filename)[1]
            if ext not in SCAN_EXTENSIONS:
                continue

            filepath = os.path.join(root, filename)
            matches = scan_file(filepath, patterns)

            if matches:
                rel_path = os.path.relpath(filepath, plugin_path)
                for match in matches:
                    match["file"] = rel_path
                all_matches.extend(matches)

    return all_matches


def load_installed_plugins(json_path):
    """Load and parse installed_plugins.json."""
    if not os.path.isfile(json_path):
        return {}

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}

    # installed_plugins.json maps plugin names to install info
    # Structure: { "plugin@marketplace": { "path": "...", ... } }
    return data


def write_atomic(filepath, content):
    """Write content atomically via tmp + rename."""
    tmp = filepath + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, filepath)


def main():
    if len(sys.argv) < 4:
        print(
            f"Usage: {sys.argv[0]} <target_id> <target_path> <output_path> [installed_plugins_json]",
            file=sys.stderr,
        )
        sys.exit(1)

    target_id = sys.argv[1]
    target_path = os.path.expanduser(sys.argv[2])
    output_path = os.path.expanduser(sys.argv[3])
    plugins_json = os.path.expanduser(
        sys.argv[4]
        if len(sys.argv) > 4
        else os.path.join(target_path, "plugins", "installed_plugins.json")
    )

    patterns = build_patterns(target_path)
    installed = load_installed_plugins(plugins_json)

    dependencies = {}
    plugins_scanned = 0
    skipped = []

    for plugin_key, plugin_info in installed.items():
        plugin_path = None
        if isinstance(plugin_info, dict):
            plugin_path = plugin_info.get("path", plugin_info.get("install_path"))
        elif isinstance(plugin_info, str):
            plugin_path = plugin_info

        if not plugin_path or not os.path.isdir(plugin_path):
            skipped.append(plugin_key)
            continue

        plugins_scanned += 1
        matches = scan_plugin(plugin_path, patterns)

        if matches:
            dependencies[plugin_key] = {
                "paths_referenced": [
                    {
                        "pattern": m["pattern"],
                        "file": m["file"],
                        "line": m["line"],
                        "context": m["context"],
                    }
                    for m in matches
                ]
            }

    result = {
        "version": 1,
        "target_id": target_id,
        "last_scanned": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "plugins_scanned": plugins_scanned,
        "plugins_with_deps": len(dependencies),
        "skipped": skipped,
        "dependencies": dependencies,
    }

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    write_atomic(output_path, json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    print(
        json.dumps(
            {
                "status": "scanned",
                "plugins_scanned": plugins_scanned,
                "plugins_with_deps": len(dependencies),
                "skipped": len(skipped),
            }
        )
    )


if __name__ == "__main__":
    main()
