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
    "allow": [读文件 + 构建命令 + 运行命令 + git 只读],
    "ask":  [Edit/Write 所有源码 + git add/commit/checkout],
    "deny": [rm -rf, curl|sh, git push -f, mvn deploy, 编辑敏感配置]
  }
}
```

### 3.4 .claude/rules/

**编码规范** (`<lang>-conventions.md`): 命名约定 → 框架模式 → 文件组织 → 日志 → 异常处理。每个规则解释 WHY。

**安全规范** (`security.md`): 凭据管理 → 注入防护 → 审计日志 → 禁止项清单。

### 3.5-3.8 可选组件

按阶段 2 的决策树结果生成。具体模板见 `references/optional-components.md`。

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

# 5. .gitignore 不排除应提交的文件
$gitignore = Get-Content .gitignore -Raw
if ($gitignore -match '^CLAUDE\.md|^\.claude/' -and $gitignore -notmatch '\.claude/(audit|state|sessions|worktrees|settings\.local)') {
    Write-Host "WARNING: .gitignore may exclude shared Claude config files"
}
```

---

## 易错点

| 错误 | 后果 | 正确做法 |
|------|------|----------|
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
