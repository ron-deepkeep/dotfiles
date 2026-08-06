#!/bin/bash
# Restore Rift window-to-workspace state from saved state
STATE_FILE="$HOME/.config/rift/state.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "No saved state found at $STATE_FILE"
    exit 1
fi

python3 -c "
import json, subprocess, sys, time

state_file = '$STATE_FILE'
with open(state_file) as f:
    saved = json.load(f)

# Get current windows from rift
result = subprocess.run(['rift-cli', 'query', 'workspaces'], capture_output=True, text=True)
current = json.loads(result.stdout)

# First, visit all target workspaces so rift initializes them
target_workspaces = sorted(set(entry['workspace_index'] for entry in saved))
for ws in target_workspaces:
    subprocess.run(['rift-cli', 'execute', 'workspace', 'switch', str(ws)], capture_output=True)
    time.sleep(0.3)

# Switch back to first workspace
subprocess.run(['rift-cli', 'execute', 'workspace', 'switch', '0'], capture_output=True)
time.sleep(0.3)

# Build map of current windows by exact id
current_windows = {}
for ws in current:
    for w in ws['windows']:
        key = (w['bundle_id'], w['id']['pid'], w['id']['idx'])
        current_windows[key] = {
            'window_id': w['id'],
            'current_workspace': ws['index'],
            'app_name': w['app_name']
        }

# Fallback match by bundle_id + title
current_by_bundle_title = {}
for ws in current:
    for w in ws['windows']:
        key = (w['bundle_id'], w['title'])
        if key not in current_by_bundle_title:
            current_by_bundle_title[key] = []
        current_by_bundle_title[key].append({
            'window_id': w['id'],
            'current_workspace': ws['index'],
            'app_name': w['app_name']
        })

# Fallback match by bundle_id only (for apps with changing titles)
current_by_bundle = {}
for ws in current:
    for w in ws['windows']:
        key = w['bundle_id']
        if key not in current_by_bundle:
            current_by_bundle[key] = []
        current_by_bundle[key].append({
            'window_id': w['id'],
            'current_workspace': ws['index'],
            'app_name': w['app_name']
        })

moved = 0
skipped = 0
not_found = 0

for entry in saved:
    target_ws = entry['workspace_index']
    info = None

    # Try exact match by pid+idx first
    exact_key = (entry['bundle_id'], entry['window_id']['pid'], entry['window_id']['idx'])
    if exact_key in current_windows:
        info = current_windows.pop(exact_key)
    else:
        # Fallback: match by bundle_id + title
        fallback_key = (entry['bundle_id'], entry['title'])
        if fallback_key in current_by_bundle_title and current_by_bundle_title[fallback_key]:
            info = current_by_bundle_title[fallback_key].pop(0)
        else:
            # Last resort: match by bundle_id only
            bkey = entry['bundle_id']
            if bkey in current_by_bundle and current_by_bundle[bkey]:
                info = current_by_bundle[bkey].pop(0)

    if info is None:
        print(f\"  Not found: {entry['app_name']} - {entry['title'][:50]}\")
        not_found += 1
        continue

    if info['current_workspace'] != target_ws:
        wid = str(info['window_id']['idx'])
        subprocess.run(['rift-cli', 'execute', 'workspace', 'move-window', str(target_ws), wid])
        time.sleep(0.1)
        print(f\"  Moved {info['app_name']} -> workspace {entry['workspace_name']} ({target_ws})\")
        moved += 1
    else:
        skipped += 1

print(f\"\nDone: {moved} moved, {skipped} already correct, {not_found} not found\")
"
