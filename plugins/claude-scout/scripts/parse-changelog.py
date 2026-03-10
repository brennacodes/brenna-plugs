#!/usr/bin/env python3
"""Parse changelog files to structured JSON.

Supports:
- Keep a Changelog format (## [version] - date + ### Type sections)
- Claude Code variant (## version + prefixed items: Added/Fixed/Improved/etc.)
- Fallback: raw text extraction per ## heading

Uses SHA-256 hash caching to avoid re-parsing unchanged files.

Usage:
    python3 parse-changelog.py <changelog_path> <output_path>
    python3 parse-changelog.py --hash-only <changelog_path>
"""

import hashlib
import json
import os
import re
import sys
from datetime import date


def file_hash(filepath):
    """SHA-256 hash of a file's contents."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def infer_change_type(text):
    """Infer change type from item text prefix."""
    text_lower = text.lower().lstrip("- ").lstrip("* ")
    prefixes = {
        "added": "added",
        "add ": "added",
        "new ": "added",
        "fixed": "fixed",
        "fix ": "fixed",
        "improved": "improved",
        "improve ": "improved",
        "changed": "changed",
        "change ": "changed",
        "updated": "changed",
        "update ": "changed",
        "removed": "removed",
        "remove ": "removed",
        "deprecated": "deprecated",
        "deprecate ": "deprecated",
        "security": "security",
    }
    for prefix, change_type in prefixes.items():
        if text_lower.startswith(prefix):
            return change_type
    return "other"


def parse_keep_a_changelog(text):
    """Parse standard Keep a Changelog format.

    ## [version] - YYYY-MM-DD
    ### Added
    - item
    """
    entries = []
    # Match ## [version] - date or ## [version]
    version_pattern = re.compile(
        r"^##\s+\[([^\]]+)\](?:\s*-\s*(.+?))?$", re.MULTILINE
    )
    section_pattern = re.compile(r"^###\s+(.+)$", re.MULTILINE)
    item_pattern = re.compile(r"^[-*]\s+(.+)$", re.MULTILINE)

    versions = list(version_pattern.finditer(text))
    for i, match in enumerate(versions):
        version = match.group(1).strip()
        release_date = match.group(2).strip() if match.group(2) else ""

        # Get text between this version and the next
        start = match.end()
        end = versions[i + 1].start() if i + 1 < len(versions) else len(text)
        section_text = text[start:end]

        changes = []
        sections = list(section_pattern.finditer(section_text))

        if sections:
            for j, sec in enumerate(sections):
                change_type = sec.group(1).strip().lower()
                sec_start = sec.end()
                sec_end = (
                    sections[j + 1].start()
                    if j + 1 < len(sections)
                    else len(section_text)
                )
                items_text = section_text[sec_start:sec_end]
                for item in item_pattern.finditer(items_text):
                    changes.append(
                        {"type": change_type, "description": item.group(1).strip()}
                    )
        else:
            # No ### sections — infer types from items
            for item in item_pattern.finditer(section_text):
                desc = item.group(1).strip()
                changes.append(
                    {"type": infer_change_type(desc), "description": desc}
                )

        entries.append(
            {
                "version": version,
                "date": release_date,
                "changes": changes,
            }
        )

    return entries


def parse_claude_variant(text):
    """Parse Claude Code changelog variant.

    ## version
    - Added: description
    - Fixed: description
    """
    entries = []
    version_pattern = re.compile(r"^##\s+(.+?)$", re.MULTILINE)
    item_pattern = re.compile(r"^[-*]\s+(.+)$", re.MULTILINE)

    versions = list(version_pattern.finditer(text))
    for i, match in enumerate(versions):
        version = match.group(1).strip()

        start = match.end()
        end = versions[i + 1].start() if i + 1 < len(versions) else len(text)
        section_text = text[start:end]

        changes = []
        for item in item_pattern.finditer(section_text):
            desc = item.group(1).strip()
            changes.append(
                {"type": infer_change_type(desc), "description": desc}
            )

        entries.append(
            {
                "version": version,
                "date": "",
                "changes": changes,
            }
        )

    return entries


def detect_and_parse(text):
    """Auto-detect format and parse."""
    # Check for Keep a Changelog format: ## [version]
    if re.search(r"^##\s+\[", text, re.MULTILINE):
        return parse_keep_a_changelog(text)
    # Check for ## headings (Claude variant or generic)
    if re.search(r"^##\s+", text, re.MULTILINE):
        return parse_claude_variant(text)
    return []


def write_atomic(filepath, content):
    """Write content atomically via tmp + rename."""
    tmp = filepath + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, filepath)


def main():
    if len(sys.argv) < 3:
        if len(sys.argv) == 3 and sys.argv[1] == "--hash-only":
            pass
        else:
            print(
                f"Usage: {sys.argv[0]} <changelog_path> <output_path>",
                file=sys.stderr,
            )
            print(
                f"       {sys.argv[0]} --hash-only <changelog_path>",
                file=sys.stderr,
            )
            sys.exit(1)

    if sys.argv[1] == "--hash-only":
        changelog_path = os.path.expanduser(sys.argv[2])
        if not os.path.isfile(changelog_path):
            print(json.dumps({"error": f"File not found: {changelog_path}"}))
            sys.exit(1)
        print(json.dumps({"hash": file_hash(changelog_path)}))
        return

    changelog_path = os.path.expanduser(sys.argv[1])
    output_path = os.path.expanduser(sys.argv[2])

    if not os.path.isfile(changelog_path):
        print(json.dumps({"error": f"File not found: {changelog_path}"}))
        sys.exit(1)

    # Check cache
    current_hash = file_hash(changelog_path)
    if os.path.isfile(output_path):
        try:
            with open(output_path, "r", encoding="utf-8") as f:
                cached = json.load(f)
            if cached.get("source_hash") == current_hash:
                print(json.dumps({"status": "cached", "hash": current_hash}))
                return
        except (json.JSONDecodeError, KeyError):
            pass

    # Parse
    with open(changelog_path, "r", encoding="utf-8") as f:
        text = f.read()

    entries = detect_and_parse(text)

    result = {
        "version": 1,
        "source": changelog_path,
        "source_hash": current_hash,
        "parsed_date": date.today().isoformat(),
        "total_entries": len(entries),
        "entries": entries,
    }

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    write_atomic(output_path, json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    print(
        json.dumps(
            {
                "status": "parsed",
                "hash": current_hash,
                "entries": len(entries),
            }
        )
    )


if __name__ == "__main__":
    main()
