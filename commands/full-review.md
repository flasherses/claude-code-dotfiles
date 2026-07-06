# /full-review — 并行全量审查

对当前项目执行并行全量审查：代码质量 + 安全审计 + 文档一致性，三个 agent 同时跑，最后汇总。

## 用法

```
/full-review [目标路径]
```

不指定路径时，审查 `git diff` 中所有变更文件。无 git 仓库时审查整个当前目录。

## 执行模式：并行分派（Parallel Dispatch）

与 `/review` 的区别：`/review` 顺序执行（先 reviewer 再 auditor），`/full-review` **同时启动**三个 agent。

```
/full-review
    │
    ├──→ code-reviewer   (background) ──→ 代码质量报告
    ├──→ security-auditor (background) ──→ 安全审计报告
    └──→ doc-explorer     (background) ──→ 文档一致性报告
            │
            └──→ 全部完成 → 汇总 → 交叉分析
```

## 执行流程

### 阶段 1: Decompose（拆解）

确定审查范围的变更文件列表：
```powershell
git diff --name-only HEAD 2>$null
# 或用户指定的路径
```

将审查拆为三个独立维度：
| 维度 | Agent | 关注点 |
|------|-------|--------|
| 代码质量 | code-reviewer | Bug、命名、性能、可读性 |
| 安全漏洞 | security-auditor | OWASP、密钥泄露、注入 |
| 文档一致 | doc-explorer | 代码与文档同步、注释完整性 |

### 阶段 2: Dispatch（并行分派）

**关键：在同一轮中使用 `run_in_background: true`，同时启动三个 agent。**

```
Agent: code-reviewer (background)
  Prompt: "Review the following changed files for bugs, code quality, and performance issues:
           [changed files list from phase 1]"

Agent: security-auditor (background)
  Prompt: "Audit the following changed files for OWASP Top-10 vulnerabilities, 
           exposed secrets, and unsafe patterns: [changed files list]"

Agent: doc-explorer (background)
  Prompt: "Check if the following changed files have adequate documentation,
           comments, and if any related docs need updating: [changed files list]"
```

三个 agent 同时执行，互不依赖。收到各自完成通知后进入阶段 3。

### 阶段 3: Collect（收集）

每个 agent 完成后返回结构化报告。收集三个报告的 key findings。

### 阶段 4: Consolidate（汇总 + 交叉分析）

将三个报告合并，重点做**交叉分析**——同一段代码在不同维度上的问题：

```markdown
## 并行全量审查报告

### 审查范围
- 变更文件: [N] 个
- 执行时间: [并行耗时]
- Agent: code-reviewer + security-auditor + doc-explorer

### 交叉分析（同一代码的多维度问题）

| 文件:行 | 代码质量 | 安全 | 文档 | 综合判断 |
|----------|----------|------|------|----------|
| `auth.py:23` | Warning: 复杂度过高 | Critical: SQL 注入 | Info: 缺 docstring | **必须修** |
| `utils.py:45` | Suggestion: 命名模糊 | — | Warning: 行为未注释 | 建议修 |

### 各维度汇总

#### 代码质量 (code-reviewer)
- Critical: [N], Warnings: [N], Suggestions: [N]
- [关键发现摘要]

#### 安全审计 (security-auditor)
- 风险等级: LOW / MEDIUM / HIGH / CRITICAL
- [关键发现摘要]

#### 文档一致性 (doc-explorer)
- [关键发现摘要]

### 总体评估
- 综合评级: PASS / NEEDS FIXES / DO NOT MERGE
- 必须修: [N] 项
- 建议修: [N] 项

### Top 3 优先修复
1. [最严重问题 — 含文件和行号]
2. [次严重问题 — 含文件和行号]
3. [第三严重 — 含文件和行号]
```
