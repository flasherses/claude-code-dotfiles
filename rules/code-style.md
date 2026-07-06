---
description: 通用编码规范，所有项目默认适用。项目级规则可覆盖。
paths:
  - "**/*"
---

# 通用编码规范

## 注释原则

**不写注释，除非解释 WHY。** 代码本身应该自解释。

```python
# ❌ 废话注释
def get_user(user_id):
    # 通过 ID 获取用户
    return db.query(User).filter(User.id == user_id).first()

# ✅ 解释 WHY
def get_user(user_id):
    # 使用 with_for_update 防止并发修改导致的竞态条件
    return db.query(User).with_for_update().filter(User.id == user_id).first()
```

## 抽象原则

**3 行重复好过一个不成熟的抽象。** 不要为了"未来可能"而设计。

- 同一逻辑出现 3+ 次 → 可以提取
- 只有 1 次 → 内联
- 不确定 → 先不抽象，等 pattern 更清晰再改

## 依赖原则

- 不引入未真正使用的依赖
- 能用标准库的不加第三方库
- 引入新依赖前想清楚：能否用 5 行代码代替一个 5MB 的包？

## 安全优先

**安全 > 正确性 > 性能 > 可读性 > 简洁**

遇到冲突时按此优先级决策。例如：安全的写法多 10 行 → 选安全的。

## 错误处理

- **只在系统边界做错误处理** — 用户输入、外部 API、文件 I/O
- **不处理不可能发生的场景** — 信任内部代码和框架保证
- **fallback 降级** — 关键路径失败时有兜底方案，不做无意义的 try/catch

## 命名

- 用描述性名称，不缩写（`user_profile` 不是 `usr_prf`）
- 布尔变量用 `is_` / `has_` / `should_` 前缀
- 遵循各语言的命名约定（Python: snake_case, JS: camelCase, Go: PascalCase/camelCase）

## Git 操作

- 不 force push 到 main/master
- 不跳过 hooks（`--no-verify`、`--no-gpg-sign`）
- commit 前确保变更已审查
- commit message 写 WHY 不写 WHAT
