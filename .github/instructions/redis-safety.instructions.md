---
applyTo: "**"
---

# Redis 安全规范

> 完整规范见 `.claude/skills/redis-safety/`，本文件是 Copilot 仓库级精简版。

适用 go-redis / Jedis / redis-py / ioredis 等所有 Redis 客户端。

## 禁止操作

| 禁止 | 替代 | 原因 |
|------|------|------|
| `KEYS *` / `KEYS pattern` | `SCAN` 游标迭代 | KEYS 是 O(N) 阻塞，生产 Redis 会卡死 |
| `FLUSHDB` / `FLUSHALL` | 按前缀 `SCAN + DEL` | 全量删除风险极高 |
| 无 TTL 的 `SET` | 必须设置 TTL | 防止内存泄漏 |

## 必须遵守

| 项 | 规则 | 速记 |
|----|------|------|
| 替代 KEYS | 用 SCAN 游标 | Go `rdb.Scan` / Java `jedis.scan` / Python `r.scan_iter` |
| 大 key 控制 | value ≤ 10KB；集合元素 ≤ 5000 | 超过拆多 key |
| 批量调用 | 用 Pipeline，禁止循环单次调用 | `pipe := rdb.Pipeline()` → `pipe.Exec()` |
| TTL 强制 | 所有 key 必须显式 TTL | `SET key val EX 86400` 而非 `SET key val 0` |

## 嗅探信号

代码评审看到以下立即怀疑：

- 任何 `KEYS(`、`keys(` 调用 → 必须改 SCAN
- `Set(ctx, key, val, 0)` / `set(key, val)`（无 TTL 参数）→ 必须加 TTL
- `for ... rdb.Get/Set` 循环 → 必须改 Pipeline
- Hash/ZSet 写入未限制元素数量 → 必须加 ≤ 5000 校验
