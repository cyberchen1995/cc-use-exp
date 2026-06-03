---
applyTo: "**"
---

# 异步任务模式规范

> 完整规范见 `.claude/skills/async-task-pattern/`，本文件是 Copilot 仓库级精简版。

操作可能跑 > 10 秒（批量数据、远程 API 批量调用、全表扫描）时，必须用 `triggerAsync()` + `getStatus()` 异步状态机模式。

## 触发条件

满足任一即属本规范覆盖：
- 单次处理 ≥ 1000 条
- 远程批量调用 batch × 延迟 > 5s
- 历史已出过 504/502/30s timeout
- 用户描述"卡住"、"转圈很久"、"点完没反应"

## 5 个核心陷阱速记

| 陷阱 | 错误做法 | 正确做法 |
|------|---------|---------|
| 同步阻塞 | Controller 同步算 30s+ | 立即返回任务态，Executor 异步执行 |
| 状态缓存无界 | `ConcurrentHashMap<Long, State>` 永不清理 | 入口清理 + TTL（推荐）/ 定时任务 / LRU |
| 子线程丢 Context | `executor.execute(() -> run())` | 子线程入口手动 `TenantContext.setTenantId(tenantId)` + finally clear（同样适用 SecurityContext/MDC） |
| 重复触发并发跑 | 用户连点两次 → 起两个任务覆盖状态 | RUNNING 时 `return existing.snapshot()`，前端按钮 disabled |
| 前端双 polling | mount 用 setTimeout + status 变 RUNNING 又起 setInterval | 只能有一套 polling，由依赖 status 的 effect 接管 |

## 必检清单

- [ ] 真的需要异步？同步可压到 < 5s 就别上
- [ ] 触发接口立即返回，不带任何业务计算
- [ ] 状态缓存有 TTL/LRU；RUNNING 拒绝重复触发
- [ ] 子线程恢复 TenantContext / SecurityContext / MDC
- [ ] FAILED 状态的 `errorMessage` 透传给前端
- [ ] 前端只有一套 polling 机制 + 按钮 RUNNING 时 disabled

## 反模式

- ❌ 启动新 `Thread()` 而非 Executor（OOM 风险）
- ❌ 状态塞 HTTP Session（多实例失效）/ 写文件（容器重启丢）
- ❌ 同类内调用 `@Async` 方法（self-invocation 不走代理）
- ❌ 前端 `setInterval` 不 cleanup（路由切换后还在跑）

## 嗅探信号

代码评审看到立即怀疑：
- Controller 内直接做循环 + JPA 写库 + 远程调用
- 成员变量是 `ConcurrentHashMap<X, State>` 但找不到 evict 逻辑
- `executor.execute(...)` 内引用了 `TenantContext.getXxx()` 但前面没 setTenantId
