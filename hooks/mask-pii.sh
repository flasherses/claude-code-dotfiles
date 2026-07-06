#!/bin/bash
# mask-pii.sh — PostToolUse hook: detect and warn about PII in output
# Exit 0 always (warns but never blocks).

input=$(cat)
if [ -z "$input" ]; then exit 0; fi

tool=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
if [ "$tool" != "Edit" ] && [ "$tool" != "Write" ]; then exit 0; fi

file_path=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
content=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('content',''))" 2>/dev/null)

if [ -z "$content" ]; then exit 0; fi

warnings=0

# China ID Card (18 digits with checksum)
if echo "$content" | grep -qP '[1-9]\d{5}(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]'; then
    count=$(echo "$content" | grep -oP '[1-9]\d{5}(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]' | wc -l | tr -d ' ')
    echo "PII WARNING: $count China ID Card(s) in $file_path" >&2
    warnings=$((warnings + 1))
fi

# China Mobile
if echo "$content" | grep -qP '1[3-9]\d{9}'; then
    count=$(echo "$content" | grep -oP '1[3-9]\d{9}' | wc -l | tr -d ' ')
    echo "PII WARNING: $count China Mobile(s) in $file_path" >&2
    warnings=$((warnings + 1))
fi

# Email
if echo "$content" | grep -qP '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}'; then
    count=$(echo "$content" | grep -oP '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}' | wc -l | tr -d ' ')
    echo "PII WARNING: $count Email(s) in $file_path" >&2
    warnings=$((warnings + 1))
fi

# Bank Card
if echo "$content" | grep -qP '\b\d{16,19}\b'; then
    count=$(echo "$content" | grep -oP '\b\d{16,19}\b' | wc -l | tr -d ' ')
    echo "PII WARNING: $count potential Bank Card(s) in $file_path" >&2
    warnings=$((warnings + 1))
fi

if [ $warnings -gt 0 ]; then
    echo "  Consider masking or using test data instead." >&2
fi

exit 0
