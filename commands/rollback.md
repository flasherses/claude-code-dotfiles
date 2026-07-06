# /rollback — 回滚最后一次 Git Commit

撤销最近一次 `git commit`，根据模式保留或丢弃变更。

## 用法

```
/rollback [模式]
```

模式选项：
- 不指定 = `--mixed`（默认）：撤销 commit，保留工作区变更（未暂存）
- `soft` / `--soft`：撤销 commit，保留暂存区和工作区
- `hard` / `--hard`：撤销 commit + 丢弃所有变更（**需二次确认**）

## 示例

```
/rollback              → mixed 模式，最安全
/rollback --soft       → 撤销 commit，变更留在暂存区可以重新 commit
/rollback --hard       → 完全丢弃（会要求二次确认）
```

## 执行流程

1. 调起 `git-rollback` Skill
2. Skill 执行前置检查（git 仓库？未提交变更？显示目标 commit）
3. 如果是 hard 模式 → 二次确认
4. 执行回滚 → 显示结果

## ⚠️ 警告

- **已 push 的 commit 不要随意回滚**——回滚 + force push = 覆盖远程历史
- **hard reset 不可恢复**——变更只能通过 `git reflog` 找回
- **不要在 main/master 上做 hard reset**
