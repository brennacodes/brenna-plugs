#!/usr/bin/env bash
# Quick structural validation of .things/ collections.
#
# Usage: validate-structure.sh <things_path> [collection_path]
#
# Checks directory existence, required files, JSON validity.
# Returns JSON array of issues found.

set -euo pipefail

THINGS_PATH="${1:?Usage: validate-structure.sh <things_path> [collection_path]}"
COLLECTION="${2:-}"
REGISTRY="$THINGS_PATH/registry.json"

if [[ ! -f "$REGISTRY" ]]; then
  echo '{"error": "registry.json not found"}'
  exit 1
fi

python3 -c "
import json, os, sys, glob

things_path = '$THINGS_PATH'
target_collection = '$COLLECTION' or None
registry_path = os.path.join(things_path, 'registry.json')

with open(registry_path) as f:
    registry = json.load(f)

issues = []

for col_path, col_def in registry.get('collections', {}).items():
    if target_collection and col_path != target_collection:
        continue

    full_path = os.path.join(things_path, col_path)

    # Check directory exists
    if not os.path.isdir(full_path):
        issues.append({
            'severity': 'error',
            'collection': col_path,
            'message': 'directory does not exist'
        })
        continue

    item_struct = col_def.get('item_structure', {})

    if item_struct.get('directory_per_item'):
        required_files = item_struct.get('required_files', [])
        # Check each subdirectory
        for item_name in sorted(os.listdir(full_path)):
            item_path = os.path.join(full_path, item_name)
            if not os.path.isdir(item_path):
                continue
            if item_name.startswith('.'):
                continue
            # Skip master-index files
            if item_name.endswith('.json'):
                continue
            for req_file in required_files:
                if not os.path.isfile(os.path.join(item_path, req_file)):
                    issues.append({
                        'severity': 'warning',
                        'collection': col_path,
                        'item': item_name,
                        'message': f'missing required file: {req_file}'
                    })

    # Check master index
    master_index = col_def.get('master_index')
    if master_index:
        mi_path = os.path.join(things_path, master_index)
        if not os.path.isfile(mi_path):
            issues.append({
                'severity': 'warning',
                'collection': col_path,
                'message': f'master index not found: {master_index}'
            })
        else:
            try:
                with open(mi_path) as f:
                    json.load(f)
            except json.JSONDecodeError as e:
                issues.append({
                    'severity': 'error',
                    'collection': col_path,
                    'message': f'master index is invalid JSON: {e}'
                })

print(json.dumps({'issues': issues, 'total': len(issues)}, indent=2))
"
