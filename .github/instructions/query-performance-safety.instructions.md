---
applyTo: "**"
---

# 查询性能安全规范

> 完整规范见 `.claude/skills/query-performance-safety/`，本文件是 Copilot 仓库级精简版。

防止 N+1、IN 子句过长、递归内存炸裂、嵌套重复查询、索引缺失、缓存失效等高频性能陷阱。

## 6 个核心陷阱速记

| 陷阱 | 错误做法 | 正确做法 |
|------|---------|---------|
| 循环内单条查询 → N+1 | `for (Order o : orders) { findById(o.userId) }` | 先批量 IN 查询落 Map，循环查 Map |
| IN 子句不分批 | 直接 5000 个 ID 进 IN | `IN_BATCH_SIZE=500` 分批合并；SUM/COUNT 也分批 |
| BFS/递归只限 depth | 只 `depth ≤ 3` 不限总数 | 加 `MAX_TOTAL_NODES=5000` 硬上限 + log.warn 截断 |
| 嵌套 service 重复查询 | `count + sum + list` 各跑一遍 BFS | 上提为返回 list 的底层方法，上层一次调用 |
| 大表缺索引 | 新增 `findByXxx` 但 xxx 列无索引 | 实体加 `@Index` + Flyway 显式 CREATE INDEX，EXPLAIN 验证 |
| 缓存反模式 | `@Cacheable("user")` key 不带 tenantId / 含 Pageable | key 显式列稳定字段 + 含 tenantId；写操作配 `@CacheEvict` |

## 隐式 N+1（最坑）

循环内调 `convertToDTO()` / `toResponseDto()` / `enrichEntity()` —— 一个函数藏 4-5 次 `findById`，循环 N 次 = N×K 次 SQL。

**修复策略**：
- 策略 A：先用 entity 筛选/分组，只对真正展示的批量预加载关联
- 策略 B：场景化轻量 DTO（列表用 lightweight，详情用完整）
- 策略 C：提供 `convertToDTOs(List<T>)` 批量版

## Repository 必须配套批量方法

| 单条 | 必须配套 |
|------|---------|
| `findById` | `findAllById` / `findByIdIn` |
| `findByTenantIdAndId` | `findByTenantIdAndIdIn` |
| `findByFooId` | `findByFooIdIn` |

## 性能预算速查

| 查询模式 | 可接受 SQL 数 | 警戒线 |
|---------|--------------|--------|
| 单实体查询 | 1-3 | > 5 |
| 列表（N 外键 join） | 1 + 外键种类数 | 与 N 相关即不可接受 |
| BFS/递归 | depth × 1 + IN 批次数 | 与节点数线性相关 |
| 聚合统计 | 1 SUM 或分批数 | 全量加载到内存 |

## 嗅探信号

- service / handler 方法里搜 `findById(` / `getOne(` / `findOne(`，是否在循环/stream 链中
- `convertToDTO` / `toXxxDto` / `enrich` 是否被循环调用
- IN 查询参数 list 无 size 上限，可能 > 500
- `@Cacheable` key 包含 `Pageable` 或不含 tenantId
- 同 Controller 内多次调用同一底层重查询
