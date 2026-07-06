#!/bin/bash
# health-check.sh — Claude Code Engineering System Health Check (macOS/Linux)
# Usage: bash scripts/health-check.sh [--mcp]

CLAUDE_DIR="${HOME}/.claude"
CHECK_MCP=false
[[ "$1" == "--mcp" ]] && CHECK_MCP=true

pass=0; fail=0; warn=0

_pass() { echo "  PASS: $1"; pass=$((pass+1)); }
_fail() { echo "  FAIL: $1"; fail=$((fail+1)); }
_warn() { echo "  WARN: $1"; warn=$((warn+1)); }

echo "=== Claude Code Engineering Health Check ==="
echo "Claude dir: $CLAUDE_DIR"
echo ""

# ── 1. Core Files ──────────────────────────────────────────

echo "[1/8] Core Files"
for f in CLAUDE.md settings.json; do
    [ -f "$CLAUDE_DIR/$f" ] && _pass "$f" || _fail "$f missing"
done
echo ""

# ── 2. JSON Validity ───────────────────────────────────────

echo "[2/8] JSON Validity"
for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.example.json"; do
    [ -f "$f" ] || continue
    if python3 -m json.tool "$f" > /dev/null 2>&1; then
        _pass "$(basename "$f")"
    else
        _fail "$(basename "$f")"
    fi
done
echo ""

# ── 3. Shell Hook Syntax ──────────────────────────────────

echo "[3/8] Shell Hook Syntax"
sh_count=0
for f in "$CLAUDE_DIR"/hooks/*.sh; do
    [ -f "$f" ] || continue
    sh_count=$((sh_count+1))
    if bash -n "$f" 2>/dev/null; then
        _pass "$(basename "$f")"
    else
        _fail "$(basename "$f")"
    fi
done
[ $sh_count -eq 0 ] && _pass "No .sh hooks"
echo ""

# ── 4. PowerShell Hook Syntax ──────────────────────────────

echo "[4/8] PowerShell Hook Syntax"
if command -v pwsh &>/dev/null; then
    for f in "$CLAUDE_DIR"/hooks/*.ps1; do
        [ -f "$f" ] || continue
        if pwsh -NoProfile -Command "
            [System.Management.Automation.Language.Parser]::ParseFile('$f', [ref]\$null, [ref]\$null)
        " 2>/dev/null; then
            _pass "$(basename "$f")"
        else
            _fail "$(basename "$f")"
        fi
    done
else
    _warn "pwsh not available — skipping .ps1 check"
fi
echo ""

# ── 5. Rules Frontmatter ───────────────────────────────────

echo "[5/8] Rules YAML Frontmatter"
rule_count=0
for f in "$CLAUDE_DIR"/rules/*.md; do
    [ -f "$f" ] || continue
    rule_count=$((rule_count+1))
    if head -1 "$f" | grep -q '^---'; then
        _pass "$(basename "$f")"
    else
        _fail "$(basename "$f"): missing YAML frontmatter"
    fi
done
[ $rule_count -eq 0 ] && _warn "No rules found"
echo ""

# ── 6. Agents Required Fields ──────────────────────────────

echo "[6/8] Agents Required Fields"
agent_count=0
for f in "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    agent_count=$((agent_count+1))
    issues=""
    grep -q '^name:' "$f" || issues="$issues name"
    grep -q '^description:' "$f" || issues="$issues description"
    grep -q '^tools:' "$f" || issues="$issues tools"
    [ -z "$issues" ] && _pass "$(basename "$f")" || _fail "$(basename "$f"): missing$issues"
done
[ $agent_count -eq 0 ] && _warn "No agents found"
echo ""

# ── 7. Hooks Registration ──────────────────────────────────

echo "[7/8] Hooks Registration"
if ls "$CLAUDE_DIR"/hooks/*.ps1 "$CLAUDE_DIR"/hooks/*.sh &>/dev/null | head -1 | grep -q .; then
    if python3 -c "
import json
with open('$CLAUDE_DIR/settings.json') as f:
    d = json.load(f)
    assert 'hooks' in d, 'hooks missing'
    print(len(d['hooks']), 'events')
" 2>/dev/null; then
        _pass "Hooks registered"
    else
        _fail "Hooks exist but NOT registered in settings.json"
    fi
else
    _pass "No hooks"
fi
echo ""

# ── 8. Audit Log ───────────────────────────────────────────

echo "[8/8] Audit Log"
audit_dir="$CLAUDE_DIR/audit"
if [ -d "$audit_dir" ]; then
    recent=$(find "$audit_dir" -name "*.log" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
    if [ "$recent" -gt 0 ]; then
        _pass "Audit active ($recent recent logs)"
    else
        _warn "No recent audit logs"
    fi
else
    _warn "No audit directory"
fi
echo ""

# ── Optional: MCP ──────────────────────────────────────────

if $CHECK_MCP; then
    echo "[OPT] MCP Connectivity"
    verify_script="$(dirname "$0")/verify-mcp.sh"
    [ -f "$verify_script" ] && bash "$verify_script" || _warn "verify-mcp.sh not found"
fi

# ── Summary ─────────────────────────────────────────────────

echo "============================================"
echo "  PASS : $pass"
echo "  FAIL : $fail"
echo "  WARN : $warn"
echo "============================================"

if [ $fail -eq 0 ] && [ $warn -eq 0 ]; then
    echo "Status: HEALTHY"
elif [ $fail -eq 0 ]; then
    echo "Status: WARNINGS — functional, review warnings"
else
    echo "Status: FIXES NEEDED — resolve $fail failure(s)"
fi
