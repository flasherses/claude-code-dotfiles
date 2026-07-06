# deny-dangerous.ps1 — PreToolUse hook: block truly dangerous shell commands
# Applies to ALL projects (user-level hook).
# Reads JSON from stdin, outputs rejection reason to stderr.
# Exit 0 = allow, Exit 2 = deny.

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }

try {
    $data = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$command = $data.tool_input.command
if (-not $command) { exit 0 }

# Patterns that must NEVER execute automatically
$dangerous = @(
    @{pattern = 'rm\s+-rf';                  reason = 'Recursive force delete - irreversible data loss'},
    @{pattern = 'rm\s+-r\s+/';               reason = 'Recursive delete from root - system destruction'},
    @{pattern = 'curl.*\|\s*(sh|bash|sudo)'; reason = 'Pipe curl to shell - remote code execution risk'},
    @{pattern = 'wget.*\|\s*(sh|bash|sudo)'; reason = 'Pipe wget to shell - remote code execution risk'},
    @{pattern = 'git\s+push\s+.*--force';    reason = 'Force push - overwrites remote history'},
    @{pattern = 'git\s+push\s+.*-f\b';       reason = 'Force push (-f) - overwrites remote history'},
    @{pattern = 'chmod\s+777';               reason = 'World-writable permissions - security risk'},
    @{pattern = 'dd\s+if=';                  reason = 'Raw disk write - irreversible data loss'},
    @{pattern = 'mkfs\.';                    reason = 'Filesystem format - destroys all data on target'}
)

foreach ($entry in $dangerous) {
    if ($command -match $entry.pattern) {
        $msg = "DENIED: $($entry.reason)`nMatched pattern: $($entry.pattern)`nCommand: $command"
        [Console]::Error.WriteLine($msg)
        exit 2
    }
}

exit 0
