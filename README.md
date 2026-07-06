# Claude Code Dotfiles

Claude Code 用户级工程化配置体系。基于 Windows 11 + PowerShell 5.1，兼容 DeepSeek API 代理。依据极客时间《Claude Code 工程化实战》(黄佳老师) 课程搭建。

## 为什么要工程化

**AI 不会取代程序员，但会取代不会用 AI 的程序员。工程化才是 LLM 落地的瓶颈，不是模型本身。**

没有工程体系的 Claude Code 像一个没有代码规范、没有 CI/CD、没有权限控制的开发团队——短期能跑，长期必然失控。具体表现为：

| 无工程体系 | 有工程体系 |
|------------|------------|
| Claude 不了解项目，每次对话从零开始 | CLAUDE.md 提供项目记忆，跨会话一致 |
| AI 可能执行 `rm -rf` 或 `git push --force` | 6 层纵深防御，危险操作全部拦截 |
| 代码风格因人而异，每次 AI 输出不一致 | Rules 约束编码规范，输出风格统一 |
| 重复性任务每次都口头描述一遍 | Skills 沉淀可复用能力，一句话触发 |
| 输出质量不可控，不知道 agent 有没有完成工作 | SubagentStop Hook 验收输出格式，不合格重来 |
| 无法迁移到其他电脑 | `git clone` + `setup.ps1` 两分钟部署 |
| 无法扩展外部能力 | MCP 协议连接 GitHub/数据库/浏览器 |

**工程化的本质是把"人的判断"固化为"系统的规则"**——人负责架构/边界/意图，AI 负责执行/知识/不知疲倦。

这套体系已在 3 个真实 Java 项目中验证：

| 项目 | 类型 | 模块数 | 结果 |
|------|------|:--:|------|
| aicontractreview-mcp | MCP Server | 2 | 13 个配置文件，全部生效 |
| aicontractreview-admin-backend | 管理后台 | 15 | 12 个文件，首次发现 5 个缺陷，已修正 |
| aicontractreview-custom | SSO 集成 | 3 | 9 个文件，优化后 skill 零缺陷生成 |

## 快速开始

```powershell
# 1. 克隆仓库
git clone git@github.com:flasherses/claude-code-dotfiles.git ~/.claude-config

# 2. 一键部署
cd ~/.claude-config
powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1

# 3. 填入 API Key
notepad ~/.claude/settings.json
```

## 架构总览

```
┌──────────────────────────────────────────────────────┐
│                       基础层                           │
│  CLAUDE.md  +  Rules(安全红线 + 编码规范)               │
│  settings.json  (权限: 8 allow + 9 deny)               │
├──────────────────────────────────────────────────────┤
│                       执行层                           │
│  SubAgent ×4   Skill ×14   Command ×4                 │
├──────────────────────────────────────────────────────┤
│                       治理层                           │
│  Hook ×4  (PreToolUse, PostToolUse,                   │
│            Stop, SubagentStop)                        │
├──────────────────────────────────────────────────────┤
│                       运行层                           │
│  Superpowers Plugin v5.1.0  +  setup.ps1              │
└──────────────────────────────────────────────────────┘
```

## 目录结构

```
~/.claude/
├── CLAUDE.md                          # 用户级记忆：偏好、禁区、常用命令
├── README.md                          # 本文件
├── setup.ps1                          # 一键部署脚本
├── settings.example.json              # 配置模板（不含 token）
├── .gitignore                         # 排除 token/缓存/marketplace skills
│
├── rules/
│   ├── security.md                    # 通用安全红线（所有项目生效）
│   └── code-style.md                  # 通用编码规范（所有项目生效）
│
├── agents/
│   ├── code-reviewer.md               # 只读 — 代码审查 (sonnet)
│   ├── security-auditor.md            # 只读 — 安全审计 (sonnet)
│   ├── doc-explorer.md                # 只读 — 代码探索 (haiku)
│   └── test-runner.md                 # 可执行 — 测试运行 (haiku)
│
├── commands/
│   ├── review.md                      # /review — 顺序审查
│   ├── audit.md                       # /audit — 安全审计
│   ├── full-review.md                 # /full-review — 并行全量审查
│   └── rollback.md                    # /rollback — 回滚最近 commit
│
├── hooks/
│   ├── deny-dangerous.ps1             # PreToolUse — 拦截危险命令
│   ├── audit-edit.ps1                 # PostToolUse — Edit/Write 审计日志
│   ├── check-uncommitted.ps1          # Stop — 四步质量门
│   └── validate-subagent.ps1          # SubagentStop — 子代理输出验收
│
├── skills/
│   ├── git-rollback/                  # 手写 — 安全回滚（双锁模式）
│   │   └── SKILL.md
│   ├── project-engineering-init/       # 手写 — 项目工程化体系自动生成
│   │   ├── SKILL.md
│   │   ├── trigger_eval.json
│   │   └── references/
│   │       ├── claude-md-template.md
│   │       ├── example-java-mcp.md
│   │       └── optional-components.md
│   └── [12 个 Superpowers Skills]     # Marketplace 安装
│
└── plugins/
    └── superpowers@claude-plugins-official (v5.1.0)
```

## 使用指南

