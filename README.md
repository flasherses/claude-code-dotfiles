# Claude Code Dotfiles

Claude Code 用户级工程化配置体系——**48 个文件，5 个 Agent，10 个 Hook，6 个 Skill，4 个 Command，覆盖课程 33 讲全部可工程化内容。**

支持 Windows (PowerShell) + macOS/Linux (Bash)，兼容 Anthropic API 和 DeepSeek 代理。同时是标准 Claude Code Plugin。

[![Validate](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/validate.yml)
[![CI](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/claude-review.yml/badge.svg)](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/claude-review.yml)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 为什么要工程化

**AI 不会取代程序员，但会取代不会用 AI 的程序员。工程化才是 LLM 落地的瓶颈，不是模型本身。**

没有工程体系的 Claude Code 像一个没有代码规范、没有 CI/CD、没有权限控制的开发团队——短期能跑，长期必然失控。

| 无工程体系 | 有工程体系 |
|------------|------------|
| Claude 不了解项目，每次对话从零开始 | CLAUDE.md 提供项目记忆，跨会话一致 |
| AI 可能执行 `rm -rf` 或 `git push --force` | 6 层纵深防御 + 9 条 deny + 3 层 Hook 拦截 |
| 代码风格因人而异，每次 AI 输出不一致 | Rules 约束编码规范，输出风格统一 |
| 重复性任务每次都口头描述 | Skills 沉淀可复用能力，一句话触发 |
| 输出质量不可控 | SubagentStop Hook 验收格式 + PII Hook 检测敏感数据 |
| 无法迁移到其他电脑 | `git clone` + `setup.ps1` 两分钟部署 |
| 无法扩展外部能力 | MCP 协议连接 GitHub/数据库/文件系统 |
| Token 成本不可见 | Token 分析脚本 + 调优剧本，预期降本 40-50% |
| 项目配置每次手动创建 | `project-engineering-init` Skill 自动探测+生成 |
| 无法在 CI 中运行 | Headless 模式 + GitHub Actions workflow |

**工程化的本质是把"人的判断"固化为"系统的规则"**——人负责架构/边界/意图，AI 负责执行/知识/不知疲倦。

---

## 快速开始

```powershell
# 1. 克隆仓库
git clone https://github.com/flasherses/claude-code-dotfiles.git ~/.claude-config

# 2. 一键部署
cd ~/.claude-config
powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1

# 3. 填入 API Key
notepad ~/.claude/settings.json

# 4. (可选) 安装 Superpowers Skills
claude plugin install superpowers@claude-plugins-official
```

---

## 架构

```
┌──────────────────────────────────────────────────────────────┐
│                          基础层                                │
│  CLAUDE.md + Rules (security + code-style)                    │
│  settings.json (8 allow + 9 deny + 4 Hook 事件)               │
├──────────────────────────────────────────────────────────────┤
│                          执行层                                │
│  5 Agents (3 只读 + 1 可执行 + 1 可写)                        │
│  6 Skills (3 手写 + 3 team)  +  4 Commands                    │
├──────────────────────────────────────────────────────────────┤
│                          治理层                                │
│  10 Hooks (5 ps1 + 5 sh) — PreToolUse / PostToolUse /         │
│  Stop / SubagentStop — 拦截 + 审计 + 质量门 + 验收 + PII      │
│  MCP 模板 (GitHub / Filesystem / SQLite) + 实战指南            │
├──────────────────────────────────────────────────────────────┤
│                          运行层                                │
│  Plugin 打包  +  setup.ps1  +  CI/CD workflows                │
│  Token 分析  +  调优剧本  +  Agent SDK 示例                    │
└──────────────────────────────────────────────────────────────┘
```

---

## 目录结构

```
claude-code-dotfiles/
├── README.md                              # 本文件
├── LICENSE                                # MIT
├── VERSION                                # 1.0.0
├── .gitattributes                         # 跨平台换行统一
├── .gitignore
├── setup.ps1                              # 一键部署
├── CLAUDE.md                              # 用户级记忆
├── settings.example.json                  # 配置模板（不含 token）
│
├── .claude-plugin/
│   └── plugin.json                        # Plugin manifest
│
├── .github/workflows/
│   ├── validate.yml                       # CI: JSON/PS1/SH/YAML 自动校验
│   └── claude-review.yml                  # CI: PR 自动审查 (quick/full/security)
│
├── agents/                                # 5 个 SubAgent
│   ├── code-reviewer.md                   # 只读 — 代码审查 (sonnet)
│   ├── security-auditor.md                # 只读 — 安全审计 (sonnet)
│   ├── doc-explorer.md                    # 只读 — 代码探索 (haiku)
│   ├── test-runner.md                     # 可执行 — 测试运行 (haiku)
│   └── pr-drafter.md                      # 可写 — PR 草稿 (sonnet)
│
├── hooks/                                 # 10 个 Hook (5 ps1 + 5 sh)
│   ├── deny-dangerous.{ps1,sh}            # PreToolUse — 拦截 9 条危险命令
│   ├── audit-edit.{ps1,sh}                # PostToolUse — 审计日志
│   ├── mask-pii.{ps1,sh}                  # PostToolUse — PII 检测 (6 类)
│   ├── check-uncommitted.{ps1,sh}         # Stop — 四步质量门
│   └── validate-subagent.{ps1,sh}         # SubagentStop — 输出验收
│
├── commands/                              # 4 个命令
│   ├── review.md                          # /review — 顺序审查
│   ├── audit.md                           # /audit — 纯安全审计
│   ├── full-review.md                     # /full-review — 并行全量审查
│   └── rollback.md                        # /rollback — 回滚 commit
│
├── skills/                                # 6 个 Skill (3 手写 + 3 team)
│   ├── project-engineering-init/           # 手写 — 项目工程化自动生成
│   │   ├── SKILL.md                       #   四阶段 Pipeline
│   │   ├── trigger_eval.json              #   20 个触发评估用例
│   │   └── references/                    #   L3 按需加载 (3 refs)
│   ├── git-rollback/                      # 手写 — 安全回滚 (双锁)
│   │   └── SKILL.md
│   ├── smart-review/                      # 手写 — 注入模式示例
│   │   └── SKILL.md
│   ├── add-rest-endpoint/                 # Team — REST 接口生成
│   ├── add-mcp-tool/                      # Team — MCP 工具生成
│   └── add-sso-controller/                # Team — SSO 控制器生成
│
├── rules/                                 # 2 个规则
│   ├── security.md                        # 通用安全红线
│   └── code-style.md                      # 通用编码规范
│
├── mcp/                                   # MCP 模板 + 指南
│   ├── README.md
│   ├── GUIDE.md                           # 三步配置 + 排错
│   ├── github.json                        # GitHub MCP 配置
│   ├── filesystem.json                    # Filesystem MCP 配置
│   └── sqlite.json                        # SQLite MCP 配置
│
├── scripts/                               # 工具脚本 (8 个)
│   ├── health-check.{ps1,sh}              # 一键健康检查 (8 步)
│   ├── check-conflicts.{ps1,sh}           # 配置冲突检测 (5 类)
│   ├── verify-mcp.{ps1,sh}                # MCP 连通性验证
│   ├── analyze-tokens.{ps1,sh}            # Token 分析器
│   └── agent-sdk-hello.py                 # Agent SDK 并行 + MCP Server
│
└── docs/
    └── PERFORMANCE-TUNING.md              # 6 维调优剧本
```

---

## 使用指南

### 项目工程化搭建

在任意项目根目录，一句话自动生成全套工程配置：

> "帮我搭建这个项目的工程化体系"

触发 `project-engineering-init` Skill：探测技术栈 → 生成 CLAUDE.md + rules + settings + hooks + commands + agents + skills → 6 项自动验证。

已支持：Java/Maven、Python、Node.js、Go、Rust、静态网站。

### Agent 矩阵

| Agent | 类型 | Tools | Model | 触发词 |
|-------|:--:|-------|:--:|--------|
| code-reviewer | 只读 | Read, Grep, Glob | sonnet | "review"、"审查" |
| security-auditor | 只读 | Read, Grep, Glob | sonnet | "audit"、"安全审计" |
| doc-explorer | 只读 | Grep, Glob, Read | haiku | "explain"、"探索项目" |
| test-runner | 可执行 | Read, Grep, Glob, Bash | haiku | "run tests"、"跑测试" |
| pr-drafter | **可写** | Read, Grep, Glob, Edit, Bash | sonnet | "create a PR"、"提交 PR" |

> pr-drafter 的写权限限制在 `.claude/drafts/`，不直接 commit/push。

### Hook 事件矩阵

| 事件 | 脚本 | 行为 |
|------|------|------|
| Bash 执行前 | `deny-dangerous` | 拦截 9 条危险命令 (exit 2) |
| Edit/Write 后 | `audit-edit` | 审计日志 → `~/.claude/audit/` |
| Edit/Write 后 | `mask-pii` | PII 检测：身份证/手机号/邮箱/银行卡/Token |
| 会话停止前 | `check-uncommitted` | 四步质量门（warn） |
| 子代理完成后 | `validate-subagent` | 格式验收 (exit 2 重试) |

### Skills

| Skill | 来源 | 类型 | 用途 |
|-------|:--:|:--:|------|
| **project-engineering-init** | 手写 | Pipeline | 任意项目自动生成全套工程配置 |
| **git-rollback** | 手写 | 双锁 | 安全回滚 commit（仅手动触发） |
| **smart-review** | 手写 | 注入 | 智能审查：按文件类型分派 Agent |
| add-rest-endpoint | Team | Generator | Controller→Service→Mapper |
| add-mcp-tool | Team | Generator | @McpTool + Service + DTO |
| add-sso-controller | Team | Generator | SSO 集成控制器 |
| +12 Superpowers Skills | Marketplace | — | 初始化/探索/调试/TDD/浏览器... |

### Commands

| 命令 | 模式 | 流程 |
|------|:--:|------|
| `/review` | 顺序 | reviewer → auditor |
| `/audit` | 单一 | security-auditor |
| `/full-review` | 并行 | reviewer + auditor + explorer 同时跑 |
| `/rollback` | 双锁 | git-rollback Skill → `--mixed`/`--soft`/`--hard` |

---

## 安全模型（6 层纵深防御）

```
Layer 1: settings.json deny (9 条)    — 权限级：根本不让用
Layer 2: rules/security.md            — 软规范：告诉为什么
Layer 3: PreToolUse Hook              — 事件拦截：9 条正则实时阻断
Layer 4: PostToolUse Hook ×2          — 审计日志 + PII 检测
Layer 5: SubAgent 工具白名单          — 角色隔离：默认只读
Layer 6: Stop Hook                    — 退出保护：四步质量门
```

---

## 运维工具

### 一键健康检查

```powershell
# 基础检查（8 步：JSON/PS1/SH/frontmatter/agents/hooks/audit）
powershell -File scripts/health-check.ps1

# 含 MCP 连通性
powershell -File scripts/health-check.ps1 --mcp
```

输出 PASS/FAIL/WARN 三级，最终 HEALTHY / WARNINGS / FIXES NEEDED 结论。

### 配置冲突检测

```powershell
powershell -File scripts/check-conflicts.ps1 [项目路径]
```

扫描用户级 + 项目级 + 本地级三层配置的 5 类问题：过宽通配符（`Read(*)`）、跨层冲突（deny vs allow）、规则冗余、deny 过多、缺失配置。

### MCP 连通性验证

```powershell
powershell -File scripts/verify-mcp.ps1
```

测试 GitHub / Filesystem / SQLite 三种 MCP Server 可达性，含 DeepSeek 代理兼容性诊断。

### Token 分析 + 调优

```powershell
powershell -File scripts/analyze-tokens.ps1
```

诊断 CLAUDE.md 长度、rules frontmatter 缺失、Skills 闲置、会话过长等。配合 `docs/PERFORMANCE-TUNING.md` 6 维优化剧本，预期降本 40-50%。

### Headless CI

`.github/workflows/claude-review.yml` — PR 自动审查，3 种模式：

| 模式 | 触发 | 流程 |
|------|------|------|
| quick | 每次 PR | Claude 审查变更文件 → 自动评论 PR |
| full | 手动 `/full` | 全面审查 → 自动评论 PR |
| security | 手动 `/security` | 纯安全审计 → 自动评论 PR |

### Agent SDK

```bash
pip install claude-code-sdk
python scripts/agent-sdk-hello.py D:/path/to/project
```

并行调 code-reviewer + security-auditor，演示 `create_sdk_mcp_server` 打包自定义工具为进程内 MCP Server，输出 cost/duration/turns。

---

## 安装方式

### 方式 1: setup.ps1（推荐）

```powershell
git clone https://github.com/flasherses/claude-code-dotfiles.git ~/.claude-config
cd ~/.claude-config
powershell -File setup.ps1
```

### 方式 2: Plugin

```powershell
claude plugin install github:flasherses/claude-code-dotfiles
```

---

## 维护

```powershell
# 更新配置
cd ~/.claude-config && git pull && powershell -File setup.ps1

# Token 诊断
powershell -File scripts/analyze-tokens.ps1

# 审计日志
cat ~/.claude/audit/$(Get-Date -Format 'yyyy-MM-dd').log
```

## 平台兼容

| 平台 | Shell | Hook 脚本 | 状态 |
|------|-------|-----------|:--:|
| Windows 11 | PowerShell 5.1 | `.ps1` | ✅ |
| macOS | Bash/Zsh | `.sh` | ✅ |
| Linux | Bash | `.sh` | ✅ |

- **Anthropic API**: 完全支持
- **DeepSeek 代理**: 支持（sonnet/opus 同模型，MCP 需验证）

## 参考

- 课程: 极客时间《Claude Code 工程化实战》(黄佳老师)
- 规范: [Agent Skills Protocol](https://agentskills.io/specification)
- MCP: [Model Context Protocol](https://modelcontextprotocol.io)
