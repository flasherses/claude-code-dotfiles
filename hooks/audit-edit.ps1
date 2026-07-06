# audit-edit.ps1 — PostToolUse hook: log every Edit/Write to audit trail
# Applies to ALL projects (user-level hook).
# Reads JSON from stdin. Exit 0 always (never blocks).

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }

try {
    $data = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$tool = $data.tool_name
if ($tool -notin @('Edit', 'Write')) { exit 0 }

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$filePath = $data.tool_input.file_path
$cwd = $data.cwd

$auditDir = Join-Path $env:USERPROFILE '.claude\audit'
if (-not (Test-Path $auditDir)) {
    New-Item -ItemType Directory -Force -Path $auditDir | Out-Null
}

$logFile = Join-Path $auditDir "$(Get-Date -Format 'yyyy-MM-dd').log"
$entry = "[$timestamp] Tool=$tool | File=$filePath | CWD=$cwd"

Add-Content -Path $logFile -Value $entry -Encoding utf8

exit 0
