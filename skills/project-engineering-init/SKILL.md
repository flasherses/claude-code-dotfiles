---
name: project-engineering-init
description: >
  Use when user asks to 'set up Claude Code for this project', 'initialize project
  engineering', 'create project config', '搭建项目工程化', '初始化工程体系',
  '为这个项目配置 Claude', or '帮我搭建工程化体系'. Also triggers when user says
  'build engineering system for this project' or after creating a new project and
  asking Claude to set up project-level configuration. Do NOT trigger for general
  CLAUDE.md editing or single-file config tweaks.
---

# Project Engineering Init

## Quick Reference

```
1. Explore   → 读构建文件 + 入口代码 → 输出 10 项探测结果
2. Plan      → 对照决策树 → 列出生成清单 → 用户确认
3. Generate  → 逐文件生成：CLAUDE.md → .claudeignore → settings.json → rules → skills/commands/agents/hooks
4. Validate  → 文件存在 + JSON 格式 + 脚本语法 → 报告
```

**何时不用**: 只改一个配置文件、已有完整工程体系只需更新、非项目根目录。

## 目标

为任意项目生成完整的 Claude Code 项目级工程化体系。一次执行，覆盖基础层 + 执行层 + 治理层所有项目级配置。

## 适用判断

**执行前**:
```powershell
# 确认在项目根目录
Test-Path ".\pom.xml"  # 或 package.json / go.mod / Cargo.toml / requirements.txt
```

**跳过此 Skill** 如果：
- 用户只要求修改单个已有配置文件
- 项目已有完整的 `.claude/` 目录且用户只想微调
- 当前目录不是项目根目录（无构建文件）

---

## 阶段 1: Explore — 探测项目

读取以下文件收集 10 项信息：
- 构建文件 (`pom.xml` / `package.json` / `go.mod` / `Cargo.toml` / `requirements.txt`) — 取前 60 行
- 入口文件 (`*Application.java` / `main.py` / `app.js` / `index.ts` / `main.go`) — 取前 30 行
- 目录结构 — 顶层 2 层

**必须输出的 10 项**:

| # | 信息 | 来源 |
|---|------|------|
| 1 | 项目类型 | 构建文件名 |
| 2 | 语言与版本 | 构建文件中的 version 字段 |
| 3 | 框架 | 入口文件的 import/package |
| 4 | 构建工具 | 构建文件名 + scripts |
| 5 | 数据库 | 构建文件依赖 + 配置文件 |
| 6 | 多模块? | 父 POM 的 `<modules>` 或 monorepo 结构 |
| 7 | 有测试? | `src/test/` / `tests/` / `__tests__/` / `spec/` 是否存在 |
| 8 | 有敏感配置? | `.env` / `application-*.yml` / `secrets.*` / `credentials.*` |
| 9 | 入口文件 | `*Application.java` / `main.py` / `app.js` / `main.go` |
| 10 | 项目用途 | README 第一段或入口文件注释 |

**检查点**:
```
确认 10 项全部有值（非空、非"未知"）。如果有缺失，重新读取相关文件。
全部有值后，向用户展示探测结果确认。
```

---

## 阶段 2: Plan — 确定生成清单

使用下表（**逐行问自己：这个项目需要吗？**）：

```
项目有构建工具? ──── 是 → 生成 /build + /run + compile-check Hook
     │
项目有测试目录? ──── 是 → 生成 /test 命令
     │
项目有数据库/API/密钥? ──── 是 → 生成 security.md 规则 + block-sensitive Hook
     │
项目有明确开发模式? ──── 是 → 生成 add-<feature> Skill
     │                   (如 @McpTool / Controller→Service→Repo / React 组件)
项目有框架特有审查需求? ──── 是 → 生成 specialist Agent
     │
编译型语言 + 有构建工具 + 无测试? ──── 是 → 生成 compile-check Hook（强烈推荐）
```