### 项目工程化搭建（推荐首先使用）

在任意项目根目录，一句话自动生成全套工程配置：

> "帮我搭建这个项目的工程化体系"

触发 `project-engineering-init` Skill → 探测技术栈 → 生成 CLAUDE.md + rules + settings + hooks + commands。

已支持：Java/Maven、Python、Node.js、Go、Rust、静态网站。生成后自动验证 6 项检查。

### 斜杠命令

| 命令 | 用途 | 执行方式 |
|------|------|----------|
| `/review [路径]` | 快速代码检查 | 顺序：code-reviewer → security-auditor |
| `/audit [路径]` | 纯安全审计 | 单一 security-auditor 扫描 |
| `/full-review [路径]` | 全面审查 | 并行：reviewer + auditor + explorer 同时跑 |
| `/rollback [模式]` | 撤销最近 commit | `--soft` / `--mixed`(默认) / `--hard`(二次确认) |

### 子代理（通过描述自动匹配触发）

| Agent | 类型 | Tools | 触发词 |
|-------|:--:|-------|--------|
| code-reviewer | 只读 | Read, Grep, Glob | "review"、"审查"、"检查代码" |
| security-auditor | 只读 | Read, Grep, Glob | "audit"、"安全审计" |
| doc-explorer | 只读 | Grep, Glob, Read | "explain"、"探索项目" |
| test-runner | 可执行 | Read, Grep, Glob, Bash | "run tests"、"跑测试" |

### Hook 事件

| 事件 | 脚本 | 行为 |
|------|------|------|
| Bash 执行前 | `deny-dangerous.ps1` | 拦截 `rm -rf`、`curl\|sh`、`git push -f` |
| Edit/Write 后 | `audit-edit.ps1` | 操作记入 `~/.claude/audit/<日期>.log` |
| 会话停止前 | `check-uncommitted.ps1` | 四步质量门（仅警告） |
| 子代理完成后 | `validate-subagent.ps1` | 校验输出格式，不合格重来 |

### Skills

| Skill | 来源 | 用途 |
|-------|:--:|------|
| **project-engineering-init** | 手写 | 任意项目自动生成全套工程化配置 |
| **git-rollback** | 手写 | 安全回滚 commit（双锁，仅手动触发） |
| project-kickstart | Marketplace | 新项目初始化，生成 CLAUDE.md |
| project-scout | Marketplace | 陌生代码库探索 |
| diagnose | Marketplace | 结构化调试循环 |
| tdd | Marketplace | 红-绿-重构测试驱动开发 |
| agent-browser | Marketplace | 浏览器自动化 |
| spec-coach | Marketplace | 需求引导→实施计划 |
| grill-me | Marketplace | 设计方案压力测试 |
| improve-codebase-architecture | Marketplace | 代码库架构深化 |
| write-a-skill | Marketplace | 创建新 Skill |
| caveman | Marketplace | Token 节省模式 |
| zoom-out | Marketplace | 上下文视角切换 |

## 安全模型（6 层纵深防御）

```
第1层: settings.json deny 规则     — 权限级拦截（根本不让用）
第2层: rules/security.md           — 软规范（告诉为什么不能用）
第3层: PreToolUse Hook             — 事件级实时正则拦截
第4层: PostToolUse Hook            — 事后审计（每笔变更可追溯）
第5层: SubAgent 工具白名单         — 角色隔离（默认只读零风险）
第6层: Stop Hook                   — 退出保护（四步质量门）
```

## 维护

```powershell
# 从远端更新配置
cd ~/.claude-config && git pull
powershell -File setup.ps1

# 查看今天的审计日志
cat ~/.claude/audit/$(Get-Date -Format 'yyyy-MM-dd').log

# 更新 Superpowers 插件
claude plugin update superpowers@claude-plugins-official
```

## 扩展

1. **添加个人规则**: 创建 `~/.claude/rules/<名称>.md`，带 YAML frontmatter 声明生效路径
2. **添加子代理**: 创建 `~/.claude/agents/<名称>.md`，配置 `tools` + `model`
3. **添加命令**: 创建 `~/.claude/commands/<名称>.md`
4. **添加 Skill**: 创建 `~/.claude/skills/<名称>/SKILL.md`，遵循 3 层渐进披露
5. **添加 Hook**: 写 `.ps1` 脚本（纯英文 ASCII），在 `settings.json` 中注册

## 环境说明

- **Windows**: PowerShell 5.1 要求 `.ps1` 脚本为纯 ASCII，所有 Hook 已做兼容处理。Hook 命令必须包含 `-ExecutionPolicy Bypass`
- **DeepSeek**: 仅 2 个有效模型分级（haiku → flash，sonnet/opus → pro），agent 中 `model:` 字段仅能区分 haiku
- **MCP**: 尚未配置（计划接入 GitHub MCP Server）

## 参考资源

- 课程: 极客时间《Claude Code 工程化实战》(黄佳老师)
- 规范: [Agent Skills Protocol](https://agentskills.io/specification)
- MCP: [Model Context Protocol](https://modelcontextprotocol.io)
- 配套仓库: [huangjia2019/claude-code-engineering](https://github.com/huangjia2019/claude-code-engineering)
