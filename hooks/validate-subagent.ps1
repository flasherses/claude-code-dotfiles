# validate-subagent.ps1 — SubagentStop hook: validate sub-agent output format
# Reads sub-agent result from stdin JSON.
# Exit 0 = pass, Exit 2 = fail (forces sub-agent to retry)

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }

try {
    $data = $rawInput | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine("SubagentStop: Failed to parse stdin JSON")
    exit 0
}

$agentName = $data.agent_name
$result = $data.result

if (-not $result) {
    [Console]::Error.WriteLine("SubagentStop [$agentName]: Empty output")
    exit 2
}

$resultStr = $result.ToString()
$resultLen = $resultStr.Length

# === Universal checks (all agents) ===

# 1. Minimum output length
if ($resultLen -lt 50) {
    [Console]::Error.WriteLine("SubagentStop [$agentName]: Output too short ($resultLen chars)")
    exit 2
}

# 2. Must have Markdown heading
$hasHeading = $resultStr -match '^#{1,3}\s+\w+'
if (-not $hasHeading) {
    [Console]::Error.WriteLine("SubagentStop [$agentName]: Missing Markdown heading")
    exit 2
}

# 3. Must have substantive content
$hasContent = $resultStr -match '\w{30,}'
if (-not $hasContent) {
    [Console]::Error.WriteLine("SubagentStop [$agentName]: Missing substantive content")
    exit 2
}

# === Agent-specific validation ===

switch ($agentName) {
    'code-reviewer' {
        if ($resultStr -notmatch 'Code Review|Critical|Warning|Suggestion') {
            [Console]::Error.WriteLine("SubagentStop [code-reviewer]: Missing standard report structure")
            [Console]::Error.WriteLine("  Expected: ## Code Review Report -> Critical -> Warnings -> Suggestions")
            exit 2
        }
    }
    'security-auditor' {
        if ($resultStr -notmatch 'CWE-\d+|OWASP|SQL.*Injection|XSS|Security Audit') {
            [Console]::Error.WriteLine("SubagentStop [security-auditor]: Missing security classification (CWE/OWASP)")
            [Console]::Error.WriteLine("  Expected: ## Security Audit Report -> CRITICAL -> HIGH -> MEDIUM -> INFO")
            exit 2
        }
    }
    'doc-explorer' {
        if ($resultStr -notmatch '`[^`]+\.[a-z]+`|File:|\.py|\.ts|\.js|\.html') {
            [Console]::Error.WriteLine("SubagentStop [doc-explorer]: Missing file path references")
            [Console]::Error.WriteLine("  Expected: Exploration Report -> Search Results -> Key Files")
            exit 2
        }
    }
    'test-runner' {
        if ($resultStr -notmatch 'Test Results|PASS|FAIL|Total:|Passed:|Failed:') {
            [Console]::Error.WriteLine("SubagentStop [test-runner]: Missing test result summary")
            [Console]::Error.WriteLine("  Expected: ## Test Results -> Summary (Total/Passed/Failed) -> Failed Tests")
            exit 2
        }
    }
}

Write-Host "SubagentStop [$agentName]: Output validation PASSED ($resultLen chars)"
exit 0
