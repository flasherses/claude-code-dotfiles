# MCP 实战配置指南

## 1. GitHub MCP

### 前提

```powershell
# 1. 确认 Node.js >= 18
node --version

# 2. 创建 GitHub Personal Access Token
# https://github.com/settings/tokens → Generate new token (classic)
# 权限: repo, read:org, read:user

# 3. 设置环境变量
[System.Environment]::SetEnvironmentVariable('GITHUB_PERSONAL_ACCESS_TOKEN', 'ghp_...', 'User')
# 重启终端使环境变量生效
```

### 配置

复制 `mcp/github.json` 到项目根目录或 `~/.claude/`：

```powershell
# 项目级（团队成员共享）
copy mcp\github.json .mcp.json

# 用户级（所有项目生效）
copy mcp\github.json ~/.claude\.mcp.json
```

### 验证

重启 Claude Code 后：

> "What MCP tools are available?"

应看到：
```
mcp__github__create_issue
mcp__github__list_issues
mcp__github__search_repositories
mcp__github__get_pull_request
mcp__github__create_pull_request_review
...
```

### 测试

> "List open issues in flasherses/claude-code-dotfiles"

> "Create an issue titled 'Test MCP connection' in flasherses/claude-code-dotfiles"

### 排错

| 问题 | 检查 |
|------|------|
| `npx` command not found | `winget install OpenJS.NodeJS.LTS` |
| Permission denied (publickey) | Token 权限不足，重新生成 |
| MCP tools not showing | 重启 Claude Code |
| DeepSeek + MCP 不工作 | DeepSeek 代理可能不支持 MCP 工具调用。改用 Anthropic API 直连测试 |
| Windows + npx 超时 | 检查防火墙/代理设置 |

## 2. Filesystem MCP

允许 Claude 访问项目目录外的文件。

### 配置

编辑 `mcp/filesystem.json`，修改路径为实际需要访问的目录：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "D:/projects",
        "D:/documents"
      ]
    }
  }
}
```

### 使用场景

- 跨项目搜索代码
- 读取配置文件模板
- 访问共享文档目录

### 安全注意

- 不要暴露包含凭据的目录
- 不要允许访问 `~/`、`C:\Users\` 等敏感区域
- Filesystem MCP 是只读的，不能写文件

## 3. SQLite MCP

### 前提

```powershell
# 安装 uv (Python package installer)
pip install uv
# 或: winget install astral-sh.uv
```

### 配置

编辑 `mcp/sqlite.json`，修改数据库路径：

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "uvx",
      "args": [
        "mcp-server-sqlite",
        "--db-path",
        "D:/path/to/your/database.db"
      ]
    }
  }
}
```

### 使用

> "Query the SQLite database: SELECT name FROM sqlite_master WHERE type='table'"

> "Show me the schema of the users table"

## 4. Windows + DeepSeek 兼容性说明

DeepSeek API 代理（`api.deepseek.com/anthropic`）的 MCP 支持可能有以下限制：

| 功能 | Anthropic 直连 | DeepSeek 代理 |
|------|:--:|:--:|
| MCP 工具发现 (tools/list) | ✅ | ⚠️ 取决于代理实现 |
| MCP 工具调用 (tools/call) | ✅ | ⚠️ 同上 |
| stdio 传输 | ✅ | ✅ |
| HTTP/SSE 传输 | ✅ | ⚠️ |

**建议**: 先用 Anthropic API 直连测试 MCP，确认可用后再切回 DeepSeek。
