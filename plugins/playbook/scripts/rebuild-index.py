#!/usr/bin/env python3
"""Rebuild index.json and tags.json from plans, workflows, and reviews.

Scans all three subdirectories (plans/, workflows/, reviews/), parses
YAML frontmatter, and writes a unified index.json and tags.json.

Plans use a versioned directory structure: plans/<slug>/v1.md, v2.md, etc.
Only the latest version per slug is indexed.

Usage:
    python3 rebuild-index.py <things_path>
"""

import json
import os
import re
import sys
from datetime import date


def parse_frontmatter(text):
    """Parse YAML frontmatter from markdown text.

    Handles:
    - Simple key: value pairs
    - Quoted strings
    - Inline lists [a, b, c]
    - Block lists (- item)
    """
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, text

    fm_lines = []
    body_start = len(lines)
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == "---":
            body_start = i + 1
            break
        fm_lines.append(line)

    body = "\n".join(lines[body_start:])
    data = {}
    current_key = None
    current_list = None

    for line in fm_lines:
        if not line.strip():
            if current_key and current_list is not None:
                data[current_key] = current_list
                current_key = None
                current_list = None
            continue

        # Block list item
        m = re.match(r"^  - (.+)$", line)
        if m and current_key is not None:
            if current_list is None:
                current_list = []
            current_list.append(m.group(1).strip().strip('"').strip("'"))
            continue

        # Top-level key: value
        m = re.match(r"^(\w[\w_]*):\s*(.*)$", line)
        if m:
            if current_key and current_list is not None:
                data[current_key] = current_list

            key = m.group(1)
            val = m.group(2).strip()

            # Inline list
            if val.startswith("[") and val.endswith("]"):
                items = val[1:-1].split(",")
                data[key] = [i.strip().strip('"').strip("'") for i in items if i.strip()]
                current_key = None
                current_list = None
            elif val == "" or val is None:
                current_key = key
                current_list = None
            elif val.lower() in ("true", "false"):
                data[key] = val.lower() == "true"
                current_key = None
                current_list = None
            elif (val.startswith('"') and val.endswith('"')) or \
                 (val.startswith("'") and val.endswith("'")):
                data[key] = val[1:-1]
                current_key = None
                current_list = None
            else:
                data[key] = try_number(val)
                current_key = None
                current_list = None

    if current_key and current_list is not None:
        data[current_key] = current_list

    return data, body


def try_number(val):
    """Try to convert a string to int or float, else return as string."""
    try:
        return int(val)
    except (ValueError, TypeError):
        pass
    try:
        return float(val)
    except (ValueError, TypeError):
        pass
    return val


def ensure_list(val):
    """Ensure a value is a list."""
    if isinstance(val, list):
        return val
    if isinstance(val, str) and val:
        return [val]
    return []


def write_atomic(filepath, content):
    """Write content to a file atomically via tmp + rename."""
    tmp = filepath + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, filepath)


