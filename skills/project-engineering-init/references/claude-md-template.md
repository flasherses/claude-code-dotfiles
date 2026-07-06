# CLAUDE.md Template Reference

Universal 6-element template. Fill tech-specific content from project exploration results.

```markdown
# <Project Name> — Project CLAUDE.md

## 1. Project Goal

[2-3 sentences: who it serves, what problem it solves, key constraints]
[Example: "Inventory MCP Server — exposes inventory management
capabilities as standardized MCP tools for AI Agents."]

## 2. Tech Stack

| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Language | [e.g. Java] | [e.g. 21] | |
| Build | [e.g. Maven] | [e.g. 3.x] | |
| Framework | [e.g. Spring Boot] | [e.g. 4.1.0] | |
| ORM | [if applicable] | | |
| Database | [if applicable] | | |
| HTTP Client | [if applicable] | | |
| Test | [framework or "none"] | | |
| Other | [encryption, logging, etc.] | | |

## 3. Directory Structure

[Only list directories AI will frequently touch]
```
project/
├── build-file (pom.xml / package.json / go.mod / ...)
├── src/main/...              # [what's here]
├── src/test/...              # [what's here, or "no tests"]
├── docs/                     # [what's here]
└── config/                   # [what's here]
```

[If multi-module, list modules and their responsibilities]

## 4. Code Conventions

### Naming
[Language-specific naming rules]

### Framework Patterns
[How to create new components in this framework]
[Key annotations, decorators, or patterns]

### File Organization
[Where to put new files of each type]

### Logging
[What logging library, how to use it, what NOT to do]

### Error Handling
[How to handle errors, where to handle them, where NOT to]

## 5. Forbidden Zones

### Must Ask Before Touching
- [sensitive config files]
- [build configuration]
- [entry point class/file]

### Never Auto-Execute
- `git push` — requires manual confirmation
- `<deploy command>` — requires manual review
- Delete operations on [specific directories]

### Protected Files
- [files with encrypted credentials]
- [files that should only be edited manually]

## 6. Common Commands

```shell
# Build
<build command>

# Run
<run command with required env vars>

# Test (if applicable)
<test command>

# Single module (if multi-module)
<module-specific commands>

# Other useful commands
<lint, format, dependency tree, etc.>
```
```

## Key Principles

1. **100-300 lines** — if exceeding, split details into `.claude/rules/`
2. **Specific, not generic** — "use @McpTool annotation with description field" not "write good code"
3. **Answer WHY** — AI that understands the reason can handle edge cases
4. **Progressive disclosure** — highest-frequency 20% here, rest in rules/
5. **Forbidden zones must be actionable** — file paths or patterns, not vague "be careful"
