#!/bin/bash
# verify-mcp.sh — MCP connectivity verification script (macOS/Linux)
# Usage: bash scripts/verify-mcp.sh

all_passed=true

echo "=== MCP Connectivity Verification ==="
echo ""

# ── Prerequisites ───────────────────────────────────────────

echo "[0/3] Checking prerequisites..."
echo ""

if command -v node &>/dev/null; then
    echo "  Node.js: $(node --version) — OK"
else
    echo "  Node.js: NOT FOUND — install via: brew install node (macOS) / apt install nodejs (Linux)"
    all_passed=false
fi

if command -v npx &>/dev/null; then
    echo "  npx: $(npx --version) — OK"
else
    echo "  npx: NOT FOUND"
fi

echo ""

# ── 1. GitHub MCP ───────────────────────────────────────────

echo "[1/3] Testing GitHub MCP..."

if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "  SKIP: GITHUB_PERSONAL_ACCESS_TOKEN not set"
    echo "  Set: export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_..."
else
    if npx -y @modelcontextprotocol/server-github --help &>/dev/null; then
        echo "  GitHub MCP Server: AVAILABLE"
    else
        echo "  GitHub MCP Server: FAILED"
        all_passed=false
    fi
fi
echo ""

# ── 2. Filesystem MCP ───────────────────────────────────────

echo "[2/3] Testing Filesystem MCP..."

if npx -y @modelcontextprotocol/server-filesystem --help &>/dev/null; then
    echo "  Filesystem MCP Server: AVAILABLE"
else
    echo "  Filesystem MCP Server: FAILED"
    all_passed=false
fi
echo ""

# ── 3. SQLite MCP ──────────────────────────────────────────

echo "[3/3] Testing SQLite MCP..."

if command -v uv &>/dev/null; then
    echo "  uv: $(uv --version) — OK"
    if uvx mcp-server-sqlite --help &>/dev/null; then
        echo "  SQLite MCP Server: AVAILABLE"
    else
        echo "  SQLite MCP Server: FAILED"
        all_passed=false
    fi
else
    echo "  uv: NOT FOUND — install via: pip install uv"
    all_passed=false
fi
echo ""

# ── DeepSeek Compatibility ──────────────────────────────────

echo "=== DeepSeek Proxy MCP Compatibility ==="
echo ""
echo "  DeepSeek API proxy may not support MCP tool discovery."
echo "  To verify: configure MCP, set ANTHROPIC_BASE_URL to proxy,"
echo "  and ask Claude: 'What MCP tools are available?'"
echo "  If no mcp__* tools appear, switch to Anthropic API direct."
echo ""

# ── Summary ─────────────────────────────────────────────────

echo "=== Result ==="
if [ "$all_passed" = true ]; then
    echo "  ALL CHECKS PASSED — MCP servers are ready."
else
    echo "  Some checks failed. MCP is optional."
fi
