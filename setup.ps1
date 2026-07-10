# setup.ps1 — Claude Code 用户级工程体系一键部署脚本 v1.0.0
# 用法:
#   git clone https://github.com/flasherses/claude-code-dotfiles.git ~/.claude-config
#   cd ~/.claude-config
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$Version = "1.0.0"
$ClaudeDir = "$env:USERPROFILE\.claude"

Write-Host ""
Write-Host "============================================"
Write-Host "  Claude Code Dotfiles v$Version"
Write-Host "  User-level Engineering System Deployment"
Write-Host "============================================"
Write-Host ""

# ── Step 1: Ensure target directory ───────────────────────

Write-Host "[1/6] Preparing ~/.claude/..."
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
    Write-Host "  Created: $ClaudeDir"
} else {
    Write-Host "  Exists: $ClaudeDir"
}

# ── Step 2: Deploy config files ───────────────────────────

Write-Host ""
Write-Host "[2/6] Deploying config files..."

$items = @(
    @{Src=".\CLAUDE.md";       Dst="$ClaudeDir\CLAUDE.md";       Label="CLAUDE.md"},
    @{Src=".\rules";           Dst="$ClaudeDir\rules";           Label="rules/"},
    @{Src=".\agents";          Dst="$ClaudeDir\agents";          Label="agents/"},
    @{Src=".\commands";        Dst="$ClaudeDir\commands";        Label="commands/"},
    @{Src=".\hooks";           Dst="$ClaudeDir\hooks";           Label="hooks/"},
    @{Src=".\skills";          Dst="$ClaudeDir\skills";          Label="skills/"}
)

foreach ($item in $items) {
    if (Test-Path $item.Src) {
        Copy-Item -Path $item.Src -Destination $item.Dst -Recurse -Force
        $count = if (Test-Path $item.Src -PathType Container) {
            (Get-ChildItem $item.Src -Recurse -File).Count
        } else { 1 }
        Write-Host "  OK  $($item.Label) ($count files)"
    } else {
        Write-Host "  SKIP $($item.Label) (not found)"
    }
}

# ── Step 3: Generate settings.json ────────────────────────

Write-Host ""
Write-Host "[3/6] Generating settings.json..."

if (Test-Path "$ClaudeDir\settings.json") {
    Write-Host "  SKIP settings.json already exists (protecting existing config)"
    Write-Host "  To update: compare with .\settings.example.json manually"
} else {
    $example = Get-Content ".\settings.example.json" -Raw
    $claudeHome = $ClaudeDir -replace '\\', '\\'
    $example = $example -replace '__CLAUDE_HOME__', $claudeHome
    $example | Set-Content -Path "$ClaudeDir\settings.json" -Encoding utf8
    Write-Host "  OK  settings.json generated (paths adapted to: $ClaudeDir)"
}

# ── Step 4: Create runtime directories ────────────────────

Write-Host ""
Write-Host "[4/6] Creating runtime directories..."
$dirs = @("$ClaudeDir\audit", "$ClaudeDir\state", "$ClaudeDir\projects")
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
}
Write-Host "  OK  audit/ + state/ + projects/"

# ── Step 5: Install marketplace skills (optional) ──────────

Write-Host ""
Write-Host "[5/6] Installing Superpowers skills (optional)..."
try {
    $claudeExists = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeExists) {
        claude plugin install superpowers@claude-plugins-official 2>$null
        Write-Host "  OK  Superpowers skills installed"
    } else {
        Write-Host "  SKIP Claude Code CLI not found — install manually later:"
        Write-Host "       /plugin install superpowers@claude-plugins-official"
    }
} catch {
    Write-Host "  SKIP Automatic install failed. Install manually in Claude Code:"
    Write-Host "       /plugin install superpowers@claude-plugins-official"
}

# ── Step 6: Verify deployment ──────────────────────────────

Write-Host ""
Write-Host "[6/6] Verifying deployment..."

$checks = @{
    "CLAUDE.md"         = (Test-Path "$ClaudeDir\CLAUDE.md")
    "rules/"            = (Test-Path "$ClaudeDir\rules")
    "agents/"           = (Test-Path "$ClaudeDir\agents")
    "commands/"         = (Test-Path "$ClaudeDir\commands")
    "hooks/"            = (Test-Path "$ClaudeDir\hooks")
    "skills/"           = (Test-Path "$ClaudeDir\skills")
    "settings.json"     = (Test-Path "$ClaudeDir\settings.json")
    "audit/"            = (Test-Path "$ClaudeDir\audit")
}
$allOk = $true
foreach ($check in $checks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "  OK  $($check.Key)"
    } else {
        Write-Host "  MISS  $($check.Key)"
        $allOk = $false
    }
}

# ── Done ───────────────────────────────────────────────────

Write-Host ""
Write-Host "============================================"
if ($allOk) {
    Write-Host "  Deployment complete!"
} else {
    Write-Host "  Deployment complete (some items skipped)."
}
Write-Host "============================================"
Write-Host ""
Write-Host "What you have now:"
Write-Host "  5 Agents    — code-reviewer, security-auditor, doc-explorer, test-runner, pr-drafter"
Write-Host "  10 Hooks    — 5 event types, dual platform (ps1+sh)"
Write-Host "  6 Skills    — project-engineering-init, git-rollback, smart-review + 3 team skills"
Write-Host "  4 Commands  — /review, /audit, /full-review, /rollback"
Write-Host "  2 Rules     — security.md, code-style.md"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Start a new Claude Code session"
Write-Host "  2. Verify: ask 'What are my coding preferences?'"
Write-Host "  3. In any project: say 'build the engineering system for this project'"
Write-Host "  4. Run health check: cd ~/.claude-config && powershell -File scripts/health-check.ps1"
Write-Host ""
