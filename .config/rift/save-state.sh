#!/bin/bash
# Save current Rift window-to-workspace state
STATE_FILE="$HOME/.config/rift/state.json"
TMP_FILE="${STATE_FILE}.tmp"

if ! rift-cli query workspaces | python3 -c "
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
" > "$TMP_FILE"; then
    echo "ERROR: Failed to query rift state" >&2
    rm -f "$TMP_FILE"
    exit 1
fi

# Validate JSON before replacing
if ! python3 -c "import json; json.load(open('$TMP_FILE'))" 2>/dev/null; then
    echo "ERROR: Generated state is not valid JSON" >&2
    rm -f "$TMP_FILE"
    exit 1
fi

mv "$TMP_FILE" "$STATE_FILE"
echo "Saved $(python3 -c "import json; print(len(json.load(open('$STATE_FILE'))))" ) windows to $STATE_FILE"
