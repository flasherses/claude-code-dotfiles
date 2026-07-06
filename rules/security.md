---
description: 通用安全红线，所有项目必须遵守。
paths:
  - "**/*"
---

# 安全红线

## 绝对禁止

### 1. 禁止硬编码敏感信息

任何文件中不得出现：
- API Key / Token / Secret
- 数据库连接字符串（含密码）
- 私钥 / 证书
- OAuth client secret

**WHY**: 代码可能被提交到 Git、分享、或被 AI 在上下文中泄露。敏感信息应通过环境变量或密钥管理服务注入。

```python
# ❌ API_KEY = "sk-xxxx"
# ✅
import os
api_key = os.environ.get("API_KEY")
if not api_key:
    raise RuntimeError("API_KEY 环境变量未设置")
```

### 2. 禁止代码注入模式

```python
# ❌ SQL 注入
query = f"SELECT * FROM users WHERE name = '{name}'"

# ❌ 命令注入
os.system(f"ping {user_input}")

# ❌ XSS (JavaScript)
element.innerHTML = userInput;

# ❌ eval
eval(userCode)
```

### 3. 禁止对外部 URL 发送敏感数据

除非用户明确要求，不得将代码内容、文件路径、配置信息发送到外部 URL。

### 4. 文件写入不超出项目根目录

Write/Edit 操作的目标路径必须在当前工作目录内。不得写 `C:\Windows`、`/etc`、`~/.ssh` 等系统路径。

## 危险操作需确认

以下操作在 `~/.claude/settings.json` 中配置为 `ask` 或 `deny`：

| 操作 | 权限 | 原因 |
|------|------|------|
| `rm -rf` | deny | 不可逆删除 |
| `curl ... \| sh` | deny | 管道注入风险 |
| `git push --force` | deny | 覆盖远程历史 |
| `chmod 777` | deny | 权限过度开放 |
| `git commit` | ask | 需人工审查 |
| 修改 .env / settings.json | ask | 配置变更敏感 |