| 文件 | 条件 | 优先级 |
|------|------|:--:|
| `CLAUDE.md` | 始终 | 必须 |
| `.claudeignore` | 始终 | 必须 |
| `.claude/settings.json` | 始终 | 必须 |
| `.claude/rules/<lang>-conventions.md` | 有代码时 | 建议 |
| `.claude/rules/security.md` | 有数据库/API/密钥时 | 建议 |
| `.claude/commands/build.md` | 有构建工具 | 建议 |
| `.claude/commands/run.md` | 有启动命令 | 建议 |
| `.claude/skills/<add-feature>/SKILL.md` | 有明确开发模式 | 可选 |
| `.claude/commands/test.md` | 有测试目录 | 可选 |
| `.claude/agents/<specialist>.md` | 有框架特有审查 | 可选 |
| `.claude/hooks/block-sensitive.ps1` | 有敏感操作 | 建议 |
| `.claude/hooks/compile-check.ps1` | 编译型+有构建 | 强烈建议 |
| `.gitignore` 补充 | 缺标准排除 | 建议 |

**展示清单给用户**，每项标注"[建议生成]"或"[可选]"，等用户确认。用户说"全部生成"则跳过确认。

**检查点**: 用户确认后进入阶段 3。

---

## 阶段 3: Generate — 逐文件生成

### 3.1 CLAUDE.md（100-300 行）

严格的六大要素结构。参照 `references/claude-md-template.md` 的完整模板。

**核心规则**:
- 每个规则回答 WHY — AI 懂了原因才能在边缘情况正确判断
- 禁区必须可操作 — 文件路径或通配符，不是模糊的"注意安全"
- 常用命令必须是可复制粘贴执行的完整命令
- 超过 300 行 → 把细则拆分到 rules/

**Few-Shot 参考**: 加载 `references/example-java-mcp.md` 看 Java/Maven 项目的完整 CLAUDE.md 样例。

### 3.2 .claudeignore

按技术栈选排除模式：

| 语言/工具 | 排除 |
|-----------|------|
| 通用（始终） | `node_modules/` `.git/` `.idea/` `.vscode/` `Thumbs.db` `.DS_Store` `*.log` |
| Java/Maven | `target/` `*.class` `*.jar` |
| Python | `__pycache__/` `*.pyc` `.venv/` `dist/` |
| Node.js | `node_modules/` `dist/` `build/` `.next/` |
| Go | `*.exe` `*.test` `vendor/` |
| Rust | `target/` |
| 敏感文件 | `.env` `.env.*` `*.pem` `*.key` `credentials.*` |
| Claude 工作 | `.claude/audit/` `.claude/state/` `.claude/sessions/` `.claude/worktrees/` |

### 3.3 .claude/settings.json

三层权限，**deny 控制在 5-8 条**：

```json
{
  "permissions": {
    "allow": [
      "Read(<项目根绝对路径>\\**)",   // ❗ 必须限定项目路径，禁用 Read(*)
      "Glob(<项目根绝对路径>\\**)",
      "Grep(<项目根绝对路径>\\**)",
      "Bash(<构建命令>*)",
      "Bash(<运行命令>*)",
      "Bash(git diff*|status*|log*|branch*)"
    ],
    "ask": [
      "Edit(<项目根绝对路径>\\**)",    // ❗ 必须限定项目路径
      "Write(<项目根绝对路径>\\**)",
      "Bash(git add*|commit*|checkout*)"
    ],
    "deny": [
      "Bash(rm -rf*)", "Bash(curl*|*sh*)",
      "Bash(git push*--force*)", "Bash(git push*-f*)",
      "PowerShell(mvn deploy*)",
      "Edit(<项目根绝对路径>\\**\\application-prod*.yml)",
      "Edit(<项目根绝对路径>\\**\\.env*)",
      "Edit(<项目根绝对路径>\\.claude\\settings.json)"
    ]
  }
}
```

**❗ 强制规则（不遵守会导致安全问题）**:
- **Read/Glob/Grep 必须限定项目路径** — `Read(D:\\path\\to\\project\\**)` 而非 `Read(*)`。`Read(*)` 让 Claude 能读系统上任何文件
- **Edit/Write 必须限定项目路径** — 同上
- **路径用绝对路径 + 正斜杠** — `D:/project/**` 格式
- **deny 中包含 `.claude/settings.json`** — 防止 AI 修改自身权限

### 3.4 .claude/rules/

**❗ 强制：每个 rule 文件必须包含 YAML frontmatter**。无 frontmatter 的 rule 会在每次对话全程加载，浪费上下文。

**编码规范** (`<lang>-conventions.md`):

