# check-uncommitted.ps1 — Stop hook: 4-step quality gate
# Applies to ALL projects (user-level).
# WARNING only — never blocks stop (always exits 0).

$cwd = (Get-Location).Path

# === Gate 1: Uncommitted changes ===
Write-Host "`n=== Gate 1/4: Uncommitted Changes ==="
$gitStatus = git -C $cwd status --porcelain 2>$null
$inGit = $LASTEXITCODE -eq 0

if ($inGit -and $gitStatus) {
    $count = @($gitStatus -split "`n" | Where-Object { $_ -ne "" }).Count
    [Console]::Error.WriteLine("WARNING Gate 1: $count uncommitted file(s)")
    [Console]::Error.WriteLine($gitStatus)
} else {
    Write-Host "  PASS"
}

# === Gate 2: Test coverage check ===
Write-Host "`n=== Gate 2/4: Test Coverage ==="
$changedSrc = $false
$hasTests = $false

if ($inGit) {
    $diff = git -C $cwd diff --name-only HEAD 2>$null
    if ($diff -match 'src/|lib/|app/') { $changedSrc = $true }
    if (Test-Path "$cwd\tests") { $hasTests = $true }
    if (Test-Path "$cwd\test") { $hasTests = $true }
    if (Test-Path "$cwd\__tests__") { $hasTests = $true }
    if (Test-Path "$cwd\spec") { $hasTests = $true }
}

if ($changedSrc -and $hasTests) {
    [Console]::Error.WriteLine("WARNING Gate 2: Source changed and tests exist - consider running tests")
    [Console]::Error.WriteLine("  Tip: ask Claude to use the test-runner agent")
} else {
    Write-Host "  PASS (no tests or no source changes)"
}

# === Gate 3: Debug code residue ===
Write-Host "`n=== Gate 3/4: Debug Code ==="
$debugPatterns = @('console\.log', 'print\(', 'debugger', 'TODO.*FIXME', 'XXXXX')
$foundDebug = $false

if ($inGit) {
    $diffContent = git -C $cwd diff HEAD 2>$null
    foreach ($p in $debugPatterns) {
        if ($diffContent -match $p) {
            if (-not $foundDebug) {
                [Console]::Error.WriteLine("WARNING Gate 3: Possible debug code found:")
                $foundDebug = $true
            }
            [Console]::Error.WriteLine("  Pattern: $p")
        }
    }
}
if (-not $foundDebug) {
    Write-Host "  PASS"
}

# === Gate 4: Sensitive files check ===
Write-Host "`n=== Gate 4/4: Sensitive Files ==="
$sensitiveFiles = @('.env', '.env.local', 'credentials.json', 'secrets.yaml', '*.pem', '*.key')
$foundSensitive = $false

if ($inGit -and $gitStatus) {
    foreach ($sf in $sensitiveFiles) {
        $matches = $gitStatus | Select-String -Pattern ([regex]::Escape($sf).Replace('\*', '.*'))
        if ($matches) {
            if (-not $foundSensitive) {
                [Console]::Error.WriteLine("WARNING Gate 4: Sensitive files in changes!")
                $foundSensitive = $true
            }
            [Console]::Error.WriteLine("  File: $($matches.Line)")
        }
    }
}
if (-not $foundSensitive) {
    Write-Host "  PASS"
}

Write-Host "`n=== Quality gate check complete ==="
exit 0