def process_file(filepath, subdir):
    """Process a single file and return an index entry with doc_type."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()
    except Exception as e:
        print(f"Warning: could not read {filepath}: {e}", file=sys.stderr)
        return None

    fm, _ = parse_frontmatter(text)
    if not fm.get("title"):
        print(f"Warning: skipping {filepath} (missing title)", file=sys.stderr)
        return None

    # Derive doc_type from frontmatter or subdirectory
    doc_type = fm.get("doc_type", subdir.rstrip("s"))  # plans->plan, workflows->workflow, reviews->review
    filename = subdir + "/" + os.path.basename(filepath)

    entry = {
        "filename": filename,
        "doc_type": doc_type,
        "title": fm.get("title", ""),
        "date": str(fm.get("date", "")),
        "description": fm.get("description", ""),
        "tags": ensure_list(fm.get("tags", [])),
    }

    # Type-specific fields
    if doc_type == "plan":
        entry["status"] = fm.get("status", "active")
        if fm.get("source_plan"):
            entry["source_plan"] = fm["source_plan"]
        if fm.get("project"):
            entry["project"] = fm["project"]

    elif doc_type == "workflow":
        if fm.get("scope"):
            entry["scope"] = fm["scope"]
        if fm.get("target_path"):
            entry["target_path"] = fm["target_path"]
        if fm.get("step_count"):
            entry["step_count"] = fm["step_count"]

    elif doc_type == "review":
        if fm.get("plan_ref"):
            entry["plan_ref"] = fm["plan_ref"]
        if fm.get("branch"):
            entry["branch"] = fm["branch"]
        entry["status"] = fm.get("status", "has-open-items")
        if fm.get("actionable_count") is not None:
            entry["actionable_count"] = fm["actionable_count"]
        if fm.get("done_count") is not None:
            entry["done_count"] = fm["done_count"]

    return entry


def scan_versioned_plans(plans_dir):
    """Scan plans/<slug>/v*.md directories, return only the latest version per slug."""
    entries = []
    if not os.path.isdir(plans_dir):
        return entries

    for slug in sorted(os.listdir(plans_dir)):
        slug_dir = os.path.join(plans_dir, slug)
        if not os.path.isdir(slug_dir):
            continue

        # Find all v*.md files and pick the highest version
        versions = {}
        for filename in os.listdir(slug_dir):
            m = re.match(r"^v(\d+)\.md$", filename)
            if m:
                versions[int(m.group(1))] = filename

        if not versions:
            continue

        latest_num = max(versions.keys())
        latest_file = versions[latest_num]
        filepath = os.path.join(slug_dir, latest_file)

        entry = process_file(filepath, "plans")
        if entry:
            # Override filename to include slug dir
            entry["filename"] = f"plans/{slug}/{latest_file}"
            entry["slug"] = slug
            entry["version"] = latest_num
            entry["references"] = ensure_list(entry.get("references")) if "references" in entry else []
            # Pull references from frontmatter if present
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    text = f.read()
                fm, _ = parse_frontmatter(text)
                entry["references"] = ensure_list(fm.get("references", []))
            except Exception:
                pass
            entries.append(entry)

    return entries


def build_tags(entries):
    """Build tags.json data from entries."""
    tags = {}
    for entry in entries:
        for tag in entry.get("tags", []):
            if tag not in tags:
                tags[tag] = {"count": 0, "last_used": ""}
            tags[tag]["count"] += 1
            entry_date = entry.get("date", "")
            if entry_date and entry_date > tags[tag]["last_used"]:
                tags[tag]["last_used"] = entry_date
    return tags


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <things_path>", file=sys.stderr)
        sys.exit(1)

    things_path = os.path.expanduser(sys.argv[1])
    plugin_dir = os.path.join(things_path, "playbook")

    if not os.path.isdir(plugin_dir):
        print(f"No playbook directory at {plugin_dir}", file=sys.stderr)
        sys.exit(0)

    entries = []
    type_counts = {"plan": 0, "workflow": 0, "review": 0}

    # Plans use versioned directory structure: plans/<slug>/v*.md
    plan_entries = scan_versioned_plans(os.path.join(plugin_dir, "plans"))
    for entry in plan_entries:
        entries.append(entry)
        type_counts["plan"] += 1

    # Workflows and reviews remain flat files
    for subdir in ("workflows", "reviews"):
        subdir_path = os.path.join(plugin_dir, subdir)
        if not os.path.isdir(subdir_path):
            continue
        for filename in sorted(os.listdir(subdir_path)):
            if not filename.endswith(".md"):
                continue
            filepath = os.path.join(subdir_path, filename)
            entry = process_file(filepath, subdir)
            if entry:
                entries.append(entry)
                doc_type = entry.get("doc_type", "")
                if doc_type in type_counts:
                    type_counts[doc_type] += 1

    entries.sort(key=lambda e: e.get("date", ""), reverse=True)

    today = date.today().isoformat()
    index_data = {
        "version": 1,
        "last_updated": today,
        "total_items": len(entries),
        "by_type": type_counts,
        "items": entries,
    }
    index_path = os.path.join(plugin_dir, "index.json")
    write_atomic(index_path, json.dumps(index_data, indent=2, ensure_ascii=False) + "\n")

    tags_map = build_tags(entries)
    tags_data = {
        "last_updated": today,
        "tags": tags_map,
    }
    tags_path = os.path.join(plugin_dir, "tags.json")
    write_atomic(tags_path, json.dumps(tags_data, indent=2, ensure_ascii=False) + "\n")

    print(f"Rebuilt: {len(entries)} items ({type_counts}), {len(tags_map)} tags")


if __name__ == "__main__":
    main()
