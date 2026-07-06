# health-check.ps1 — Claude Code Engineering System Health Check (Windows)
# One-command validation of the entire engineering system.
# Usage: powershell -File scripts/health-check.ps1 [--mcp]

param(
    [switch]$CheckMcp,
    [string]$ClaudeDir = "$env:USERPROFILE\.claude"
)

$pass = 0; $fail = 0; $warn = 0

function Pass($msg) { Write-Host "  PASS: $msg"; $script:pass++ }
function Fail($msg) { Write-Host "  FAIL: $msg"; $script:fail++ }
function Warn($msg) { Write-Host "  WARN: $msg"; $script:warn++ }

Write-Host "=== Claude Code Engineering Health Check ==="
Write-Host "Claude dir: $ClaudeDir"
Write-Host ""

# ── 1. Core Files ──────────────────────────────────────────

Write-Host "[1/8] Core Files"
@("CLAUDE.md", "settings.json") | ForEach-Object {
    if (Test-Path "$ClaudeDir\$_") { Pass $_ } else { Fail "$_ missing" }
}
Write-Host ""

# ── 2. JSON Validity ───────────────────────────────────────

Write-Host "[2/8] JSON Validity"
foreach ($f in @("$ClaudeDir\settings.json", "$ClaudeDir\settings.example.json")) {
    if (-not (Test-Path $f)) { continue }
    try {
        Get-Content $f -Raw | ConvertFrom-Json | Out-Null
        Pass (Split-Path $f -Leaf)
    } catch {
        Fail "$(Split-Path $f -Leaf): $($_.Exception.Message.Substring(0,[Math]::Min(60,$_.Exception.Message.Length)))"
    }
}
Write-Host ""

# ── 3. PowerShell Hook Syntax ──────────────────────────────

Write-Host "[3/8] PowerShell Hook Syntax"
$psFiles = @(Get-ChildItem "$ClaudeDir\hooks\*.ps1" -ErrorAction SilentlyContinue)
if ($psFiles.Count -eq 0) {
    Warn "No .ps1 hooks found"
} else {
    foreach ($f in $psFiles) {
        $tokens = $null; $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -eq 0) { Pass $f.Name }
        else { Fail "$($f.Name): $($parseErrors[0])" }
    }
}
Write-Host ""

# ── 4. Bash Hook Syntax ─────────────────────────────────────

Write-Host "[4/8] Bash Hook Syntax"
$shFiles = @(Get-ChildItem "$ClaudeDir\hooks\*.sh" -ErrorAction SilentlyContinue)
if ($shFiles.Count -eq 0) {
    Pass "No .sh hooks (Windows only setup)"
} else {
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) {
        Warn "bash not available — skipping .sh syntax check"
    } else {
        foreach ($f in $shFiles) {
            $result = bash -n $f.FullName 2>&1
            if ($LASTEXITCODE -eq 0) { Pass $f.Name }
            else { Fail "$($f.Name): $result" }
        }
    }
}
Write-Host ""

# ── 5. Rules Frontmatter ───────────────────────────────────

Write-Host "[5/8] Rules YAML Frontmatter"
$ruleFiles = @(Get-ChildItem "$ClaudeDir\rules\*.md" -ErrorAction SilentlyContinue)
if ($ruleFiles.Count -eq 0) {
    Warn "No rules found"
} else {
    foreach ($f in $ruleFiles) {
        $firstLine = Get-Content $f.FullName -First 1
        if ($firstLine -eq '---') { Pass $f.Name }
        else { Fail "$($f.Name): missing YAML frontmatter (add --- at top)" }
    }
}
Write-Host ""

# ── 6. Agents Required Fields ──────────────────────────────

Write-Host "[6/8] Agents Required Fields"
$agentFiles = @(Get-ChildItem "$ClaudeDir\agents\*.md" -ErrorAction SilentlyContinue)
if ($agentFiles.Count -eq 0) {
    Warn "No agents found"
} else {
    foreach ($f in $agentFiles) {
        $content = Get-Content $f.FullName -Raw
        $hasName = $content -match '^name:\s*\S+'
        $hasDesc = $content -match '^description:'
        $hasTools = $content -match '^tools:'
        $issues = @()
        if (-not $hasName) { $issues += "name" }
        if (-not $hasDesc) { $issues += "description" }
        if (-not $hasTools) { $issues += "tools" }
        if ($issues.Count -eq 0) { Pass $f.Name }
        else { Fail "$($f.Name): missing $($issues -join ', ')" }
    }
}
Write-Host ""

# ── 7. Hooks Registration ──────────────────────────────────

Write-Host "[7/8] Hooks Registration"
$hasHooks = (Get-ChildItem "$ClaudeDir\hooks\*.ps1" -ErrorAction SilentlyContinue).Count -gt 0
$hasSettings = Test-Path "$ClaudeDir\settings.json"
if ($hasHooks -and $hasSettings) {
    try {
        $s = Get-Content "$ClaudeDir\settings.json" -Raw | ConvertFrom-Json
        if ($s.hooks) {
            $hookEvents = ($s.hooks | Get-Member -MemberType NoteProperty).Count
            Pass "Hooks registered ($hookEvents events)"
        } else {
            Fail "Hooks exist in hooks/ but NOT registered in settings.json"
        }
    } catch {
        Fail "Cannot parse settings.json"
    }
} else {
    Pass "No hooks to register"
}
Write-Host ""

# ── 8. Audit Log Active ────────────────────────────────────

Write-Host "[8/8] Audit Log"
$auditDir = "$ClaudeDir\audit"
if (Test-Path $auditDir) {
    $todayLog = Join-Path $auditDir "$(Get-Date -Format 'yyyy-MM-dd').log"
    $recentLogs = Get-ChildItem $auditDir -Filter "*.log" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }
    if ($recentLogs) {
        Pass "Audit active (recent logs: $($recentLogs.Count))"
    } else {
        Warn "No recent audit logs — PostToolUse hook may not be running"
    }
} else {
    Warn "No audit directory — PostToolUse hook not active"
}
Write-Host ""

# ── Optional: MCP ──────────────────────────────────────────

if ($CheckMcp) {
    Write-Host "[OPT] MCP Connectivity"
    $verifyScript = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "verify-mcp.ps1"
    if (Test-Path $verifyScript) {
        & $verifyScript
    } else {
        Warn "verify-mcp.ps1 not found"
    }
}

# ── Summary ─────────────────────────────────────────────────

Write-Host "============================================"
Write-Host "  PASS : $pass"
Write-Host "  FAIL : $fail"
Write-Host "  WARN : $warn"
Write-Host "============================================"

if ($fail -eq 0 -and $warn -eq 0) {
    Write-Host "Status: HEALTHY — all checks passed"
} elseif ($fail -eq 0) {
    Write-Host "Status: WARNINGS — system is functional, review warnings"
} else {
    Write-Host "Status: FIXES NEEDED — resolve $fail failure(s)"
}
