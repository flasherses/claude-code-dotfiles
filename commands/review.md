# /review — 代码审查

对指定文件或最近变更执行全流程代码审查。

## 用法

```
/review [文件或目录路径]
```

不指定路径时，审查 `git diff` 中所有变更文件。

## 执行流程

1. **确定审查范围**
   - 如果提供了 `$ARGUMENTS`，审查指定文件
   - 如果未提供参数，运行 `git diff --name-only` 获取变更文件列表
   - 如果不在 git 仓库中，提示用户指定文件

2. **代码审查** — 调起 `code-reviewer` 子代理逐文件审查
   - 关注：安全漏洞、逻辑错误、代码质量、性能问题

3. **安全审计**（如涉及以下文件类型自动触发）
   - 配置文件（`.json`, `.yaml`, `.env`, `.toml`）
   - 认证相关代码（`auth`, `login`, `session`, `token`）
   - 数据库操作代码（`sql`, `query`, `migrate`）
   - 调起 `security-auditor` 子代理

4. **汇总报告** — 合并 reviewer 和 auditor 的输出，给出总体评估

## 输出

- 审查文件数
- 问题汇总：Critical / Warning / Suggestion 各多少
- 整体评估：PASS / NEEDS FIXES / DO NOT MERGE
