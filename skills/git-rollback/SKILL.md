---
name: git-rollback
description: >
  Rollback the last git commit safely. Three modes — soft (keep changes staged),
  mixed (keep changes unstaged, default), hard (discard changes entirely).
  This skill is disabled from automatic model invocation; it can only be
  triggered by explicit user command (/rollback).
  Use when user explicitly types /rollback or requests to undo the last commit.
disable-model-invocation: true
---

# Git Rollback — 回滚最后一次 Commit

## 目标

撤销最近一次 `git commit`，根据模式保留或丢弃变更。**不可逆操作，必须由用户显式触发。**

## 前置检查

执行前必须完成以下检查，任一失败则中止：

```powershell
# 1. 确认在 git 仓库中
git status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 不在 git 仓库中"; exit 1
}

# 2. 检查是否有未提交变更（可选保护）
$uncommitted = git status --porcelain
if ($uncommitted) {
    Write-Host "⚠️ 存在未提交的变更："
    Write-Host $uncommitted
    Write-Host "这些变更不会被回滚影响，但建议先处理"
}

# 3. 显示即将回滚的 commit
Write-Host "`n即将回滚的 commit："
git log -1 --format="  %h — %s (%an, %ar)"
```

## 三种回滚模式

| 模式 | 命令 | commit | 暂存区 | 工作区 |
|------|------|:------:|:------:|:------:|
| `--soft` | `git reset --soft HEAD~1` | 撤销 | ✅ 保留 | ✅ 保留 |
| `--mixed` | `git reset --mixed HEAD~1` | 撤销 | ❌ 清空 | ✅ 保留 |
| `--hard` | `git reset --hard HEAD~1` | 撤销 | ❌ 清空 | ❌ 丢弃 |

**默认模式**: `--mixed`（最安全）
**hard 模式**: 需要用户二次确认

## 执行流程

### Step 1: 确定模式

- 如果用户没有指定模式 → 使用 `--mixed`
- 如果用户说了 `soft` / `--soft` → 使用 `--soft`
- 如果用户说了 `hard` / `--hard` → **必须二次确认**

### Step 2: 二次确认（hard 模式专用）

```powershell
Write-Host "⚠️ HARD 模式将永久丢弃所有变更！"
Write-Host "最近一次 commit 的内容："
git show --stat HEAD
$confirm = Read-Host "确认执行 hard reset？(输入 YES 继续)"
if ($confirm -ne "YES") {
    Write-Host "已取消"; exit 0
}
```

### Step 3: 执行

```powershell
# soft 或 mixed
git reset <mode> HEAD~1

# 然后显示结果
Write-Host "`n回滚后的状态："
git log -1 --format="  HEAD → %h — %s (%ar)"
git status --short
```

## ⚠️ 易错点

1. **已 push 的 commit** — 如果 commit 已经推送到远程，回滚后需要 `git push --force` 才能同步。这会覆盖远程历史——**绝对不要在 main/master 上做，只在个人分支上做。**
2. **hard reset 不可恢复** — 一旦执行，变更只能通过 reflog 找回（`git reflog` + `git cherry-pick`）。
3. **merge commit 回滚** — `HEAD~1` 在 merge commit 上可能行为不符合预期，需要加 `-m 1` 参数。

## 回滚后的恢复

如果用户后悔了回滚操作：

```powershell
git reflog                        # 找到回滚前的 commit hash
git reset --hard <commit-hash>    # 恢复到该 commit
```
