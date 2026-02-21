#!/usr/bin/env python3
"""sesh - Claude Code session finder engine.

Subcommands:
    active              List recent sessions sorted by modified date
    search <query>      Search sessions by keyword in metadata or transcripts
    projects            List all projects with session counts
    resume <id>         Look up session by full or partial ID
"""

import argparse
import glob
import json
import os
import sys
from datetime import datetime, timedelta, timezone


CLAUDE_DIR = os.path.expanduser("~/.claude/projects")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_date(s):
    """Parse ISO date string or relative expression to a datetime."""
    s = s.strip().lower()
    now = datetime.now(timezone.utc)

    if s == "today":
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    if s == "yesterday":
        return (now - timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    if s == "last week":
        return now - timedelta(weeks=1)
    if s.endswith(" days ago"):
        try:
            n = int(s.split()[0])
            return now - timedelta(days=n)
        except ValueError:
            pass
    # ISO date
    for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f"):
        try:
            dt = datetime.strptime(s, fmt)
            return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    # ISO with Z suffix
    if s.endswith("z"):
        for fmt in ("%Y-%m-%dT%H:%M:%S.%fz", "%Y-%m-%dT%H:%M:%Sz"):
            try:
                dt = datetime.strptime(s, fmt)
                return dt.replace(tzinfo=timezone.utc)
            except ValueError:
                continue
    raise ValueError(f"Cannot parse date: {s!r}")


def iso_to_dt(iso_str):
    """Parse an ISO datetime string from session data."""
    if not iso_str:
        return None
    try:
        return parse_date(iso_str)
    except ValueError:
        return None


def shorten_project(path):
    """Shorten a project path for display."""
    home = os.path.expanduser("~")
    if path == home:
        return "~"
    if path.startswith(home + "/"):
        return "~/" + path[len(home) + 1:]
    return os.path.basename(path)


def discover_indexes():
    """Find all sessions-index.json files and return (index_path, original_path) pairs."""
    pattern = os.path.join(CLAUDE_DIR, "*/sessions-index.json")
    results = []
    for path in glob.glob(pattern):
        try:
            with open(path, "r") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        original_path = data.get("originalPath")
        if not original_path:
            entries = data.get("entries", [])
            if entries:
                original_path = entries[0].get("projectPath", "")
        if not original_path:
            # Derive from directory name
            dirname = os.path.basename(os.path.dirname(path))
            original_path = dirname.replace("-", "/").lstrip("/")
        results.append((path, original_path, data))
    return results


def load_all_sessions():
    """Load all sessions from all indexes, enriched with project info."""
    sessions = []
    for index_path, original_path, data in discover_indexes():
        for entry in data.get("entries", []):
            if entry.get("isSidechain", False):
                continue
            entry = dict(entry)
            if not entry.get("projectPath"):
                entry["projectPath"] = original_path
            entry["projectName"] = shorten_project(entry["projectPath"])
            entry["resumeCommand"] = (
                f'cd "{entry["projectPath"]}" && claude --resume {entry["sessionId"]}'
            )
            sessions.append(entry)
    return sessions


def search_transcript(jsonl_path, query):
    """Search a JSONL transcript for a query string. Returns True on first match."""
    query_lower = query.lower()
    try:
        with open(jsonl_path, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                msg_type = obj.get("type", "")
                if msg_type not in ("user", "assistant"):
                    continue
                message = obj.get("message", {})
                content = message.get("content", "")
                if isinstance(content, str):
                    if query_lower in content.lower():
                        return True
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            if query_lower in block.get("text", "").lower():
                                return True
    except OSError:
        pass
    return False


def match_project(session, project_filter):
    """Check if a session matches a project filter (substring, case-insensitive)."""
    if not project_filter:
        return True
    pf = project_filter.lower()
    return (
        pf in session.get("projectPath", "").lower()
        or pf in session.get("projectName", "").lower()
    )


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

def cmd_active(args):
    sessions = load_all_sessions()
    sessions.sort(key=lambda s: s.get("modified", ""), reverse=True)
    total = len(sessions)
    limited = sessions[: args.limit]
    print(json.dumps({
        "command": "active",
        "total": total,
        "showing": len(limited),
        "sessions": limited,
    }, indent=2))


def cmd_search(args):
    query = args.query
    query_lower = query.lower() if query else ""
    sessions = load_all_sessions()

    since_dt = parse_date(args.since) if args.since else None
    until_dt = parse_date(args.until) if args.until else None

    results = []
    for s in sessions:
        # Project filter
        if not match_project(s, args.project):
            continue

        # Date filters
        modified_dt = iso_to_dt(s.get("modified"))
        if since_dt and modified_dt and modified_dt < since_dt:
            continue
        if until_dt and modified_dt and modified_dt > until_dt:
            continue

        if not query_lower:
            # Empty query with project filter = list all sessions for project
            s["matchedIn"] = "project"
            results.append(s)
            continue

        # Metadata search
        summary = (s.get("summary") or "").lower()
        first_prompt = (s.get("firstPrompt") or "").lower()

        if query_lower in summary:
            s["matchedIn"] = "summary"
            results.append(s)
        elif query_lower in first_prompt:
            s["matchedIn"] = "firstPrompt"
            results.append(s)
        elif args.deep:
            # Deep search in transcript
            full_path = s.get("fullPath", "")
            if full_path and search_transcript(full_path, query):
                s["matchedIn"] = "transcript"
                results.append(s)

    results.sort(key=lambda s: s.get("modified", ""), reverse=True)
    total = len(results)
    limited = results[: args.limit] if args.limit else results

    print(json.dumps({
        "command": "search",
        "query": query,
        "deep": args.deep,
        "total": total,
        "showing": len(limited),
        "sessions": limited,
    }, indent=2))


def cmd_projects(args):
    indexes = discover_indexes()
    projects = []
    for index_path, original_path, data in indexes:
        entries = [e for e in data.get("entries", []) if not e.get("isSidechain", False)]
        if not entries:
            continue
        last_modified = max(
            (e.get("modified", "") for e in entries),
            default="",
        )
        projects.append({
            "projectPath": original_path,
            "projectName": shorten_project(original_path),
            "sessionCount": len(entries),
            "lastModified": last_modified,
        })
    projects.sort(key=lambda p: p["lastModified"], reverse=True)
    print(json.dumps({
        "command": "projects",
        "projects": projects,
    }, indent=2))


def cmd_resume(args):
    query = args.id
    sessions = load_all_sessions()
    matches = []
    for s in sessions:
        sid = s.get("sessionId", "")
        if sid == query:
            matches = [s]
            break
        if sid.startswith(query) or query in sid:
            matches.append(s)

    if not matches:
        print(json.dumps({
            "command": "resume",
            "error": f"No session found matching '{query}'",
        }, indent=2))
        sys.exit(1)

    if len(matches) == 1:
        s = matches[0]
        print(json.dumps({
            "command": "resume",
            "sessionId": s["sessionId"],
            "summary": s.get("summary", ""),
            "projectPath": s.get("projectPath", ""),
            "projectName": s.get("projectName", ""),
            "resumeCommand": s["resumeCommand"],
            "created": s.get("created", ""),
            "modified": s.get("modified", ""),
            "messageCount": s.get("messageCount", 0),
        }, indent=2))
    else:
        # Multiple matches
        print(json.dumps({
            "command": "resume",
            "query": query,
            "matchCount": len(matches),
            "matches": [
                {
                    "sessionId": s["sessionId"],
                    "summary": s.get("summary", ""),
                    "projectPath": s.get("projectPath", ""),
                    "projectName": s.get("projectName", ""),
                    "resumeCommand": s["resumeCommand"],
                    "created": s.get("created", ""),
                    "modified": s.get("modified", ""),
                    "messageCount": s.get("messageCount", 0),
                }
                for s in matches
            ],
        }, indent=2))


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        prog="sesh",
        description="Claude Code session finder",
    )
    sub = parser.add_subparsers(dest="command")

    # active
    p_active = sub.add_parser("active", help="List recent sessions")
    p_active.add_argument("--limit", type=int, default=10)

    # search
    p_search = sub.add_parser("search", help="Search sessions by keyword")
    p_search.add_argument("query", nargs="?", default="")
    p_search.add_argument("--project", default=None)
    p_search.add_argument("--since", default=None)
    p_search.add_argument("--until", default=None)
    p_search.add_argument("--limit", type=int, default=20)
    p_search.add_argument("--deep", action="store_true")

    # projects
    sub.add_parser("projects", help="List all projects with session counts")

    # resume
    p_resume = sub.add_parser("resume", help="Look up session and get resume command")
    p_resume.add_argument("id", help="Full or partial session ID")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    {
        "active": cmd_active,
        "search": cmd_search,
        "projects": cmd_projects,
        "resume": cmd_resume,
    }[args.command](args)


if __name__ == "__main__":
    main()
