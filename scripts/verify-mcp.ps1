# verify-mcp.ps1 — MCP connectivity verification script (Windows)
# Tests GitHub, Filesystem, and SQLite MCP server connectivity.
# Usage: powershell -File scripts/verify-mcp.ps1

param(
    [switch]$SkipGitHub,
    [switch]$SkipFilesystem,
    [switch]$SkipSqlite
)

$ErrorActionPreference = "Continue"
$allPassed = $true

Write-Host "=== MCP Connectivity Verification ==="
Write-Host ""

# ── Prerequisites ───────────────────────────────────────────

Write-Host "[0/3] Checking prerequisites..."
Write-Host ""

$nodeVersion = $null
try { $nodeVersion = node --version 2>$null } catch {}
if ($nodeVersion) {
    Write-Host "  Node.js: $nodeVersion — OK"
} else {
    Write-Host "  Node.js: NOT FOUND — install via: winget install OpenJS.NodeJS.LTS"
    $allPassed = $false
}

$npxVersion = $null
try { $npxVersion = npx --version 2>$null } catch {}
if ($npxVersion) {
    Write-Host "  npx: $npxVersion — OK"
} else {
    Write-Host "  npx: NOT FOUND (comes with Node.js)"
}

Write-Host ""

# ── 1. GitHub MCP ───────────────────────────────────────────

if (-not $SkipGitHub) {
    Write-Host "[1/3] Testing GitHub MCP..."

    $token = $env:GITHUB_PERSONAL_ACCESS_TOKEN
    if (-not $token) {
        Write-Host "  SKIP: GITHUB_PERSONAL_ACCESS_TOKEN not set"
        Write-Host "  Set: [System.Environment]::SetEnvironmentVariable('GITHUB_PERSONAL_ACCESS_TOKEN', 'ghp_...', 'User')"
    } else {
        # Verify the server package exists
        $result = npx -y @modelcontextprotocol/server-github --help 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "github") {
            Write-Host "  GitHub MCP Server: AVAILABLE"
        } else {
            Write-Host "  GitHub MCP Server: FAILED — $result"
            $allPassed = $false
        }
    }
    Write-Host ""
}

# ── 2. Filesystem MCP ───────────────────────────────────────

if (-not $SkipFilesystem) {
    Write-Host "[2/3] Testing Filesystem MCP..."

    $result = npx -y @modelcontextprotocol/server-filesystem --help 2>&1
    if ($LASTEXITCODE -eq 0 -or $result -match "filesystem") {
        Write-Host "  Filesystem MCP Server: AVAILABLE"
    } else {
        Write-Host "  Filesystem MCP Server: FAILED"
        $allPassed = $false
    }
    Write-Host ""
}

# ── 3. SQLite MCP ──────────────────────────────────────────

if (-not $SkipSqlite) {
    Write-Host "[3/3] Testing SQLite MCP..."

    $uvVersion = $null
    try { $uvVersion = uv --version 2>$null } catch {}
    if ($uvVersion) {
        Write-Host "  uv: $uvVersion — OK"
        $result = uvx mcp-server-sqlite --help 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "sqlite") {
            Write-Host "  SQLite MCP Server: AVAILABLE"
        } else {
            Write-Host "  SQLite MCP Server: FAILED"
            $allPassed = $false
        }
    } else {
        Write-Host "  uv: NOT FOUND — install via: pip install uv"
        Write-Host "  SQLite MCP requires uv. Skipping test."
        $allPassed = $false
    }
    Write-Host ""
}

# ── DeepSeek Compatibility Check ────────────────────────────

Write-Host "=== DeepSeek Proxy MCP Compatibility ==="
Write-Host ""
Write-Host "  DeepSeek API proxy (api.deepseek.com/anthropic) may not"
Write-Host "  support MCP tool discovery (tools/list) and invocation"
Write-Host "  (tools/call). This depends on how the proxy implements"
Write-Host "  the Anthropic Messages API."
Write-Host ""
Write-Host "  To verify:"
Write-Host "  1. Configure a GitHub MCP server in .mcp.json"
Write-Host "  2. Set ANTHROPIC_BASE_URL to your DeepSeek proxy"
Write-Host "  3. Start Claude Code and ask: 'What MCP tools are available?'"
Write-Host "  4. If no mcp__* tools appear, MCP is not supported by the proxy"
Write-Host "  5. Switch to ANTHROPIC_BASE_URL=https://api.anthropic.com to test"
Write-Host ""

# ── Summary ─────────────────────────────────────────────────

Write-Host "=== Result ==="
if ($allPassed) {
    Write-Host "  ALL CHECKS PASSED — MCP servers are ready to use."
    Write-Host "  Copy mcp/*.json to .mcp.json to enable."
} else {
    Write-Host "  Some checks failed. See above for fix instructions."
    Write-Host "  MCP is optional — all other engineering features work without it."
}
