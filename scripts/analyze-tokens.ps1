# analyze-tokens.ps1 — Claude Code Token Usage Analyzer
# Analyzes session transcripts to identify token waste and optimization opportunities.
# Usage: powershell -File scripts/analyze-tokens.ps1

param(
    [string]$SessionDir = "$env:USERPROFILE\.claude\sessions",
    [int]$TopN = 10
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Claude Code Token Analyzer ==="
Write-Host ""

# 1. Scan session directory
if (-not (Test-Path $SessionDir)) {
    Write-Host "ERROR: Session directory not found: $SessionDir"
    Write-Host "Check your Claude Code installation path."
    exit 1
}

$sessionFiles = Get-ChildItem $SessionDir -Recurse -Filter "*.jsonl" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

if (-not $sessionFiles) {
    Write-Host "No session transcript files found in $SessionDir"
    Write-Host "This may be because transcripts are stored elsewhere or session persistence is disabled."
    exit 0
}

Write-Host "Found $($sessionFiles.Count) session files"
Write-Host ""

# 2. Analyze most recent sessions
$sessions = @()
$totalTokens = 0
$totalTurns = 0

foreach ($file in $sessionFiles | Select-Object -First $TopN) {
    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
    $lineCount = $lines.Count
    $fileSize = (Get-Item $file.FullName).Length

    # Rough token estimation: ~4 chars per token for English, ~2 for Chinese
    $content = $lines -join "`n"
    $charCount = $content.Length
    $estimatedTokens = [math]::Round($charCount / 3.5)  # Mixed Chinese/English

    $sessions += [PSCustomObject]@{
        Name = $file.Name
        Date = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Size = [math]::Round($fileSize / 1KB, 1)
        Lines = $lineCount
        EstTokens = $estimatedTokens
    }

    $totalTokens += $estimatedTokens
    $totalTurns += $lineCount
}

# 3. Display session summary
Write-Host "=== Recent Sessions ==="
$sessions | Format-Table Name, Date, @{N='Size(KB)';E={$_.Size}}, Lines, @{N='Est.Tokens';E={$_.EstTokens}} -AutoSize
Write-Host ""

# 4. Analyze CLAUDE.md and rules impact
Write-Host "=== Config Token Footprint ==="

$configDir = "$env:USERPROFILE\.claude"
$configTokens = 0

# CLAUDE.md
if (Test-Path "$configDir\CLAUDE.md") {
    $content = Get-Content "$configDir\CLAUDE.md" -Raw
    $tokens = [math]::Round($content.Length / 3.5)
    $lines = (Get-Content "$configDir\CLAUDE.md").Count
    Write-Host "  CLAUDE.md: $lines lines, ~$tokens tokens (loaded every session)"
    $configTokens += $tokens
}

# Rules
$rulesDir = "$configDir\rules"
if (Test-Path $rulesDir) {
    $ruleCount = 0
    foreach ($rule in Get-ChildItem $rulesDir -Filter "*.md") {
        $content = Get-Content $rule.FullName -Raw
        $tokens = [math]::Round($content.Length / 3.5)
        $hasFM = $content -match '^---'
        $fmTag = if ($hasFM) { "[conditional]" } else { "[ALWAYS LOADED]" }
        Write-Host "  rules/$($rule.Name): ~$tokens tokens $fmTag"
        if (-not $hasFM) { $configTokens += $tokens }  # Only always-loaded rules count
        $ruleCount++
    }
    Write-Host "  Rules count: $ruleCount"
}

# Skills (L1 description only)
$skillsDir = "$configDir\skills"
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -Directory).Count
    Write-Host "  Skills L1 overhead: ~$($skillCount * 100) tokens ($skillCount skills x ~100 tokens each)"
    $configTokens += $skillCount * 100
}

# Agents
$agentsDir = "$configDir\agents"
if (Test-Path $agentsDir) {
    $agentCount = (Get-ChildItem $agentsDir -Filter "*.md").Count
    Write-Host "  Agents: $agentCount (loaded on-demand, near-zero base cost)"
}

Write-Host "  Estimated per-session config overhead: ~$configTokens tokens"
Write-Host ""

# 5. Optimization recommendations
Write-Host "=== Optimization Recommendations ==="
Write-Host ""

$recs = @()

# Check CLAUDE.md length
$claudeLines = (Get-Content "$configDir\CLAUDE.md").Count
if ($claudeLines -gt 300) {
    $recs += "CLAUDE.md is $claudeLines lines. Consider splitting into rules/ with paths: frontmatter."
} elseif ($claudeLines -gt 150) {
    $recs += "CLAUDE.md is $claudeLines lines — acceptable but review for unused content."
}

# Check for rules without frontmatter
$rulesWithoutFM = @()
foreach ($rule in Get-ChildItem $rulesDir -Filter "*.md") {
    $content = Get-Content $rule.FullName -Raw
    if ($content -notmatch '^---') {
        $rulesWithoutFM += $rule.Name
    }
}
if ($rulesWithoutFM.Count -gt 0) {
    $recs += "Rules without frontmatter (always loaded): $($rulesWithoutFM -join ', '). Add YAML frontmatter with paths: to load conditionally."
}

# Check skill count
$skillCount = (Get-ChildItem $skillsDir -Directory).Count
if ($skillCount -gt 20) {
    $recs += "You have $skillCount skills. Each adds ~100 tokens to L1 overhead. Review which are unused."
} elseif ($skillCount -gt 12) {
    $recs += "You have $skillCount skills — reasonable. Periodically audit for unused ones."
}

# Check for overlong sessions
$longSessions = $sessions | Where-Object { $_.EstTokens -gt 100000 }
if ($longSessions) {
    $recs += "$($longSessions.Count) recent sessions exceed 100K estimated tokens. Long sessions increase cost and reduce quality. Use /compact or start fresh sessions for unrelated tasks."
}

# Model tiering check
$settingsPath = "$configDir\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $haiku = $settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL
    $sonnet = $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL
    $opus = $settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL
    if ($sonnet -eq $opus) {
        $recs += "SONNET and OPUS map to the same model. Agent model selection between sonnet/opus has no cost difference."
    }
}

if ($recs.Count -eq 0) {
    Write-Host "  No issues found. Your configuration is well-optimized."
} else {
    $recs | ForEach-Object { Write-Host "  $_" }
}

Write-Host ""
Write-Host "=== Analysis Complete ==="
