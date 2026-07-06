# Claude Code Dotfiles

Claude Code 用户级工程化配置体系。基于 Windows 11 + PowerShell 5.1，兼容 DeepSeek API 代理。依据极客时间《Claude Code 工程化实战》(黄佳老师) 课程搭建。

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
┌─────────────────────────────────────────────────┐
│                     基础层                        │
│  CLAUDE.md  +  Rules(安全红线 + 编码规范)          │
│  settings.json  (权限: 8 allow + 9 deny)          │
├─────────────────────────────────────────────────┤
│                     执行层                        │
│  SubAgent ×4   Skill ×13   Command ×4            │
├─────────────────────────────────────────────────┤
│                     治理层                        │
│  Hook ×4  (PreToolUse, PostToolUse,              │
│            Stop, SubagentStop)                   │
├─────────────────────────────────────────────────┤
│                     运行层                        │
│  Superpowers Plugin v5.1.0  +  setup.ps1         │
└─────────────────────────────────────────────────┘
```

## 目录结构

```
~/.claude/
├── CLAUDE.md                          # 用户级记忆：偏好、禁区、常用命令
├── README.md                          # 本文件
├── setup.ps1                          # 一键部署脚本
├── settings.example.json              # 配置模板（不含 token）
├── .gitignore                         # 排除 token/缓存/skills/plugins
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
│   ├── git-rollback/                  # 自定义：安全回滚（双锁模式）
│   │   └── SKILL.md                   #   disable-model-invocation: true
│   └── [12 个 Superpowers Skills]     # Marketplace 安装
│
└── plugins/
    └── superpowers@claude-plugins-official (v5.1.0)
```

## 使用指南

### 斜杠命令

| 命令 | 用途 | 执行方式 |
|------|------|----------|
| `/review [路径]` | 快速代码检查 | 顺序：code-reviewer → security-auditor |
| `/audit [路径]` | 纯安全审计 | 单一 security-auditor 扫描 |
| `/full-review [路径]` | 全面审查 | 并行：reviewer + auditor + explorer 同时跑 |
| `/rollback [模式]` | 撤销最近 commit | `--soft` / `--mixed`(默认) / `--hard`(二次确认) |

### 子代理（通过描述自动匹配触发）

| Agent | 工具 | 当你说这些时自动触发... |
|-------|------|--------------------------|
| code-reviewer | Read, Grep, Glob | "review this code"、"审查"、"检查代码" |
| security-auditor | Read, Grep, Glob | "security audit"、"安全审计"、"check for vulnerabilities" |
| doc-explorer | Grep, Glob, Read | "how does X work"、"find where Y is"、"探索项目" |
| test-runner | Read, Grep, Glob, Bash | "run tests"、"跑测试"、"check if tests pass" |

### Hook 事件

| 事件 | 脚本 | 行为 |
|------|------|------|
| Bash 执行前 | `deny-dangerous.ps1` | 拦截 `rm -rf`、`curl\|sh`、`git push -f` 等 |
| Edit/Write 后 | `audit-edit.ps1` | 操作记入 `~/.claude/audit/<日期>.log` |
| 会话停止前 | `check-uncommitted.ps1` | 四步质量门检查（仅警告不阻断） |
| 子代理完成后 | `validate-subagent.ps1` | 校验输出格式，不合格则要求重来 |

### Skills（通过描述自动匹配触发）

| Skill | 用途 |
|-------|------|
| project-kickstart | 新项目初始化，自动生成 CLAUDE.md |
| project-scout | 陌生代码库探索，生成结构化报告 |
| diagnose | 结构化调试：重现→缩小→假设→修复→回归 |
| tdd | 红-绿-重构测试驱动开发 |
| agent-browser | 浏览器自动化（测试、抓取、表单填写） |
| spec-coach | 需求引导→实施计划 |
| grill-me | 设计方案压力测试 |
| improve-codebase-architecture | 代码库架构深化分析 |
| write-a-skill | 创建新的 Claude Code Skill |
| caveman | Token 节省模式（减少约 75%） |
| zoom-out | 上下文视角切换 |
| **git-rollback** | 安全回滚最后一次 commit（仅手动触发） |

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

# 查看已加载的 Skills（在 Claude Code 对话中问）
# "What skills are available?"

# 更新 Superpowers 插件
claude plugin update superpowers@claude-plugins-official
```

## 扩展

1. **添加个人规则**: 创建 `~/.claude/rules/<名称>.md`，带 YAML frontmatter 声明生效路径
2. **添加子代理**: 创建 `~/.claude/agents/<名称>.md`，配置 `tools` + `model`
3. **添加命令**: 创建 `~/.claude/commands/<名称>.md`
4. **添加 Hook**: 写 `.ps1` 脚本，在 `settings.json` 中注册

## 环境说明

- **Windows**: PowerShell 5.1 要求 `.ps1` 脚本为纯 ASCII，所有 Hook 已做兼容处理
- **DeepSeek**: 仅 2 个有效模型分级（haiku → flash，sonnet/opus → pro），agent 中 `model:` 字段仅能区分 haiku
- **MCP**: 尚未配置（计划接入 GitHub MCP Server）

## 参考资源

- 课程: 极客时间《Claude Code 工程化实战》(黄佳老师)
- 规范: [Agent Skills Protocol](https://agentskills.io/specification)
- MCP: [Model Context Protocol](https://modelcontextprotocol.io)
- 配套仓库: [huangjia2019/claude-code-engineering](https://github.com/huangjia2019/claude-code-engineering)
