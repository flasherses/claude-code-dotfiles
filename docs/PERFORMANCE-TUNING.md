# Claude Code 性能调优剧本

基于课程 L31 6 维优化模型，提供具体参数和预期降本比例。

## 快速诊断

```powershell
# 运行 Token 分析
powershell -File scripts/analyze-tokens.ps1
```

## 优化维度

### 1. 模型分级（降本 15-30%）

| 场景 | 推荐模型 | 节省 |
|------|----------|:--:|
| 代码探索、文档搜索 | haiku | 70% vs sonnet |
| 代码审查、安全检查 | sonnet | 基线 |
| 架构设计、复杂重构 | opus | -50%（更贵） |

**操作**: 在 agent 定义中正确设置 `model:`

```yaml
# doc-explorer → haiku (cheap, fast)
model: haiku

# code-reviewer → sonnet (balanced)
model: sonnet
```

**DeepSeek 用户**: haiku→flash 是唯一有效分级。sonnet/opus 都走 pro，无成本差异。

### 2. 上下文压缩（降本 20-30%）

| 操作 | 节省 | 方法 |
|------|:--:|------|
| CLAUDE.md ≤ 300 行 | ~2K tokens/session | 超出部分拆分到 rules/ |
| Rules 加 frontmatter | ~3K tokens/session | 无 frontmatter 的 rule 全程加载 |
| 删除未使用的 Skills | ~100 tokens/skill | `scripts/analyze-tokens.ps1` 识别 |
| 删除未使用的 Agents | ~0 tokens | agent 按需加载，几乎无开销 |

### 3. Token 经济（降本 10-20%）

| 操作 | 方法 |
|------|------|
| 长任务拆分为短会话 | 超过 100K tokens 的会话 → `/compact` 或新会话 |
| 使用 caveman 模式 | 说 "caveman mode" → 减少 ~75% 输出 token |
| 避免重复读取文件 | Claude 已经读过的不需要再读（除非文件被修改） |

### 4. Checkpointing（防止浪费）

对于高风险操作（数据库迁移、批量重构），先 checkpoint：

```bash
git stash
# Claude 执行操作
# 如果失败: git stash pop
# 如果成功: git stash drop
```

### 5. MCP 复用

| 操作 | 节省 |
|------|------|
| MCP 连接复用 | 一次连接，整个会话使用，不重复初始化 |
| 禁用未使用的 MCP Server | 每个 MCP Server 启动消耗 ~1-3s + npx 下载 |

### 6. 调优剧本（具体场景）

#### 场景 1: CLAUDE.md 超过 400 行

```
诊断: scripts/analyze-tokens.ps1 → CLAUDE.md 412 lines
操作: 拆分第 4 节(代码规范)到 rules/<lang>-conventions.md
     用 frontmatter paths: ["**/*.<ext>"] 条件加载
效果: 基础 token 从 ~3.5K 降到 ~1.8K (节省 48%)
```

#### 场景 2: 20+ Skills 闲置

```
诊断: scripts/analyze-tokens.ps1 → 20 skills L1 overhead: ~2000 tokens
操作: 删除超过 30 天未触发的 skills
     观察: 在 Claude Code 中问 "What skills are available?"
效果: 5 个闲置 skill 删除 → 节省 ~500 tokens/session
```

#### 场景 3: Rules 缺少 frontmatter

```
诊断: scripts/analyze-tokens.ps1 → "Always loaded" 标记
操作: 给每个 rule 加 YAML frontmatter + paths:
效果: 原本全程加载的 rule 变为按需加载 (节省 ~1-3K tokens)
```

#### 场景 4: 单会话过长

```
诊断: scripts/analyze-tokens.ps1 → 某会话 > 150K tokens
操作: 下次类似任务 → 拆分为 2-3 个短会话
     每个会话聚焦一个主题
效果: 减少上下文污染，提高响应质量，降低 token 浪费
```

## 优化检查清单

- [ ] CLAUDE.md 100-300 行
- [ ] 所有 rules 有 YAML frontmatter + paths
- [ ] Skills 数量 10-15 个（删除 30 天未用的）
- [ ] 定期运行 `scripts/analyze-tokens.ps1`
- [ ] 长任务拆分为短会话（< 100K tokens）
- [ ] Agent model 正确分级（haiku 给简单任务）
- [ ] 生产环境用 settings.local.json 收紧权限

## 预期总降本

| 优化组合 | 预期降本 |
|----------|:--:|
| 仅模型分级 | 15-30% |
| 模型分级 + 上下文压缩 | 30-45% |
| 全部 6 维 | 40-50% |

> 来源: 课程 L31 数据 + 实际配置审计
