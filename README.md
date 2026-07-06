# Claude Code Dotfiles

**将 Claude Code 从一个"聊天工具"升级为一套可治理、可观测、可复用、可版本的 AI 工程体系。**

[![Validate](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/validate.yml)
[![CI](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/claude-review.yml/badge.svg)](https://github.com/flasherses/claude-code-dotfiles/actions/workflows/claude-review.yml)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-brightgreen)

---

## 为什么需要这个项目

### 问题不在模型，在于工程化

Claude Code 开箱即用已经很强大——你可以和它聊天、让它改代码、帮你调试。但这种"裸用"模式有一个根本缺陷：**Claude 每次对话都是一个全新的开发者**。

它不了解你的项目架构。它不知道你的团队规范。它可以执行 `rm -rf`。它输出的代码风格完全随机。你上次花 30 分钟教它的东西，下次对话全部归零。

**这不是 Claude 的问题，是缺少工程化治理的问题。**

### 一个真实场景

```
你: "帮我审查最近改的代码"
Claude: "好的，请告诉我要审查哪些文件？项目的代码规范是什么？"

你: "帮我跑一下测试"
Claude: "好的，你的测试框架是什么？测试命令是什么？"

你: "提交一个 PR"
Claude: 执行了 git commit && git push --force
       覆盖了同事的代码
```

**有了这套工程体系之后**：

```
你: "帮我审查最近改的代码"
Claude: [自动读取 CLAUDE.md 了解项目]
       [自动触发 code-reviewer agent，按团队规范审查]
       [审查报告通过 SubagentStop Hook 验收格式]
       ✅ 完成。发现 2 个 Critical 问题，3 个 Warning。

你: "帮我跑一下测试"
Claude: [test-runner agent 自动检测 pytest/npm test/go test]
       [只允许执行测试命令，rm/curl/git push 被 Hook 拦截]
       ✅ 42 tests passed, 0 failed.

你: "提交一个 PR"
Claude: [pr-drafter agent 生成 PR 描述到 .claude/drafts/]
       [git push 被 PreToolUse Hook 拦截]
       ⛔ DENIED: git push requires manual confirmation.
```

### 核心理念

> **AI 不会取代程序员，但会取代不会用 AI 的程序员。工程化才是 LLM 落地的瓶颈，不是模型本身。**

这套体系的本质是**把人的判断固化为系统的规则**：

| 人的判断 | 固化为 | 系统规则 |
|----------|--------|----------|
| "这个命令很危险，不能自动执行" | → | PreToolUse Hook 正则拦截，exit 2 阻断 |
| "代码审查要检查安全、性能、可读性" | → | code-reviewer agent 的 7 项检查清单 |
| "新接口要按 Controller→Service→Mapper 模式" | → | add-rest-endpoint Skill，自动生成标准化代码 |
| "配置文件里的密码必须加密" | → | security.md rule + block-sensitive Hook 双层保护 |
| "这个项目的历史背景和架构决策" | → | CLAUDE.md，跨会话持久记忆 |

### 解决了什么

| 没有这套体系 | 有了这套体系 |
|-------------|-------------|
| Claude 不了解项目，每个对话从零开始 | CLAUDE.md 提供持久项目记忆，跨会话一致 |
| AI 可能执行 `rm -rf`、`git push --force`、`curl \| sh` | 6 层纵深防御：deny 权限 → 软规范 → PreToolUse 拦截 → 审计 → 白名单 → 质量门 |
| 每次代码风格随机，审查反复改同类问题 | Rules 约束编码规范，所有项目输出风格统一 |
| 反复口述"帮我写一个 Controller，要有参数校验..." | Skills 封装可复用模式，一句话触发，按团队规范生成 |
| Agent 输出质量不可控，不知道是否完成任务 | SubagentStop Hook 验收输出格式 + PII Hook 检测敏感数据泄露 |
| 换电脑重新配置，团队成员各搞一套 | `git clone` + `setup.ps1` 两分钟完整部署 |
| Token 成本不可见 | analyze-tokens 脚本 + PERFORMANCE-TUNING 6 维优化，预期降本 40-50% |
| 新项目手动创建全套配置 | project-engineering-init Skill 自动探测技术栈 → 生成全部配置 → 6 项验证 |
| 无法在 CI 中自动审查 | Headless 模式 + GitHub Actions，每次 PR 自动审查并评论 |

---

## 快速开始

```powershell
# 1. 克隆
git clone https://github.com/flasherses/claude-code-dotfiles.git ~/.claude-config

# 2. 部署
cd ~/.claude-config
powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1

# 3. 配置 API Key
notepad ~/.claude/settings.json
```

部署后在任意项目中验证：

```
"帮我审查最近改的代码"        → code-reviewer agent 自动触发
"安全审计一下"               → security-auditor agent 自动触发
"帮我搭建这个项目的工程化体系"  → project-engineering-init Skill 自动生成全套项目配置
/health-check               → 一键健康检查
```

---

## 架构设计

整个体系按四层架构组织，对应 AI Agent 的四大核心需求：

```
┌────────────────────────────────────────────────────────────┐
│                    基础层 — "知道什么、能做什么"              │
│  CLAUDE.md (记忆) + Rules (规范) + settings.json (权限)     │
│  解决: Claude 不了解项目、权限不受控                         │
├────────────────────────────────────────────────────────────┤
│                    执行层 — "怎么被组织成团队"               │
│  5 Agents + 6 Skills + 4 Commands                          │
│  解决: 任务无法拆分、能力无法复用、操作无法标准化              │
├────────────────────────────────────────────────────────────┤
│                    治理层 — "怎么被观察、怎么被扩展"          │
│  10 Hooks (4 事件 × 5 类型) + MCP 模板                      │
│  解决: 执行过程不可见、危险操作无拦截、外部系统无法连接         │
├────────────────────────────────────────────────────────────┤
│                    运行层 — "怎么脱离 IDE、被嵌入、被分发"    │
│  Plugin + CI/CD + Agent SDK + 运维脚本                       │
│  解决: 无法在 CI 中运行、无法编程调用、无法跨机器迁移          │
└────────────────────────────────────────────────────────────┘
```

### 为什么是四层

每一层解决一类根本问题，缺一层就会有一个维度的失控：

- **缺基础层** → Claude 是"新人"，不懂项目、行为不可预测
- **缺执行层** → 所有任务在主对话中串行，上下文爆炸、能力无法复用
- **缺治理层** → Claude 是"黑盒"，你不知道它做了什么、无法阻止它做不该做的事
- **缺运行层** → 体系困在 IDE 里，无法进入 CI/CD、无法被团队共享

---

## 项目包含什么

### 5 个 Agent（子代理）

每个 Agent 有独立的 system prompt、独立的工具白名单、独立的上下文窗口——这是"角色隔离"的硬边界。

| Agent | 类型 | 安全边界 | 触发场景 |
|-------|:--:|------|----------|
| `code-reviewer` | 只读 | Read, Grep, Glob — 零写权限 | "审查代码"、"review this" |
| `security-auditor` | 只读 | Read, Grep, Glob — OWASP 专项 | "安全审计"、"scan for vulnerabilities" |
| `doc-explorer` | 只读 | Grep, Glob, Read — haiku 低成本 | "这个项目怎么工作的" |
| `test-runner` | 可执行 | Bash 仅限 pytest/npm test/go test 等 | "跑测试"、"run tests" |
| `pr-drafter` | 可写 | Edit 仅限 `.claude/drafts/`，禁止 commit | "创建 PR"、"准备合并" |

**设计原则**：Description 写的是**"何时触发"**，不是"做什么"。Agent 通过语义匹配自动激活，不需要用户记住名字。

### 10 个 Hook（事件拦截器）

Hook 是"神经系统"——在关键时刻自动介入，观察或阻断 Claude 的行为。

| 事件 | Hook | 能力 |
|------|------|------|
| **PreToolUse** — Bash 执行前 | `deny-dangerous` | 阻断 `rm -rf`、`curl \| sh`、`git push -f` 等 9 条危险命令 (exit 2) |
| **PostToolUse** — Edit/Write 后 | `audit-edit` | 每笔文件修改写入审计日志，按日期归档 |
| **PostToolUse** — Edit/Write 后 | `mask-pii` | 检测 6 类 PII（身份证/手机号/邮箱/银行卡/IP/Token）并警告 |
| **Stop** — 会话停止前 | `check-uncommitted` | 四步质量门：未提交变更 → 测试覆盖 → 调试残留 → 敏感文件 |
| **SubagentStop** — Agent 完成后 | `validate-subagent` | 按 Agent 类型专项验收输出格式，不合格 exit 2 重来 |

每个 Hook 提供 Windows (`.ps1`) 和 macOS/Linux (`.sh`) 双版本。

### 6 个 Skill（可复用能力）

Skill 是 LLM 通过语义匹配自动发现和加载的能力包。采用三层渐进披露：描述（L1，常驻）→ 指令（L2，触发时加载）→ 参考文件（L3，按需读取）。

| Skill | 模式 | 说明 |
|-------|:--:|------|
| **project-engineering-init** | Pipeline + Generator | 任意项目自动探测技术栈 → 生成全套工程配置 → 6 项验证。4 步 Pipeline：Explore → Plan → Generate → Validate |
| **git-rollback** | 双锁 | 安全回滚 commit。Lock 1: `disable-model-invocation`（LLM 不可见），Lock 2: PreToolUse Hook 拦截 |
| **smart-review** | 注入 | 按变更文件类型自动选择对应 Agent（Java→code-reviewer，YAML→security-auditor），比 `/full-review` 省 50% token |
| **add-rest-endpoint** | Generator | Controller→Service→Mapper 标准化生成 |
| **add-mcp-tool** | Generator | @McpTool + Service + DTO 标准化生成 |
| **add-sso-controller** | Generator | SSO 集成控制器标准化生成 |

### 运维工具

| 工具 | 用途 |
|------|------|
| `health-check` | 一键检查：JSON 格式 + PS1 语法 + SH 语法 + Rules frontmatter + Agents 字段 + Hooks 注册 + 审计日志，共 8 步 |
| `check-conflicts` | 检测三层配置（用户级/项目级/本地级）之间的 deny/allow 冲突、规则冗余、过宽通配符 |
| `verify-mcp` | 测试 GitHub/Filesystem/SQLite MCP 连通性 + DeepSeek 兼容性诊断 |
| `analyze-tokens` | 分析会话 token 分布，识别浪费源：过长 CLAUDE.md、缺少 frontmatter、闲置 Skills、超长会话 |
| `PERFORMANCE-TUNING` | 6 维调优剧本：模型分级、上下文压缩、Token 经济、Checkpointing、MCP 复用、场景化调优 |
| `agent-sdk-hello` | Python SDK 示例：并行调 Agent + `create_sdk_mcp_server` 打包自定义工具 |

### CI/CD

| Workflow | 触发 | 说明 |
|----------|------|------|
| `validate.yml` | Push/PR | JSON 格式 + PS1 解析 + SH 语法 + YAML frontmatter + Agent/Skill 必填字段 + CLAUDE.md 行数 + 目录结构 |
| `claude-review.yml` | PR/手动 | 3 种模式：quick（每次 PR）、full（全面审查）、security（纯安全审计），结果自动评论到 PR |

---

## 安全模型

Claude Code 可以执行任意 Shell 命令。没有任何防护的情况下，一句"帮我清理临时文件"就可能执行 `rm -rf /`。

这套体系用 6 层纵深防御解决这个问题：

```
第1层: settings.json deny (9条)   ─ 权限级拦截。rm -rf / curl|sh / git push -f 根本不能执行
第2层: rules/security.md          ─ 软规范。告诉 Claude 为什么不能做，边缘情况能自己判断
第3层: PreToolUse Hook            ─ 事件级拦截。9 条正则，每次 Bash 执行前实时检查，exit 2 阻断
第4层: PostToolUse Hook ×2        ─ 事后审计 + PII 检测。每笔 Edit/Write 可追溯，敏感数据泄露被警告
第5层: SubAgent 工具白名单         ─ 角色隔离。3 个 Agent 只有 Read/Grep/Glob，零写权限
第6层: Stop Hook                  ─ 退出保护。四步质量门：提交→测试→调试→敏感文件
```

**核心安全原则**：

- **默认拒绝**：deny 优先于 ask 优先于 allow。测试命令在 allow 列表，危险命令在 deny 列表，deny 一定胜出
- **双重锁定**：关键操作同时受 Hook 和 Permission 两层保护。即使一层失效，另一层仍然拦截
- **全程审计**：每笔 Edit/Write 记录到 `~/.claude/audit/<date>.log`，可追溯谁在什么时候改了什么

---

## 设计原则

这套体系遵循 4 条铁律，来自真实项目中的反复验证：

### 1. 渐进式披露

配置信息分三层加载，避免上下文爆炸：
- **L1（常驻）**：CLAUDE.md 前 100 行 + Skill descriptions（~50 tokens/个）
- **L2（按需）**：匹配到的 Skill body + 相关 Rules
- **L3（引用）**：Skill 的 references/ 文件，LLM 决定是否读取

一个 14 个 Skill 的配置，每次对话的 L1 开销仅 ~1200 tokens。

### 2. Description 写触发时机，不写功能摘要

```
✅ "Use when user asks for code review, says 'review', '审查'..."
❌ "A code reviewer that checks code quality"
```

模型通过语义匹配决定是否触发。写"何时用"比写"是什么"命中率高得多。这一条来自 Superpowers 框架的 TDD 验证。

### 3. 安全硬约束 + 编码软规范

权限规则（settings.json deny/ask/allow）是**确定性执行**的硬约束。编码规则（rules/*.md）是**概率性遵守**的软规范。两者必须配套——只有软规范，Claude 可能不遵守；只有硬约束，Claude 不知道为什么。

### 4. 用户级通用 + 项目级专属

用户级配置是"宪法"——跨项目生效的 Agent、Hook、Rule。项目级配置是"地方法规"——每个项目特有的技术栈、目录结构、禁区。两者叠加，项目级覆盖用户级。

---

## 安装

### 方式一：setup.ps1（推荐）

```powershell
git clone https://github.com/flasherses/claude-code-dotfiles.git ~/.claude-config
cd ~/.claude-config
powershell -File setup.ps1
# 编辑 ~/.claude/settings.json 填入 API Key
```

setup.ps1 会自动：复制所有配置文件 → 将 `__CLAUDE_HOME__` 占位符替换为实际路径 → 创建必要目录。

### 方式二：Plugin

```powershell
claude plugin install github:flasherses/claude-code-dotfiles
```

---

## 维护

```powershell
# 更新配置
cd ~/.claude-config && git pull && powershell -File setup.ps1

# 健康检查
powershell -File scripts/health-check.ps1

# Token 诊断
powershell -File scripts/analyze-tokens.ps1

# 查看审计日志
cat ~/.claude/audit/$(Get-Date -Format 'yyyy-MM-dd').log
```

---

## 平台支持

| 平台 | Shell | Hook | 状态 |
|------|-------|------|:--:|
| Windows 11 | PowerShell 5.1 | `.ps1` | ✅ 全部测试通过 |
| macOS | Bash/Zsh | `.sh` | ✅ 语法验证通过 |
| Linux | Bash | `.sh` | ✅ 语法验证通过 |

- **Anthropic API**：完全支持全部功能
- **DeepSeek 代理**：支持（注意：sonnet/opus 指向同一模型，无成本差异。MCP 工具调用需自行验证兼容性）

---

## 参考

- [Agent Skills Protocol](https://agentskills.io/specification) — 33+ AI 产品采纳的开放规范
- [Model Context Protocol](https://modelcontextprotocol.io) — Anthropic 推出的 AI-外部系统连接标准
- 极客时间《Claude Code 工程化实战》(黄佳老师) — 本体系的理论基础
