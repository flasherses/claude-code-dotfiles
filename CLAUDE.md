# 用户级 CLAUDE.md

## 语言与沟通

- **中文**为主要沟通语言，代码、技术术语、CLI 命令保持英文
- 直接简洁，不寒暄。用表格做对比时表头用中文
- 解释用 WHY 而非 WHAT——告诉我为什么这样做，不要描述代码本身做了什么
- 给出明确建议而非选项列表（"推荐 X，因为 Y"而非"A 可以、B 也行"）

## 技术偏好

- **操作系统**: Windows 11，Shell 优先用 PowerShell
- **路径格式**: 统一用正斜杠 `D:/path/to/file`，JSON 配置内同样
- **文件操作**: 精准修改用 Edit，新建文件用 Write。不改动用 Read 读过的文件无需再读验证
- **编辑器**: VS Code，用 `code` 命令打开文件

## 编码风格

- **不写废话注释** — 代码自解释，只写 WHY 不写 WHAT
- **不过度抽象** — 3 行重复好过一个不成熟的抽象
- **不引入未使用的依赖**
- **优先级**: 安全 > 正确性 > 性能 > 可读性 > 简洁
- **不写 feature flag、不写向后兼容 shim** — 直接改代码
- **不做过度的错误处理** — 只处理系统边界（用户输入、外部 API），不处理内部不可能发生的场景

## 个人禁区

以下操作**必须先问再动**：
- 修改 `~/.claude/settings.json` 或任何 .env 文件
- `git commit` / `git push` / `git rebase`
- 全局安装 npm/pip 包
- 删除文件 — 优先重命名为 `.deprecated` 后缀
- 修改其他项目目录下的文件（非当前工作目录）

## 常用命令模式

```powershell
# 项目探索
Get-ChildItem -Depth 2                      # 看目录结构
(Get-ChildItem -Recurse -Include *.py).Count # 统计文件数

# Git 操作（先问再执行）
git status
git diff --name-only
git log --oneline -10

# 打开文件/项目
code <path>
Start-Process <url-or-file>
```

## Windows 速查

| 场景 | 写法 |
|------|------|
| 家目录 | `~` 或 `$env:USERPROFILE` |
| 环境变量 | `$env:VAR_NAME` |
| 管道错误传播 | `$ErrorActionPreference = "Stop"` |
| 空设备 | `$null` |
| 文件存在检查 | `Test-Path <path>` |
