#!/bin/bash
# audit-edit.sh — PostToolUse hook: log every Edit/Write to audit trail
# Applies to ALL projects (user-level hook).
# Reads JSON from stdin. Exit 0 always (never blocks).

input=$(cat)

if [ -z "$input" ]; then
    exit 0
fi

tool=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)

if [ "$tool" != "Edit" ] && [ "$tool" != "Write" ]; then
    exit 0
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
file_path=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
cwd=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

audit_dir="$HOME/.claude/audit"
mkdir -p "$audit_dir"

log_file="$audit_dir/$(date '+%Y-%m-%d').log"
echo "[$timestamp] Tool=$tool | File=$file_path | CWD=$cwd" >> "$log_file"

exit 0
