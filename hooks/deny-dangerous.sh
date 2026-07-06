#!/bin/bash
# deny-dangerous.sh — PreToolUse hook: block truly dangerous shell commands
# Applies to ALL projects (user-level hook).
# Reads JSON from stdin, outputs rejection reason to stderr.
# Exit 0 = allow, Exit 2 = deny.

# Read stdin (first argument for Claude Code hook compatibility)
input=$(cat)

if [ -z "$input" ]; then
    exit 0
fi

command=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$command" ]; then
    exit 0
fi

# Patterns that must NEVER execute automatically
# Check each dangerous pattern
if echo "$command" | grep -qE 'rm\s+-rf'; then
    echo "DENIED: Recursive force delete — irreversible data loss" >&2
    echo "Matched pattern: rm -rf" >&2
    echo "Command: $command" >&2
    exit 2
fi

if echo "$command" | grep -qE 'rm\s+-r\s+/'; then
    echo "DENIED: Recursive delete from root — system destruction" >&2
    exit 2
fi

if echo "$command" | grep -qE 'curl.*\|.*(sh|bash|sudo)'; then
    echo "DENIED: Pipe curl to shell — remote code execution risk" >&2
    exit 2
fi

if echo "$command" | grep -qE 'wget.*\|.*(sh|bash|sudo)'; then
    echo "DENIED: Pipe wget to shell — remote code execution risk" >&2
    exit 2
fi

if echo "$command" | grep -qE 'git\s+push\s+.*--force'; then
    echo "DENIED: Force push — overwrites remote history" >&2
    exit 2
fi

if echo "$command" | grep -qE 'git\s+push\s+.*-f\b'; then
    echo "DENIED: Force push (-f) — overwrites remote history" >&2
    exit 2
fi

if echo "$command" | grep -qE 'chmod\s+777'; then
    echo "DENIED: World-writable permissions — security risk" >&2
    exit 2
fi

if echo "$command" | grep -qE 'dd\s+if='; then
    echo "DENIED: Raw disk write — irreversible data loss" >&2
    exit 2
fi

if echo "$command" | grep -qE 'mkfs\.'; then
    echo "DENIED: Filesystem format — destroys all data on target" >&2
    exit 2
fi

exit 0
