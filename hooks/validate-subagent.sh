#!/bin/bash
# validate-subagent.sh — SubagentStop hook: validate sub-agent output format
# Reads sub-agent result from stdin JSON.
# Exit 0 = pass, Exit 2 = fail (forces sub-agent to retry)

input=$(cat)

if [ -z "$input" ]; then
    exit 0
fi

agent_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('agent_name',''))" 2>/dev/null)
result=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',''))" 2>/dev/null)

if [ -z "$result" ]; then
    echo "SubagentStop [$agent_name]: Empty output" >&2
    exit 2
fi

result_len=${#result}

# === Universal checks (all agents) ===

# 1. Minimum output length
if [ "$result_len" -lt 50 ]; then
    echo "SubagentStop [$agent_name]: Output too short ($result_len chars)" >&2
    exit 2
fi

# 2. Must have Markdown heading
if ! echo "$result" | grep -qE '^#{1,3}[[:space:]]+\w+'; then
    echo "SubagentStop [$agent_name]: Missing Markdown heading" >&2
    exit 2
fi

# 3. Must have substantive content
if ! echo "$result" | grep -qE '\w{30,}'; then
    echo "SubagentStop [$agent_name]: Missing substantive content" >&2
    exit 2
fi

# === Agent-specific validation ===

case "$agent_name" in
    code-reviewer)
        if ! echo "$result" | grep -qE 'Code Review|Critical|Warning|Suggestion'; then
            echo "SubagentStop [code-reviewer]: Missing standard report structure" >&2
            echo "  Expected: ## Code Review Report -> Critical -> Warnings -> Suggestions" >&2
            exit 2
        fi
        ;;
    security-auditor)
        if ! echo "$result" | grep -qE 'CWE-[0-9]+|OWASP|SQL.*Injection|XSS|Security Audit'; then
            echo "SubagentStop [security-auditor]: Missing security classification (CWE/OWASP)" >&2
            exit 2
        fi
        ;;
    doc-explorer)
        if ! echo "$result" | grep -qE '`[^`]+\.[a-z]+`|File:|\.py|\.ts|\.js|\.html'; then
            echo "SubagentStop [doc-explorer]: Missing file path references" >&2
            exit 2
        fi
        ;;
    test-runner)
        if ! echo "$result" | grep -qE 'Test Results|PASS|FAIL|Total:|Passed:|Failed:'; then
            echo "SubagentStop [test-runner]: Missing test result summary" >&2
            exit 2
        fi
        ;;
esac

echo "SubagentStop [$agent_name]: Output validation PASSED ($result_len chars)"
exit 0
