# MCP Configuration Templates

Ready-to-use MCP (Model Context Protocol) server configurations. Copy the relevant template to your project's `.mcp.json` or user-level `~/.claude/.mcp.json`.

## Quick Start

Choose a template below, copy it to `.mcp.json` in your project root, and restart Claude Code.

```powershell
# Project-level (shared with team via git)
copy mcp\github.json .mcp.json

# User-level (personal, all projects)
copy mcp\github.json ~/.claude\.mcp.json
```

## Templates

| Template | Server | What it enables |
|----------|--------|-----------------|
| [github.json](github.json) | GitHub MCP | Read/write Issues, PRs, Repos, Search code |
| [filesystem.json](filesystem.json) | Filesystem MCP | Extended file access beyond project root |
| [sqlite.json](sqlite.json) | SQLite MCP | Query SQLite databases directly |

## Prerequisites

- Node.js >= 18 (for npx-based servers)
- Python >= 3.10 (for uvx-based servers)
- API tokens configured as environment variables

## Environment Variables

```powershell
# GitHub MCP requires a Personal Access Token
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_..."

# Or set permanently via system environment variables
[System.Environment]::SetEnvironmentVariable('GITHUB_PERSONAL_ACCESS_TOKEN', 'ghp_...', 'User')
```

## Verification

After configuring, restart Claude Code and ask:

> "What MCP tools are available?"

You should see tools prefixed with `mcp__<server>__<tool>`.

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| No MCP tools visible | Server not started | Check `npx` / `uvx` is installed |
| `mcp__github__*` not showing | Token missing or invalid | Verify `GITHUB_PERSONAL_ACCESS_TOKEN` |
| `command not found: npx` | Node.js not installed | `winget install OpenJS.NodeJS.LTS` |
| Windows + npx hangs | Execution policy | Already handled in hook commands |
| DeepSeek proxy + MCP | May not support MCP tool calling | Test with direct Anthropic API first |
