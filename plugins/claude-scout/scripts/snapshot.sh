#!/usr/bin/env bash
# snapshot.sh — Git operations for snapshotting a target directory
#
# Subcommands:
#   init <path> <branch>          Initialize git tracking on orphan branch
#   snapshot <path> <branch> [msg] Capture current state as a commit
#   status <path> <branch>        Check for changes since last snapshot
#   diff-stat <path> <branch> [from] [to]  Show diff stats between refs
#
# All output is JSON to stdout. Errors go to stderr.

set -euo pipefail

json_error() {
  echo "{\"error\": \"$1\"}" >&2
  exit 1
}

cmd_init() {
  local target_path="$1"
  local branch="${2:-claude-scout}"

  if [ ! -d "$target_path" ]; then
    json_error "Target path does not exist: $target_path"
  fi

  local git_dir="$target_path/.git"
  local needs_init=true

  if [ -d "$git_dir" ]; then
    # Already a git repo — check if our branch exists
    if git -C "$target_path" rev-parse --verify "$branch" >/dev/null 2>&1; then
      echo "{\"status\": \"exists\", \"branch\": \"$branch\", \"path\": \"$target_path\"}"
      return 0
    fi
    needs_init=false
  fi

  if [ "$needs_init" = true ]; then
    git -C "$target_path" init -q 2>/dev/null
  fi

  # Create orphan branch
  git -C "$target_path" checkout --orphan "$branch" 2>/dev/null

  # Write default .gitignore
  cat > "$target_path/.gitignore" << 'GITIGNORE'
# claude-scout defaults: exclude large/sensitive directories
debug/
file-history/
paste-cache/
.credentials.json
*.tmp
GITIGNORE

  git -C "$target_path" add .gitignore 2>/dev/null
  git -C "$target_path" commit --no-verify -q -m "claude-scout: initial setup" 2>/dev/null

  local sha
  sha=$(git -C "$target_path" rev-parse HEAD 2>/dev/null)

  echo "{\"status\": \"initialized\", \"branch\": \"$branch\", \"sha\": \"$sha\", \"path\": \"$target_path\"}"
}

cmd_snapshot() {
  local target_path="$1"
  local branch="${2:-claude-scout}"
  local message="${3:-snapshot}"

  if [ ! -d "$target_path/.git" ]; then
    json_error "Not a git repo: $target_path"
  fi

  # Ensure we're on the right branch
  local current_branch
  current_branch=$(git -C "$target_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$current_branch" != "$branch" ]; then
    git -C "$target_path" checkout "$branch" -q 2>/dev/null
  fi

  # Stage everything (respecting .gitignore)
  git -C "$target_path" add -A 2>/dev/null

  # Check if there are changes to commit
  if git -C "$target_path" diff --cached --quiet 2>/dev/null; then
    echo "{\"status\": \"no_changes\", \"branch\": \"$branch\"}"
    return 0
  fi

  # Commit
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  git -C "$target_path" commit --no-verify -q -m "snapshot: $message ($timestamp)" 2>/dev/null

  local sha
  sha=$(git -C "$target_path" rev-parse HEAD 2>/dev/null)

  # Get diff stats from this commit
  local stats
  stats=$(git -C "$target_path" diff --stat --numstat HEAD~1..HEAD 2>/dev/null || echo "")

  local files_changed=0 insertions=0 deletions=0
  if [ -n "$stats" ]; then
    while IFS=$'\t' read -r added deleted file; do
      if [ -n "$file" ] && [ "$added" != "-" ]; then
        files_changed=$((files_changed + 1))
        insertions=$((insertions + added))
        deletions=$((deletions + deleted))
      fi
    done <<< "$stats"
  fi

  echo "{\"status\": \"committed\", \"branch\": \"$branch\", \"sha\": \"$sha\", \"timestamp\": \"$timestamp\", \"files_changed\": $files_changed, \"insertions\": $insertions, \"deletions\": $deletions}"
}

