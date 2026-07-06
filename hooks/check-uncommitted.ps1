# check-uncommitted.ps1 — Stop hook: warn about uncommitted changes
# Applies to ALL projects (user-level hook).
# WARNING only — never blocks stop (always exits 0).

$cwd = (Get-Location).Path
Push-Location $cwd

$gitStatus = git status --porcelain 2>$null
$gitAvailable = $LASTEXITCODE -eq 0

Pop-Location

if (-not $gitAvailable) {
    exit 0
}

if ($gitStatus) {
    $changedFiles = @($gitStatus -split "`n" | Where-Object { $_ -ne "" }).Count
    [Console]::Error.WriteLine("WARNING: $changedFiles uncommitted file(s) in $cwd")
    [Console]::Error.WriteLine("Changed files:")
    [Console]::Error.WriteLine($gitStatus)
}

exit 0
