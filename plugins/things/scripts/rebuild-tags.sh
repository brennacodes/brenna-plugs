#!/usr/bin/env bash
# Rebuild central tag index from all registered collections that declare tags_field.
#
# Usage: rebuild-tags.sh
# Requires: THINGS_PATH environment variable (or defaults to ~/.things)
#
# Scans registry.json for collections with tags_field, extracts tags from each,
# and writes tags/index.json with aggregated counts and sources.

set -euo pipefail

THINGS_PATH="${THINGS_PATH:-$HOME/.things}"
REGISTRY="$THINGS_PATH/registry.json"
TAG_DIR="$THINGS_PATH/tags"
TAG_INDEX="$TAG_DIR/index.json"

if [[ ! -f "$REGISTRY" ]]; then
  exit 0
fi

mkdir -p "$TAG_DIR"

python3 -c "
import json, os, glob, re, sys
from datetime import datetime, timezone

things_path = '$THINGS_PATH'
registry_path = '$REGISTRY'
tag_index_path = '$TAG_INDEX'

with open(registry_path) as f:
    registry = json.load(f)

tags = {}  # tag_name -> { count, last_used, sources: { collection -> count } }

def parse_frontmatter_tags(filepath):
    \"\"\"Extract tags from YAML frontmatter in a markdown file.\"\"\"
    try:
        with open(filepath) as f:
            content = f.read()
    except (IOError, UnicodeDecodeError):
        return []
    if not content.startswith('---'):
        return []
    parts = content.split('---', 2)
    if len(parts) < 3:
        return []
    fm = parts[1]
    # Look for tags: line
    for line in fm.split('\n'):
        line = line.strip()
        if line.startswith('tags:'):
            val = line[5:].strip()
            if val.startswith('['):
                # Inline list: [a, b, c]
                val = val.strip('[]')
                return [t.strip().strip('\"').strip(\"'\") for t in val.split(',') if t.strip()]
            elif val == '' or val == '[]':
                # Block list follows, or empty
                result = []
                for next_line in fm.split('\n')[fm.split('\n').index(line.strip() if line.strip() in [l.strip() for l in fm.split('\n')] else '') + 1:]:
                    next_line_stripped = next_line.strip()
                    if next_line_stripped.startswith('- '):
                        result.append(next_line_stripped[2:].strip().strip('\"').strip(\"'\"))
                    elif next_line_stripped and not next_line_stripped.startswith('#'):
                        break
                return result
    return []

def extract_json_tags(filepath, field_path):
    \"\"\"Extract tags from a JSON file using a dotted path like 'json.tags' or 'json.goals[].tags'.\"\"\"
    try:
        with open(filepath) as f:
            data = json.load(f)
    except (IOError, json.JSONDecodeError, UnicodeDecodeError):
        return []

    # Remove 'json.' prefix
    path = field_path
    if path.startswith('json.'):
        path = path[5:]

    # Handle array notation like 'goals[].tags'
    if '[].' in path:
        parts = path.split('[].', 1)
        array_key = parts[0]
        rest = parts[1]
        arr = data.get(array_key, [])
        if not isinstance(arr, list):
            return []
        result = []
        for item in arr:
            if isinstance(item, dict):
                val = item.get(rest, [])
                if isinstance(val, list):
                    result.extend(val)
        return result
    else:
        val = data.get(path, [])
        return val if isinstance(val, list) else []

def get_file_date(filepath):
    \"\"\"Get file modification date as YYYY-MM-DD.\"\"\"
    try:
        mtime = os.path.getmtime(filepath)
        return datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')
    except OSError:
        return datetime.now().strftime('%Y-%m-%d')

for col_path, col_def in registry.get('collections', {}).items():
    tags_field = col_def.get('tags_field')
    if not tags_field:
        continue

    plugin = col_def.get('plugin', 'unknown')
    full_path = os.path.join(things_path, col_path)
    if not os.path.isdir(full_path):
        continue

    item_struct = col_def.get('item_structure', {})

    if tags_field.startswith('frontmatter.'):
        # Scan markdown files
        if item_struct.get('directory_per_item'):
            pattern = os.path.join(full_path, '**', '*.md')
        else:
            fp = item_struct.get('file_pattern', '*.md')
            pattern = os.path.join(full_path, fp)
        for filepath in glob.glob(pattern, recursive=True):
            file_tags = parse_frontmatter_tags(filepath)
            file_date = get_file_date(filepath)
            for tag in file_tags:
                tag = tag.lower().strip()
                if not tag:
                    continue
                if tag not in tags:
                    tags[tag] = {'count': 0, 'last_used': file_date, 'sources': {}}
                tags[tag]['count'] += 1
                if file_date > tags[tag]['last_used']:
                    tags[tag]['last_used'] = file_date
                src_key = col_path
                if src_key not in tags[tag]['sources']:
                    tags[tag]['sources'][src_key] = {'plugin': plugin, 'collection': col_path, 'count': 0}
                tags[tag]['sources'][src_key]['count'] += 1

    elif tags_field.startswith('json.'):
        # Scan JSON files
        if item_struct.get('directory_per_item'):
            # Look for the main JSON file in each subdirectory
            req_files = item_struct.get('required_files', [])
            json_files = [f for f in req_files if f.endswith('.json')]
            idx_file = item_struct.get('index_file', json_files[0] if json_files else 'index.json')
            for item_name in os.listdir(full_path):
                item_path = os.path.join(full_path, item_name)
                if not os.path.isdir(item_path):
                    continue
                json_path = os.path.join(item_path, idx_file)
                if not os.path.isfile(json_path):
                    # Try campaign.json pattern
                    for candidate in ['campaign.json', 'index.json']:
                        cpath = os.path.join(item_path, candidate)
                        if os.path.isfile(cpath):
                            json_path = cpath
                            break
                if not os.path.isfile(json_path):
                    continue
                file_tags = extract_json_tags(json_path, tags_field)
                file_date = get_file_date(json_path)
                for tag in file_tags:
                    tag = str(tag).lower().strip()
                    if not tag:
                        continue
                    if tag not in tags:
                        tags[tag] = {'count': 0, 'last_used': file_date, 'sources': {}}
                    tags[tag]['count'] += 1
                    if file_date > tags[tag]['last_used']:
                        tags[tag]['last_used'] = file_date
                    src_key = col_path
                    if src_key not in tags[tag]['sources']:
                        tags[tag]['sources'][src_key] = {'plugin': plugin, 'collection': col_path, 'count': 0}
                    tags[tag]['sources'][src_key]['count'] += 1
        else:
            fp = item_struct.get('file_pattern', '*.json')
            for filepath in glob.glob(os.path.join(full_path, fp)):
                file_tags = extract_json_tags(filepath, tags_field)
                file_date = get_file_date(filepath)
                for tag in file_tags:
                    tag = str(tag).lower().strip()
                    if not tag:
                        continue
                    if tag not in tags:
                        tags[tag] = {'count': 0, 'last_used': file_date, 'sources': {}}
                    tags[tag]['count'] += 1
                    if file_date > tags[tag]['last_used']:
                        tags[tag]['last_used'] = file_date
                    src_key = col_path
                    if src_key not in tags[tag]['sources']:
                        tags[tag]['sources'][src_key] = {'plugin': plugin, 'collection': col_path, 'count': 0}
                    tags[tag]['sources'][src_key]['count'] += 1

# Build output
output = {
    'version': '1.0.0',
    'last_updated': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'tags': {}
}

for tag_name in sorted(tags.keys()):
    t = tags[tag_name]
    output['tags'][tag_name] = {
        'count': t['count'],
        'last_used': t['last_used'],
        'sources': list(t['sources'].values())
    }

# Atomic write
tmp_path = tag_index_path + '.tmp'
with open(tmp_path, 'w') as f:
    json.dump(output, f, indent=2)
    f.write('\n')
os.rename(tmp_path, tag_index_path)
"
