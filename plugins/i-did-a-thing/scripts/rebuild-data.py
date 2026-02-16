#!/usr/bin/env python3
"""Rebuild index.json, tags.json, and arsenal/*.md from log files.

Replaces rebuild-index.sh and update-arsenal.sh with a single script
that reads all logs, parses YAML frontmatter and body sections, and
writes all derived data atomically.

Usage:
    python3 rebuild-data.py <things_path>
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
    - Nested maps (one level, for metrics)
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
    current_collection = None  # will be either a list or a dict

    for line in fm_lines:
        # Blank line resets context
        if not line.strip():
            if current_key and current_collection is not None:
                data[current_key] = current_collection
                current_key = None
                current_collection = None
            continue

        # Block list item (  - value) — determines collection is a list
        m = re.match(r"^  - (.+)$", line)
        if m and current_key is not None:
            if not isinstance(current_collection, list):
                current_collection = []
            current_collection.append(m.group(1).strip().strip('"').strip("'"))
            continue

        # Nested map item (  key: value) — determines collection is a dict
        m = re.match(r"^  (\w+):\s*(.*)$", line)
        if m and current_key is not None:
            if not isinstance(current_collection, dict):
                current_collection = {}
            val = m.group(2).strip().strip('"').strip("'")
            current_collection[m.group(1)] = try_number(val) if val else None
            continue

        # Top-level key: value
        m = re.match(r"^(\w[\w_]*):\s*(.*)$", line)
        if m:
            # Flush any pending collection
            if current_key and current_collection is not None:
                data[current_key] = current_collection

            key = m.group(1)
            val = m.group(2).strip()

            # Inline list: [a, b, c]
            if val.startswith("[") and val.endswith("]"):
                items = val[1:-1].split(",")
                data[key] = [i.strip().strip('"').strip("'") for i in items if i.strip()]
                current_key = None
                current_collection = None
            # Empty value — start of a block list or map (determined by first child)
            elif val == "" or val is None:
                current_key = key
                current_collection = None  # type determined by first child line
            # Boolean
            elif val.lower() in ("true", "false"):
                data[key] = val.lower() == "true"
                current_key = None
                current_collection = None
            # Quoted string
            elif (val.startswith('"') and val.endswith('"')) or \
                 (val.startswith("'") and val.endswith("'")):
                data[key] = val[1:-1]
                current_key = None
                current_collection = None
            # Number or plain string
            else:
                data[key] = try_number(val)
                current_key = None
                current_collection = None

    # Flush any trailing collection
    if current_key and current_collection is not None:
        data[current_key] = current_collection

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


def extract_body_sections(body):
    """Extract ## sections from body text, returning a dict."""
    sections = {}
    current_heading = None
    current_lines = []

    for line in body.split("\n"):
        m = re.match(r"^## (.+)$", line)
        if m:
            if current_heading:
                sections[slugify_section(current_heading)] = "\n".join(current_lines).strip()
            current_heading = m.group(1).strip()
            current_lines = []
        elif current_heading is not None:
            current_lines.append(line)

    if current_heading:
        sections[slugify_section(current_heading)] = "\n".join(current_lines).strip()

    return sections


def slugify_section(heading):
    """Convert heading to a snake_case key."""
    s = heading.lower()
    s = re.sub(r"[^a-z0-9\s]", "", s)
    s = re.sub(r"\s+", "_", s.strip())
    return s


def extract_resume_bullets(body):
    """Extract resume bullets from the Resume Bullets section."""
    bullets = []
    in_section = False
    for line in body.split("\n"):
        if re.match(r"^## Resume Bullets", line, re.IGNORECASE):
            in_section = True
            continue
        if in_section:
            if line.startswith("## "):
                break
            m = re.match(r"^[-*]\s+(.+)$", line)
            if m:
                bullets.append(m.group(1).strip())
    return bullets


def extract_section_text(body, section_name):
    """Extract the text content of a specific ## section."""
    in_section = False
    lines = []
    for line in body.split("\n"):
        if re.match(r"^## " + re.escape(section_name), line, re.IGNORECASE):
            in_section = True
            continue
        if in_section:
            if line.startswith("## "):
                break
            lines.append(line)
    return "\n".join(lines).strip()


