# Claude Code Dotfiles

User-level engineering system for Claude Code. Built on Windows 11 + PowerShell 5.1, compatible with DeepSeek API proxy. Based on the course "Claude Code Engineering Practice" (Geektime, Huang Jia).

## Quick Start

```powershell
# 1. Clone
git clone git@github.com:flasherses/claude-code-dotfiles.git ~/.claude-config

# 2. Deploy
cd ~/.claude-config
powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1

# 3. Edit API key
notepad ~/.claude/settings.json
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Foundation                     │
│  CLAUDE.md  +  Rules (security, code-style)      │
│  settings.json  (permissions: 8 allow + 9 deny)  │
├─────────────────────────────────────────────────┤
│                   Execution                      │
│  SubAgents ×4   Skills ×13   Commands ×4        │
├─────────────────────────────────────────────────┤
│                  Governance                       │
│  Hooks ×4  (PreToolUse, PostToolUse,             │
│             Stop, SubagentStop)                  │
├─────────────────────────────────────────────────┤
│                   Runtime                        │
│  Superpowers Plugin v5.1.0  +  setup.ps1        │
└─────────────────────────────────────────────────┘
```

## File Structure

```
~/.claude/
├── CLAUDE.md                          # Personal preferences & forbidden zones
├── README.md                          # This file
├── setup.ps1                          # One-command deployment script
├── settings.example.json              # Config template (no secrets)
├── .gitignore                         # Excludes token, cache, skills, plugins
│
├── rules/
│   ├── security.md                    # Security red lines (all projects)
│   └── code-style.md                  # Coding conventions (all projects)
│
├── agents/
│   ├── code-reviewer.md               # Read-only code review (sonnet)
│   ├── security-auditor.md            # Read-only security audit (sonnet)
│   ├── doc-explorer.md                # Read-only code exploration (haiku)
│   └── test-runner.md                 # Executable test runner (haiku)
│
├── commands/
│   ├── review.md                      # Sequential review
│   ├── audit.md                       # Security-only audit
│   ├── full-review.md                 # Parallel multi-agent review
│   └── rollback.md                    # Git commit rollback
│
├── hooks/
│   ├── deny-dangerous.ps1             # PreToolUse: block rm -rf, curl|sh, etc.
│   ├── audit-edit.ps1                 # PostToolUse: log all Edit/Write ops
│   ├── check-uncommitted.ps1          # Stop: 4-step quality gate
│   └── validate-subagent.ps1          # SubagentStop: validate output format
│
├── skills/
│   ├── git-rollback/                  # Custom: safe commit rollback
│   │   └── SKILL.md                   #   disable-model-invocation: true
│   └── [12 Superpowers skills]        # Marketplace-installed
│
└── plugins/
    └── superpowers@claude-plugins-official (v5.1.0)
```

## Usage Guide

### Slash Commands

| Command | Usage | What it does |
|---------|-------|-------------|
| `/review [path]` | Quick code check | Sequential: code-reviewer then security-auditor |
| `/audit [path]` | Security-only | Single security-auditor scan |
| `/full-review [path]` | Comprehensive | Parallel: reviewer + auditor + explorer simultaneously |
| `/rollback [mode]` | Undo last commit | `--soft` / `--mixed` (default) / `--hard` (double confirm) |

### Sub-Agents (auto-triggered by description matching)

| Agent | Tools | Triggers when you say... |
|-------|-------|--------------------------|
| code-reviewer | Read, Grep, Glob | "review this code", "审查", "检查代码" |
| security-auditor | Read, Grep, Glob | "security audit", "安全审计", "check for vulnerabilities" |
| doc-explorer | Grep, Glob, Read | "how does X work", "find where Y is", "探索项目" |
| test-runner | Read, Grep, Glob, Bash | "run tests", "跑测试", "check if tests pass" |

### Hook Events

| Event | Script | Action |
|-------|--------|--------|
| Before Bash runs | `deny-dangerous.ps1` | Blocks `rm -rf`, `curl\|sh`, `git push -f`, etc. |
| After Edit/Write | `audit-edit.ps1` | Logs operation to `~/.claude/audit/<date>.log` |
| Before session stops | `check-uncommitted.ps1` | 4-step quality gate (warn only) |
| After sub-agent completes | `validate-subagent.ps1` | Validates output format; retries if malformed |

### Skills (auto-triggered by description matching)

| Skill | Purpose |
|-------|---------|
| project-kickstart | Initialize new projects with CLAUDE.md |
| project-scout | Map unfamiliar codebases |
| diagnose | Structured debugging loop |
| tdd | Red-green-refactor test-driven development |
| agent-browser | Browser automation for testing/scraping |
| spec-coach | Refine requirements into implementation plans |
| grill-me | Stress-test design decisions |
| improve-codebase-architecture | Find architectural improvements |
| write-a-skill | Create new Claude Code skills |
| caveman | Ultra-compact token-saving mode |
| zoom-out | Broader context perspective |
| **git-rollback** | Safe git commit rollback (manual trigger only) |

## Security Model (6-Layer Defense)

```
Layer 1: settings.json deny rules    — Permission-level block
Layer 2: rules/security.md           — Soft guidance on why
Layer 3: PreToolUse Hook             — Real-time regex interception
Layer 4: PostToolUse Hook            — Audit trail for every edit
Layer 5: SubAgent tool whitelist     — Role isolation (read-only by default)
Layer 6: Stop Hook                   — Uncommitted-change warning
```

## Maintenance

```powershell
# Update config from upstream
cd ~/.claude-config && git pull
powershell -File setup.ps1

# View today's audit log
cat ~/.claude/audit/$(Get-Date -Format 'yyyy-MM-dd').log

# Check which skills are loaded
# Ask in Claude Code: "What skills are available?"

# Update Superpowers plugin
claude plugin update superpowers@claude-plugins-official
```

## Customization

1. **Add a personal rule**: Create `~/.claude/rules/<name>.md` with YAML frontmatter
2. **Add a sub-agent**: Create `~/.claude/agents/<name>.md` with `tools` + `model` frontmatter
3. **Add a command**: Create `~/.claude/commands/<name>.md`
4. **Add a hook**: Write a `.ps1` script, register in `settings.json`

## Platform Notes

- **Windows**: PowerShell 5.1 requires ASCII-only `.ps1` scripts. All hooks are pure ASCII.
- **DeepSeek**: Only 2 effective model tiers (haiku → flash, sonnet/opus → pro). Agent `model:` field only distinguishes haiku from others.
- **MCP**: Not configured yet (planned: GitHub MCP server).

## References

- Course: "Claude Code Engineering Practice" (Geektime, Huang Jia)
- Specification: [Agent Skills Protocol](https://agentskills.io/specification)
- MCP: [Model Context Protocol](https://modelcontextprotocol.io)
- Companion repo: [huangjia2019/claude-code-engineering](https://github.com/huangjia2019/claude-code-engineering)
