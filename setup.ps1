# setup.ps1 — Claude Code 用户级工程体系一键部署脚本
# Version: 1.0.0
# 用法:
#   git clone https://github.com/flasherses/claude-code-dotfiles.git ~/.claude-config
#   cd ~/.claude-config
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$Version = "1.0.0"
$ClaudeDir = "$env:USERPROFILE\.claude"

Write-Host "=== Claude Code Dotfiles v$Version ==="

Write-Host "=== Claude Code 用户级工程体系部署 ==="

# 1. 确保 .claude 目录存在
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
}

# 2. 复制配置文件
Write-Host "`n[1/5] 复制配置文件..."
Copy-Item -Path ".\CLAUDE.md" -Destination "$ClaudeDir\CLAUDE.md" -Force
Copy-Item -Path ".\rules" -Destination "$ClaudeDir\rules" -Recurse -Force
Copy-Item -Path ".\agents" -Destination "$ClaudeDir\agents" -Recurse -Force
Copy-Item -Path ".\commands" -Destination "$ClaudeDir\commands" -Recurse -Force
Copy-Item -Path ".\hooks" -Destination "$ClaudeDir\hooks" -Recurse -Force
Write-Host "  ✅ CLAUDE.md + rules/ + agents/ + commands/ + hooks/"

# 3. 生成 settings.json（自动替换路径中的用户名）
Write-Host "`n[2/5] 生成 settings.json..."
if (Test-Path "$ClaudeDir\settings.json") {
    Write-Host "  ⚠️ settings.json 已存在，跳过（保护现有配置）"
    Write-Host "  如需更新，请手动对比 settings.example.json"
} else {
    $example = Get-Content ".\settings.example.json" -Raw
    # 替换 __CLAUDE_HOME__ 占位符为实际路径
    $claudeHome = $ClaudeDir -replace '\\', '\\'
    $example = $example -replace '__CLAUDE_HOME__', $claudeHome
    $example | Set-Content -Path "$ClaudeDir\settings.json" -Encoding utf8
    Write-Host "  ✅ settings.json 已生成（Hook 路径已自动适配: $ClaudeDir）"
    Write-Host "  ⚠️ 请手动编辑 ~/.claude/settings.json 填入你的 API Key"
}

# 4. 创建必要目录
Write-Host "`n[3/5] 创建目录结构..."
$dirs = @("$ClaudeDir\audit", "$ClaudeDir\state", "$ClaudeDir\projects")
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
}
Write-Host "  ✅ audit/ + state/ + projects/"

# 5. 安装 Skills（通过 marketplace）
Write-Host "`n[4/5] 安装 Skills..."
Write-Host "  执行: claude plugin install superpowers@claude-plugins-official"
try {
    claude plugin install superpowers@claude-plugins-official 2>$null
    Write-Host "  ✅ Superpowers Skills 安装完成"
} catch {
    Write-Host "  ⚠️ 自动安装失败，请手动在 Claude Code 中运行:"
    Write-Host "     /plugin install superpowers@claude-plugins-official"
}

Write-Host "`n[5/5] 完成！"
Write-Host "`n=== 验证 ==="
Write-Host "在新 Claude Code 对话中测试:"
Write-Host "  1. 'What are my coding preferences?' → 应引用 CLAUDE.md"
Write-Host "  2. '/review' → 应触发代码审查流程"
Write-Host "  3. '帮我审查这段代码' → 应触发 code-reviewer agent"
