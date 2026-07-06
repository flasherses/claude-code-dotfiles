# check-conflicts.ps1 — Claude Code Config Conflict Detector (Windows)
# Scans 3 layers (user + project + local) for permission and rule conflicts.
# Usage: powershell -File scripts/check-conflicts.ps1 [project-path]

param([string]$ProjectPath = (Get-Location).Path)

$UserDir = "$env:USERPROFILE\.claude"
$errors = 0
$warnings = 0

Write-Host "=== Claude Code Config Conflict Detector ==="
Write-Host "User dir : $UserDir"
Write-Host "Project  : $ProjectPath"
Write-Host ""

# ── 1. Load Configs ───────────────────────────────────────

function Load-Permissions($path) {
    if (-not (Test-Path $path)) { return $null }
    try {
        $json = Get-Content $path -Raw | ConvertFrom-Json
        return $json.permissions
    } catch { return $null }
}

$userPerms = Load-Permissions "$UserDir\settings.json"
$projPerms = Load-Permissions "$ProjectPath\.claude\settings.json"
$localPerms = Load-Permissions "$ProjectPath\.claude\settings.local.json"

if (-not $userPerms) { Write-Host "WARNING: No user settings.json found" }
if (-not $projPerms) { Write-Host "WARNING: No project .claude/settings.json found" }

# ── 2. Check Overly Broad Rules ────────────────────────────

Write-Host "=== 1. Overly Broad Rules ==="
$allSources = @{
    "user/settings.json" = $userPerms
    "project/settings.json" = $projPerms
    "project/settings.local.json" = $localPerms
}

foreach ($src in $allSources.Keys) {
    $perms = $allSources[$src]
    if (-not $perms) { continue }
    foreach ($level in @("allow","ask","deny")) {
        $rules = $perms.$level
        if (-not $rules) { continue }
        foreach ($rule in $rules) {
            if ($rule -match '^Read\(\*\)$|^Glob\(\*\)$|^Grep\(\*\)$') {
                Write-Host "  FAIL [$src] $rule — unrestricted file access"
                $errors++
            }
            if ($rule -match '^Edit\(\*\)$|^Write\(\*\)$') {
                Write-Host "  FAIL [$src] $rule — unrestricted file write"
                $errors++
            }
            if ($rule -match '^Bash\(\*\)$') {
                Write-Host "  FAIL [$src] $rule — full OS access"
                $errors++
            }
        }
    }
}
if ($errors -eq 0) { Write-Host "  PASS: No overly broad rules" }
Write-Host ""

# ── 3. Cross-Level Conflicts ───────────────────────────────

Write-Host "=== 2. Cross-Level Conflicts ==="
$crossConflicts = 0

# Check: project deny conflicting with user allow
if ($projPerms -and $userPerms) {
    $projDeny = $projPerms.deny
    $userAllow = $userPerms.allow
    if ($projDeny -and $userAllow) {
        foreach ($d in $projDeny) {
            $dBase = $d -replace '\*+$',''
            foreach ($a in $userAllow) {
                $aBase = $a -replace '\*+$',''
                if ($dBase -and $aBase -and ($dBase -like "$aBase*" -or $aBase -like "$dBase*")) {
                    Write-Host "  CONFLICT: deny[$d] (project) vs allow[$a] (user) — deny wins"
                    $crossConflicts++
                }
            }
        }
    }
}

# Check: user deny conflicting with project allow
if ($projPerms -and $userPerms) {
    $userDeny = $userPerms.deny
    $projAllow = $projPerms.allow
    if ($userDeny -and $projAllow) {
        foreach ($d in $userDeny) {
            foreach ($a in $projAllow) {
                if ($d -eq $a) {
                    Write-Host "  CONFLICT: deny[$d] (user) vs allow[$a] (project) — deny wins"
                    $crossConflicts++
                }
            }
        }
    }
}

if ($crossConflicts -eq 0) { Write-Host "  PASS: No cross-level conflicts" }
Write-Host ""

# ── 4. Rule Redundancy ─────────────────────────────────────

Write-Host "=== 3. Rule Redundancy ==="
$redundant = 0

# Detect: same rule in user + project at same level
foreach ($level in @("allow","ask","deny")) {
    $userRules = @(if ($userPerms.$level) { $userPerms.$level } else { @() })
    $projRules = @(if ($projPerms.$level) { $projPerms.$level } else { @() })
    $localRules = @(if ($localPerms.$level) { $localPerms.$level } else { @() })

    foreach ($r in $userRules) {
        if ($r -in $projRules) {
            Write-Host "  REDUNDANT: $level[$r] in both user and project — project overrides user"
            $redundant++
        }
        if ($r -in $localRules) {
            Write-Host "  REDUNDANT: $level[$r] in both user and local"
            $redundant++
        }
    }
    foreach ($r in $projRules) {
        if ($r -in $localRules) {
            Write-Host "  REDUNDANT: $level[$r] in both project and local — local overrides project"
            $redundant++
        }
    }
}
if ($redundant -eq 0) { Write-Host "  PASS: No redundant rules" }
Write-Host ""

# ── 5. Rule Count Audit ────────────────────────────────────

Write-Host "=== 4. Rule Count ==="
$totalDeny = 0
if ($userPerms.deny) { $totalDeny += $userPerms.deny.Count }
if ($projPerms.deny) { $totalDeny += $projPerms.deny.Count }
if ($localPerms.deny) { $totalDeny += $localPerms.deny.Count }

Write-Host "  User allow: $($userPerms.allow.Count), ask: $($userPerms.ask.Count), deny: $($userPerms.deny.Count)"
if ($projPerms) { Write-Host "  Project allow: $($projPerms.allow.Count), ask: $($projPerms.ask.Count), deny: $($projPerms.deny.Count)" }
if ($localPerms) { Write-Host "  Local allow: $($localPerms.allow.Count), ask: $($localPerms.ask.Count), deny: $($localPerms.deny.Count)" }

if ($totalDeny -gt 15) {
    Write-Host "  WARNING: Total deny rules ($totalDeny) > 15 — consider consolidating"
    $warnings++
}
Write-Host ""

# ── 6. Missing Config ──────────────────────────────────────

Write-Host "=== 5. Missing Config ==="
if (-not (Test-Path "$ProjectPath\CLAUDE.md")) {
    Write-Host "  WARNING: No project CLAUDE.md — Claude has no project context"
    $warnings++
}
if (-not (Test-Path "$ProjectPath\.claudeignore")) {
    Write-Host "  INFO: No .claudeignore — all project files visible to Claude"
}
Write-Host ""

# ── Summary ─────────────────────────────────────────────────

Write-Host "=== Result ==="
Write-Host "  Errors  : $errors"
Write-Host "  Warnings: $warnings"
if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "  Status  : CLEAN — no issues found"
} elseif ($errors -eq 0) {
    Write-Host "  Status  : WARNINGS ONLY — safe to proceed"
} else {
    Write-Host "  Status  : FIX REQUIRED — resolve errors before continuing"
}
