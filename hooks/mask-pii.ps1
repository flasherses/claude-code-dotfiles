# mask-pii.ps1 — PostToolUse hook: detect and warn about PII in output
# Scans Edit/Write content for phone numbers, ID numbers, emails, bank cards.
# Exit 0 always (warns but never blocks).

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }
try { $data = $rawInput | ConvertFrom-Json } catch { exit 0 }

$toolName = $data.tool_name
if ($toolName -notin @('Edit', 'Write')) { exit 0 }

$filePath = $data.tool_input.file_path
$content = $data.tool_input.content
if (-not $content) { exit 0 }

$contentStr = $content.ToString()

# PII patterns
$patterns = @(
    @{name='China ID Card';   pattern='\b[1-9]\d{5}(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]\b'; severity='CRITICAL'},
    @{name='China Mobile';    pattern='\b1[3-9]\d{9}\b'; severity='CRITICAL'},
    @{name='Email';           pattern='\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'; severity='HIGH'},
    @{name='Bank Card';       pattern='\b\d{16,19}\b'; severity='HIGH'},
    @{name='IP Address';      pattern='\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'; severity='MEDIUM'},
    @{name='SSO Token';       pattern='ssoToken\s*[:=]\s*["\''\s]?\w{20,}'; severity='CRITICAL'}
)

$found = @()
foreach ($p in $patterns) {
    $matches = [regex]::Matches($contentStr, $p.pattern)
    if ($matches.Count -gt 0) {
        $found += [PSCustomObject]@{Name=$p.name; Count=$matches.Count; Severity=$p.severity}
    }
}

if ($found.Count -gt 0) {
    [Console]::Error.WriteLine("PII WARNING: Sensitive data detected in $filePath")
    foreach ($f in $found) {
        [Console]::Error.WriteLine("  [$($f.Severity)] $($f.Name): $($f.Count) instance(s)")
    }
    [Console]::Error.WriteLine("  Consider masking or using test data instead.")
}

exit 0
