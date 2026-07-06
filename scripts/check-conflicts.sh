#!/bin/bash
# check-conflicts.sh — Claude Code Config Conflict Detector (macOS/Linux)
# Usage: bash scripts/check-conflicts.sh [project-path]

PROJECT_PATH="${1:-$(pwd)}"
USER_DIR="$HOME/.claude"
errors=0
warnings=0

echo "=== Claude Code Config Conflict Detector ==="
echo "User dir : $USER_DIR"
echo "Project  : $PROJECT_PATH"
echo ""

# ── 1. Check Overly Broad Rules ────────────────────────────

echo "=== 1. Overly Broad Rules ==="
for f in "$USER_DIR/settings.json" "$PROJECT_PATH/.claude/settings.json" "$PROJECT_PATH/.claude/settings.local.json"; do
    [ -f "$f" ] || continue
    label=$(basename "$(dirname "$f")")/$(basename "$f")
    [[ "$f" == "$USER_DIR"* ]] && label="user/settings.json"
    [[ "$f" == "$PROJECT_PATH"* ]] && label="project/$(basename "$f")"

    if python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
    p = d.get('permissions',{})
    for level in ['allow','ask','deny']:
        for rule in p.get(level,[]):
            if rule in ['Read(*)','Glob(*)','Grep(*)','Edit(*)','Write(*)','Bash(*)']:
                print(f'  FAIL [{label}] {rule} — unrestricted access')
                sys.exit(1)
" 2>/dev/null; then
        :
    else
        errors=$((errors+1))
    fi
done
if [ $errors -eq 0 ]; then echo "  PASS: No overly broad rules"; fi
echo ""

# ── 2. Cross-Level Conflicts ────────────────────────────────

echo "=== 2. Cross-Level Conflicts ==="
conflicts=0
user_json="$USER_DIR/settings.json"
proj_json="$PROJECT_PATH/.claude/settings.json"

if [ -f "$user_json" ] && [ -f "$proj_json" ]; then
    python3 -c "
import json
with open('$user_json') as f: u = json.load(f).get('permissions',{})
with open('$proj_json') as f: p = json.load(f).get('permissions',{})
for level in ['allow','ask','deny']:
    ur = u.get(level,[])
    pr = p.get(level,[])
    for r in ur:
        if r in pr:
            print(f'  REDUNDANT: {level}[{r}] in both user and project')
" 2>/dev/null | while read line; do
        echo "$line"
        conflicts=$((conflicts+1))
    done
fi
if [ $conflicts -eq 0 ]; then echo "  PASS: No cross-level conflicts"; fi
echo ""

# ── 3. Missing Config ──────────────────────────────────────

echo "=== 3. Missing Config ==="
if [ ! -f "$PROJECT_PATH/CLAUDE.md" ]; then
    echo "  WARNING: No project CLAUDE.md"
    warnings=$((warnings+1))
fi
if [ ! -f "$PROJECT_PATH/.claudeignore" ]; then
    echo "  INFO: No .claudeignore"
fi
echo ""

# ── Summary ─────────────────────────────────────────────────

echo "=== Result ==="
echo "  Errors  : $errors"
echo "  Warnings: $warnings"
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "  Status  : CLEAN"
elif [ $errors -eq 0 ]; then
    echo "  Status  : WARNINGS ONLY"
else
    echo "  Status  : FIX REQUIRED"
fi
