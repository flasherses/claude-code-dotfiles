#!/bin/bash
# check-uncommitted.sh — Stop hook: 4-step quality gate
# Applies to ALL projects (user-level).
# WARNING only — never blocks stop (always exits 0).

cwd=$(pwd)

# === Gate 1: Uncommitted changes ===
echo ""
echo "=== Gate 1/4: Uncommitted Changes ==="
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    git_status=$(git -C "$cwd" status --porcelain 2>/dev/null)
    if [ -n "$git_status" ]; then
        count=$(echo "$git_status" | wc -l | tr -d ' ')
        echo "WARNING Gate 1: $count uncommitted file(s)" >&2
        echo "$git_status" >&2
    else
        echo "  PASS"
    fi
else
    echo "  PASS (not a git repo)"
fi

# === Gate 2: Test coverage check ===
echo ""
echo "=== Gate 2/4: Test Coverage ==="
changed_src=false
has_tests=false

if [ -d "$cwd/tests" ] || [ -d "$cwd/test" ] || [ -d "$cwd/__tests__" ] || [ -d "$cwd/spec" ]; then
    has_tests=true
fi

if [ -n "$git_status" ]; then
    if echo "$git_status" | grep -qE 'src/|lib/|app/'; then
        changed_src=true
    fi
fi

if [ "$changed_src" = true ] && [ "$has_tests" = true ]; then
    echo "WARNING Gate 2: Source changed and tests exist — consider running tests" >&2
else
    echo "  PASS (no tests or no source changes)"
fi

# === Gate 3: Debug code residue ===
echo ""
echo "=== Gate 3/4: Debug Code ==="
if [ -n "$git_status" ]; then
    diff_content=$(git -C "$cwd" diff HEAD 2>/dev/null)
    patterns=("console\.log" "print\(" "debugger" "TODO.*FIXME" "XXXXX")
    found_debug=false
    for p in "${patterns[@]}"; do
        if echo "$diff_content" | grep -qE "$p"; then
            if [ "$found_debug" = false ]; then
                echo "WARNING Gate 3: Possible debug code found:" >&2
                found_debug=true
            fi
            echo "  Pattern: $p" >&2
        fi
    done
    if [ "$found_debug" = false ]; then
        echo "  PASS"
    fi
else
    echo "  PASS"
fi

# === Gate 4: Sensitive files check ===
echo ""
echo "=== Gate 4/4: Sensitive Files ==="
if [ -n "$git_status" ]; then
    sensitive_patterns=("\.env$" "\.env\." "credentials\.json" "secrets\.yaml" "\.pem$" "\.key$")
    found_sensitive=false
    for sp in "${sensitive_patterns[@]}"; do
        matches=$(echo "$git_status" | grep -E "$sp")
        if [ -n "$matches" ]; then
            if [ "$found_sensitive" = false ]; then
                echo "WARNING Gate 4: Sensitive files in changes!" >&2
                found_sensitive=true
            fi
            echo "  File: $matches" >&2
        fi
    done
    if [ "$found_sensitive" = false ]; then
        echo "  PASS"
    fi
else
    echo "  PASS"
fi

echo ""
echo "=== Quality gate check complete ==="
exit 0