```markdown
---
description: <项目名> <语言>编码规范。创建或修改 <扩展名> 文件时生效。
paths:
  - "**/*.<ext>"
---

# <语言>编码规范

## 命名约定
[表：类型 → 规范 → 示例]

## <框架>使用
[关键模式：如何创建新模块、依赖注入方式、ORM 模式]

## 日志规范
[用什么日志库、级别选择、不要怎么做]

## 异常处理
[如何处理异常、哪里处理、哪里不处理]
```

**安全规范** (`security.md`):

```markdown
---
description: <项目名>安全红线。修改代码/配置/环境变量文件时重点生效。
paths:
  - "**/*.<ext>"
  - "**/*.yml"
  - "**/*.yaml"
  - "**/*.xml"
  - "**/.env*"
---

# 项目安全红线

## 1. 凭据管理
[根据探测结果：硬编码禁止 / 加密方式 / 环境变量]

## 2. <数据库/API>安全
[SQL 注入防护 / API Key 管理 / 参数化查询]

## 3. 代码中不得出现
[具体的禁止项列表]
```

**关键规则**:
- `paths` 字段决定何时加载 — 只在匹配的文件被操作时激活
- `description` 字段说明规则用途 — AI 可据此判断是否相关
- 不要设 `paths: ["**/*"]` 全局生效 — 那和没有 frontmatter 一样浪费

### 3.5-3.7 Skills/Commands/Agents

按阶段 2 的决策树结果生成。具体模板见 `references/optional-components.md`。

### 3.8 .claude/hooks/ — 必须同时更新 settings.json

**❗ 强制：生成 Hook 脚本后，必须立即在 settings.json 中添加对应的 hooks 区块。**
缺失 hooks 注册 = Hook 脚本永远不会被执行（死代码）。

**block-sensitive.ps1**（PreToolUse — 阻断敏感操作）:

```powershell
# block-sensitive.ps1 — PreToolUse hook
# ❗ 使用 stdin JSON 读取工具调用信息，不是 git diff
# Exit 0 = allow, Exit 2 = deny

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }
try { $data = $rawInput | ConvertFrom-Json } catch { exit 0 }

$toolName = $data.tool_name

# Block deploy
if ($toolName -eq 'Bash' -and $data.tool_input.command -match '<deploy pattern>') {
    [Console]::Error.WriteLine("DENIED: <reason>")
    exit 2
}

# Block git push
if ($toolName -eq 'Bash' -and $data.tool_input.command -match 'git\s+push\b') {
    [Console]::Error.WriteLine("DENIED: git push requires manual confirmation.")
    exit 2
}

# Block editing sensitive files
if ($toolName -in @('Edit', 'Write')) {
    $fileName = Split-Path $data.tool_input.file_path -Leaf
    if ($fileName -match '<sensitive file pattern>') {
        [Console]::Error.WriteLine("DENIED: Cannot modify $fileName")
        exit 2
    }
}

exit 0
```

**compile-check.ps1**（PostToolUse — 编辑后自动编译）:

```powershell
# compile-check.ps1 — PostToolUse hook
# Exit 0 always (never blocks — compile failure is informational)

$rawInput = $input | Out-String
if (-not $rawInput) { exit 0 }
try { $data = $rawInput | ConvertFrom-Json } catch { exit 0 }

$toolName = $data.tool_name
if ($toolName -notin @('Edit', 'Write')) { exit 0 }

$filePath = $data.tool_input.file_path
if ($filePath -notmatch '\.<source-ext>$') { exit 0 }

# Determine module (if multi-module)
$module = '<default>'
if ($filePath -match '<module-pattern>') { $module = '<module>' }

$result = <build cmd> -pl $module -q 2>&1
if ($LASTEXITODE -ne 0) {
    [Console]::Error.WriteLine("FAIL: Compile error in $module after editing $(Split-Path $filePath -Leaf)")
    [Console]::Error.WriteLine($result)
}
exit 0
```

**注册到 settings.json**（❗ 此步骤不可省略）:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"<项目根>\\.claude\\hooks\\block-sensitive.ps1\""}]
    },
    {
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"<项目根>\\.claude\\hooks\\block-sensitive.ps1\""}]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"<项目根>\\.claude\\hooks\\compile-check.ps1\""}]
    }
  ]
}
```

**关键规则**:
- **必须读 stdin JSON** — Hook 接收 JSON 格式的工具调用信息
- **exit 2 = 阻断, exit 0 = 放行** — 不要用 exit 1
- **`-ExecutionPolicy Bypass` 必须加** — Windows PowerShell 5.1 默认禁止脚本
- **两个 matcher** — Bash（拦截命令）+ Edit|Write（拦截文件修改）

---

## 阶段 4: Validate — 验证

```powershell
# 1. 确认所有计划文件已创建
Get-ChildItem .claude -Recurse -File | Select-Object FullName