cmd_status() {
  local target_path="$1"
  local branch="${2:-claude-scout}"

  if [ ! -d "$target_path/.git" ]; then
    json_error "Not a git repo: $target_path"
  fi

  # Ensure we're on the right branch
  local current_branch
  current_branch=$(git -C "$target_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$current_branch" != "$branch" ]; then
    git -C "$target_path" checkout "$branch" -q 2>/dev/null
  fi

  # Stage everything to see what would change
  git -C "$target_path" add -A --dry-run 2>/dev/null | head -100 > /tmp/cs-status-$$.txt || true

  # Also check for modifications to tracked files
  local modified
  modified=$(git -C "$target_path" status --porcelain 2>/dev/null | head -100)

  local has_changes=false
  local added=0 modified_count=0 deleted=0 renamed=0

  if [ -n "$modified" ]; then
    has_changes=true
    added=$(echo "$modified" | grep -c '^??' || true)
    modified_count=$(echo "$modified" | grep -c '^ M\|^M ' || true)
    deleted=$(echo "$modified" | grep -c '^ D\|^D ' || true)
    renamed=$(echo "$modified" | grep -c '^R' || true)
  fi

  rm -f /tmp/cs-status-$$.txt

  local last_sha last_date
  last_sha=$(git -C "$target_path" rev-parse HEAD 2>/dev/null || echo "none")
  last_date=$(git -C "$target_path" log -1 --format="%aI" 2>/dev/null || echo "never")

  echo "{\"has_changes\": $has_changes, \"added\": $added, \"modified\": $modified_count, \"deleted\": $deleted, \"renamed\": $renamed, \"last_sha\": \"$last_sha\", \"last_date\": \"$last_date\"}"
}

cmd_diff_stat() {
  local target_path="$1"
  local branch="${2:-claude-scout}"
  local from_ref="${3:-HEAD~1}"
  local to_ref="${4:-HEAD}"

  if [ ! -d "$target_path/.git" ]; then
    json_error "Not a git repo: $target_path"
  fi

  # Ensure we're on the right branch
  local current_branch
  current_branch=$(git -C "$target_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$current_branch" != "$branch" ]; then
    git -C "$target_path" checkout "$branch" -q 2>/dev/null
  fi

  # Validate refs
  if ! git -C "$target_path" rev-parse --verify "$from_ref" >/dev/null 2>&1; then
    json_error "Invalid from ref: $from_ref"
  fi
  if ! git -C "$target_path" rev-parse --verify "$to_ref" >/dev/null 2>&1; then
    json_error "Invalid to ref: $to_ref"
  fi

  # Get file changes
  local changes
  changes=$(git -C "$target_path" diff --name-status "$from_ref".."$to_ref" 2>/dev/null || echo "")

  # Build JSON array of changes
  local json_items=""
  local total=0

  while IFS=$'\t' read -r status file newfile; do
    [ -z "$status" ] && continue
    total=$((total + 1))

    local change_type
    case "$status" in
      A) change_type="added" ;;
      M) change_type="modified" ;;
      D) change_type="deleted" ;;
      R*) change_type="renamed" ;;
      *) change_type="other" ;;
    esac

    if [ -n "$json_items" ]; then
      json_items="$json_items,"
    fi

    if [ "$change_type" = "renamed" ] && [ -n "$newfile" ]; then
      json_items="$json_items{\"status\": \"$change_type\", \"file\": \"$newfile\", \"old_file\": \"$file\"}"
    else
      json_items="$json_items{\"status\": \"$change_type\", \"file\": \"$file\"}"
    fi
  done <<< "$changes"

  local from_sha to_sha
  from_sha=$(git -C "$target_path" rev-parse "$from_ref" 2>/dev/null)
  to_sha=$(git -C "$target_path" rev-parse "$to_ref" 2>/dev/null)

  echo "{\"from\": \"$from_sha\", \"to\": \"$to_sha\", \"total_changes\": $total, \"changes\": [$json_items]}"
}

# --- Main dispatch ---
command="${1:-}"
shift || true

case "$command" in
  init)      cmd_init "$@" ;;
  snapshot)  cmd_snapshot "$@" ;;
  status)    cmd_status "$@" ;;
  diff-stat) cmd_diff_stat "$@" ;;
  *)
    json_error "Unknown command: $command. Use: init, snapshot, status, diff-stat"
    ;;
esac
