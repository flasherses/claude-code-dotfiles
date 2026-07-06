# Optional Components — Templates

Templates for the 6 optional components generated in Phase 3. Only generate when the decision tree in Phase 2 says yes.

---

## Skill: add-<feature>

For projects with a clear development pattern. Examples:
- Java/MCP → `add-mcp-tool`
- Web API → `add-api-endpoint`
- React → `add-component`

```yaml
---
name: add-<feature>
description: >
  Generate a new <feature> following the project pattern.
  Use when user asks to 'add <feature>', 'create new <feature>',
  '新增<feature>', or describes a new <feature> to implement.
  Do NOT trigger for general code edits.
---

# Add <Feature>

## Goal
Generate a new <feature> following the existing project pattern.

## Pre-check
[Verify the project context — e.g., existing tools exist, build passes]

## Steps
1. Read [reference implementation file] as template
2. Confirm [required info] with user
3. Generate [new file(s)] following the template
4. Verify: [build/lint command]

## Template
[Code template with placeholders]

## Edge Cases
- [What if the feature name conflicts?]
- [What if a dependency is missing?]
```

---

## Command: /build

```markdown
# /build — Build project

Compile and package the project.

## Usage
`/build [target]`

Options: none = compile, `package` = package jar/war, `<module>` = single module

## Execution
[build command from Phase 1 detection]

## Checkpoint
Confirm build output exists: [target directory]
```

---

## Command: /run

```markdown
# /run — Start application

Start the application in development mode.

## Prerequisites
[List required env vars, services, or config]

## Execution
[run command from Phase 1 detection]

## Verification
[How to check if the app started successfully — curl endpoint, check port, etc.]

## Notes
[Dependencies that must be running: database, Redis, etc.]
```

---

## Agent: <specialist>-reviewer

For projects with framework-specific review needs.

```markdown
---
name: <specialist>-reviewer
description: >
  Review <framework> implementations for <specific checks>.
  Use when user creates or modifies <file pattern>, says 'review this <component>',
  or after using the add-<feature> skill.
tools: Read, Grep, Glob
model: sonnet
---

# <Specialist> Reviewer

You are a code reviewer specializing in <framework> <component> implementations.

## Hard Constraints
- Read-only: Read, Grep, Glob only
- Compare against reference implementations: [list reference files]

## Review Checklist
| # | Check | Severity |
|---|-------|----------|
| 1 | [Framework-specific check 1] | Critical |
| 2 | [Framework-specific check 2] | Warning |
| ... | ... | ... |

## Output Format
[Structured report template with severity levels]
```

---

## Hook: block-sensitive.ps1

For projects with sensitive operations (deploy, push, encrypted config).

```powershell
# block-sensitive.ps1 — PreToolUse hook
# Blocks: <deploy command>, git push, editing <sensitive files>
# Exit 0 = allow, Exit 2 = deny

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }
try { $data = $rawInput | ConvertFrom-Json } catch { exit 0 }

$toolName = $data.tool_name

# Block 1: Deploy
if ($toolName -eq 'Bash') {
    $command = $data.tool_input.command
    if ($command -match '<deploy command pattern>') {
        [Console]::Error.WriteLine("DENIED: <reason>")
        exit 2
    }
}

# Block 2: Git push
# Block 3: Edit sensitive files
# ... (customize per project)

exit 0
```

**Register in settings.json**:
```json
"PreToolUse": [{
  "matcher": "Bash",
  "hooks": [{"type": "command", "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"<项目根>\\.claude\\hooks\\block-sensitive.ps1"}]
}, {
  "matcher": "Edit|Write",
  "hooks": [{"type": "command", "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"<项目根>\\.claude\\hooks\\block-sensitive.ps1"}]
}]
```

---

## Hook: compile-check.ps1

For compiled languages with build tools (especially projects without tests).

```powershell
# compile-check.ps1 — PostToolUse hook
# After source file edits, run build to catch errors immediately.
# Exit 0 always (compile failure is informational, not blocking).

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }
try { $data = $rawInput | ConvertFrom-Json } catch { exit 0 }

$toolName = $data.tool_name
if ($toolName -notin @('Edit', 'Write')) { exit 0 }

$filePath = $data.tool_input.file_path
if ($filePath -notmatch '<source file extension regex>') { exit 0 }

# Determine module (if multi-module)
$module = '<default module>'
if ($filePath -match '<module-a-pattern>') { $module = '<module-a>' }

Write-Host "Compile check: $(Split-Path $filePath -Leaf) changed, compiling $module..."
$result = <build command> -pl $module -q 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  PASS: $module compiles"
} else {
    [Console]::Error.WriteLine("FAIL: Compile error in $module")
    [Console]::Error.WriteLine($result)
}
exit 0
```

**Register in settings.json**:
```json
"PostToolUse": [{
  "matcher": "Edit|Write",
  "hooks": [{"type": "command", "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"<项目根>\\.claude\\hooks\\compile-check.ps1"}]
}]
```