# 2. settings.json 格式校验
$s = Get-Content ".claude/settings.json" -Raw | ConvertFrom-Json
Write-Host "settings.json: OK ($($s.permissions.allow.Count) allow / $($s.permissions.deny.Count) deny)"

# 3. CLAUDE.md 行数检查
$lines = (Get-Content CLAUDE.md | Measure-Object -Line).Lines
if ($lines -lt 100) { Write-Host "WARNING: CLAUDE.md too short ($lines lines)" }
elseif ($lines -gt 350) { Write-Host "WARNING: CLAUDE.md too long ($lines lines), consider splitting to rules/" }
else { Write-Host "CLAUDE.md: OK ($lines lines)" }

# 4. Hook 脚本语法检查（如有）
Get-ChildItem .claude/hooks/*.ps1 | ForEach-Object {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors)
    if ($errors.Count -eq 0) { Write-Host "$($_.Name): PASS" }
    else { Write-Host "$($_.Name): FAIL — $errors" }
}

# 5. 如果有 hooks/ 目录，确认 settings.json 中已注册
$hasHooks = Test-Path ".claude/hooks/*.ps1"
$hasHookReg = $s.hooks
if ($hasHooks -and -not $hasHookReg) {
    Write-Host "FAIL: Hook scripts exist in .claude/hooks/ but are NOT registered in settings.json"
    Write-Host "  Add a 'hooks' section to .claude/settings.json"
}

# 6. .gitignore 不排除应提交的文件
$gitignore = Get-Content .gitignore -Raw
if ($gitignore -match '^CLAUDE\.md|^\.claude/' -and $gitignore -notmatch '\.claude/(audit|state|sessions|worktrees|settings\.local)') {
    Write-Host "WARNING: .gitignore may exclude shared Claude config files"
}
```

---

## 易错点

| 错误 | 后果 | 正确做法 |
|------|------|----------|
| **Read/Glob/Grep 用 `*` 通配符** | Claude 能读系统上任何文件 | `Read(D:\\path\\to\\project\\**)` 限定项目路径 |
| **Hook 生成后不在 settings.json 注册** | Hook 脚本永久不执行（死代码）| 生成 hook 脚本后立即加 hooks 区块 |
| **Rules 缺 YAML frontmatter** | 每次对话全程加载，浪费上下文 | 加 `paths:` 条件匹配只在相关文件操作时激活 |
| **Hook 用 exit 1 而非 exit 2** | 阻断失效，Hook 协议只认 exit 2 | PreToolUse 阻断用 `exit 2` |
| **Hook 用 git diff 而非 stdin JSON** | 无法在命令执行前阻断，只能事后扫描 | 读 stdin JSON 获取 tool_name + tool_input |
| CLAUDE.md 超过 400 行 | 上下文窗口争抢，高频信息被稀释 | 100-300 行，超过拆到 rules/ |
| .gitignore 加了 `.claude/` 整体 | 团队共享的 settings.json/rules/ 被排除 | 只排除 `.claude/audit/` `.claude/state/` `.claude/sessions/` `.claude/worktrees/` `.claude/settings.local.json` |
| settings.json deny 超过 10 条 | 过多拦截阻碍正常开发 | 5-8 条真正危险的 |
| allow 放行 `Bash(*)` | 等于给 Claude 完整 OS 访问权 | 只放行构建/测试/git 只读命令 |
| Hook 脚本含中文 | PowerShell 5.1 无 BOM 编码乱码→语法错误 | 纯英文 ASCII |
| 覆盖已有配置文件 | 丢失团队已建立的规则 | 先询问，展示 diff |
| 生成不需要的 agent/skill | L1 token 浪费 | 只有明确需要时才生成 |

## 参考

- 完整 CLAUDE.md 模板: `references/claude-md-template.md`
- Java/Maven 项目样例: `references/example-java-mcp.md`
- 可选组件模板: `references/optional-components.md`
