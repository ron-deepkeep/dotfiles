#!/bin/bash
# Save current Rift window-to-workspace state
STATE_FILE="$HOME/.config/rift/state.json"

rift-cli query workspaces | python3 -c "
import json, sys
data = json.load(sys.stdin)
state = []
for ws in data:
    for w in ws['windows']:
        state.append({
            'bundle_id': w['bundle_id'],
            'app_name': w['app_name'],
            'title': w['title'],
            'workspace_index': ws['index'],
            'workspace_name': ws['name'],
            'window_id': w['id']
        })
print(json.dumps(state, indent=2))
" > "$STATE_FILE"

echo "Saved $(python3 -c "import json; print(len(json.load(open('$STATE_FILE'))))" ) windows to $STATE_FILE"