def slugify(text):
    """Convert text to a URL-friendly slug."""
    s = text.lower()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"[\s]+", "-", s.strip())
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def process_log(filepath):
    """Process a single log file and return an entry dict, or None on error."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()
    except Exception as e:
        print(f"Warning: could not read {filepath}: {e}", file=sys.stderr)
        return None

    fm, body = parse_frontmatter(text)
    if not fm.get("title") or not fm.get("date"):
        print(f"Warning: skipping {filepath} (missing title or date)", file=sys.stderr)
        return None

    filename = os.path.basename(filepath)

    # Extract body sections (the narrative ones, excluding Resume Bullets etc.)
    all_sections = extract_body_sections(body)

    # Separate special sections from body narrative sections
    special_keys = {"resume_bullets", "interview_talking_points", "blog_seed"}
    body_sections = {k: v for k, v in all_sections.items() if k not in special_keys}

    entry = {
        "filename": filename,
        "title": fm.get("title", ""),
        "date": str(fm.get("date", "")),
        "description": fm.get("description", ""),
        "evidence_type": fm.get("evidence_type", "accomplishment"),
        "impact": fm.get("impact", ""),
        "category": fm.get("category", ""),
        "tags": ensure_list(fm.get("tags", [])),
        "skills_used": ensure_list(fm.get("skills_used", [])),
        "skills_developed": ensure_list(fm.get("skills_developed", [])),
        "target_alignment": ensure_list(fm.get("target_alignment", [])),
        "role_at_time": fm.get("role_at_time", ""),
        "team_or_org": fm.get("team_or_org", ""),
        "duration": fm.get("duration", ""),
        "metrics": fm.get("metrics") if isinstance(fm.get("metrics"), dict) else {},
        "blog_potential": fm.get("blog_potential", ""),
        "resume_bullets": extract_resume_bullets(body),
        "interview_talking_points": extract_section_text(body, "Interview Talking Points"),
        "blog_seed": extract_section_text(body, "Blog Seed"),
        "body_sections": body_sections,
    }

    # Include extra frontmatter fields not already captured
    for key in ("blog_post", "blog_post_date", "draft", "author"):
        if key in fm:
            entry[key] = fm[key]

    return entry


def ensure_list(val):
    """Ensure a value is a list."""
    if isinstance(val, list):
        return val
    if isinstance(val, str) and val:
        return [val]
    return []


def build_tags(entries):
    """Build tags.json data from entries."""
    tags = {}
    for entry in entries:
        for tag in entry.get("tags", []):
            if tag not in tags:
                tags[tag] = {"count": 0, "last_used": ""}
            tags[tag]["count"] += 1
            if entry["date"] > tags[tag]["last_used"]:
                tags[tag]["last_used"] = entry["date"]
    return tags


def build_arsenal(entries):
    """Build arsenal file data from entries.

    Returns a dict of slug -> {skill, entries: [{date, title, description, impact, evidence_type, filename}]}
    """
    arsenal = {}
    for entry in entries:
        for skill in entry.get("skills_used", []):
            slug = slugify(skill)
            if slug not in arsenal:
                arsenal[slug] = {"skill": skill, "entries": []}
            arsenal[slug]["entries"].append({
                "date": entry["date"],
                "title": entry["title"],
                "description": entry.get("description", ""),
                "impact": entry.get("impact", ""),
                "evidence_type": entry.get("evidence_type", "accomplishment"),
                "filename": entry["filename"],
            })
    return arsenal


def proficiency_trend(count):
    """Determine proficiency trend from evidence count."""
    if count >= 8:
        return "expert"
    elif count >= 4:
        return "established"
    return "building"


def write_arsenal_files(arsenal_dir, arsenal_data):
    """Write arsenal markdown files, deleting stale ones first."""
    # Remove existing arsenal files
    if os.path.isdir(arsenal_dir):
        for f in os.listdir(arsenal_dir):
            if f.endswith(".md"):
                os.remove(os.path.join(arsenal_dir, f))
    else:
        os.makedirs(arsenal_dir, exist_ok=True)

    for slug, data in arsenal_data.items():
        skill = data["skill"]
        entries = sorted(data["entries"], key=lambda e: e["date"], reverse=True)
        count = len(entries)
        last_date = entries[0]["date"] if entries else ""
        trend = proficiency_trend(count)

        lines = [
            "---",
            f'skill: "{skill}"',
            f"evidence_count: {count}",
            f"last_demonstrated: {last_date}",
            f'proficiency_trend: "{trend}"',
            "---",
            "",
            f"# {skill}",
            "",
            "## Evidence",
        ]

        for e in entries:
            lines.append("")
            lines.append(f"### {e['date']} — {e['title']}")
            lines.append(f"- {e['description']}")
            lines.append(f"- Impact: {e['impact']}")
            lines.append(f"- Type: {e['evidence_type']}")
            lines.append(f"- [Full log](../logs/{e['filename']})")

        filepath = os.path.join(arsenal_dir, f"{slug}.md")
        write_atomic(filepath, "\n".join(lines) + "\n")


def write_atomic(filepath, content):
    """Write content to a file atomically via tmp + rename."""
    tmp = filepath + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, filepath)


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <things_path>", file=sys.stderr)
        sys.exit(1)

    things_path = os.path.expanduser(sys.argv[1])
    logs_dir = os.path.join(things_path, "logs")

    if not os.path.isdir(logs_dir):
        print(f"No logs directory at {logs_dir}", file=sys.stderr)
        sys.exit(0)

    # Process all log files
    entries = []
    for filename in sorted(os.listdir(logs_dir)):
        if not filename.endswith(".md"):
            continue
        filepath = os.path.join(logs_dir, filename)
        entry = process_log(filepath)
        if entry:
            entries.append(entry)

    # Sort by date descending
    entries.sort(key=lambda e: e["date"], reverse=True)

    # Build index.json
    today = date.today().isoformat()
    index_data = {
        "version": 1,
        "last_updated": today,
        "total_entries": len(entries),
        "entries": entries,
    }
    index_path = os.path.join(things_path, "index.json")
    write_atomic(index_path, json.dumps(index_data, indent=2, ensure_ascii=False) + "\n")

    # Build tags.json
    tags_map = build_tags(entries)
    tags_data = {
        "last_updated": today,
        "tags": tags_map,
    }
    tags_path = os.path.join(things_path, "tags.json")
    write_atomic(tags_path, json.dumps(tags_data, indent=2, ensure_ascii=False) + "\n")

    # Build and write arsenal files
    arsenal_data = build_arsenal(entries)
    arsenal_dir = os.path.join(things_path, "arsenal")
    write_arsenal_files(arsenal_dir, arsenal_data)

    print(f"Rebuilt: {len(entries)} entries, {len(tags_map)} tags, {len(arsenal_data)} arsenal skills")


if __name__ == "__main__":
    main()
