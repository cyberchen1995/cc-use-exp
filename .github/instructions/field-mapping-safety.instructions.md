---
applyTo: "**"
---

# 字段映射安全规范

> 完整规范见 `.claude/skills/field-mapping-safety/`，本文件是 Copilot 仓库级精简版。

**核心原则**：不要根据类型定义推测字段名，必须查看原始代码（`git show HEAD~1:file`）的实际使用。

## 触发场景

- 重构表格列定义（dataIndex、columns）
- 重构枚举类型映射（typeMap、statusMap）
- 重构数据转换逻辑（render、formatter）
- 类型有多个相似字段（changedAt vs createdAt、changeType vs operationType）

## 5 个核心陷阱速记

| 陷阱 | 错误做法 | 正确做法 |
|------|---------|---------|
| 类型有歧义 | 按类型猜可选字段 `dataIndex: 'changedAt'`（可选） | 查原始代码用必填字段 `dataIndex: 'createdAt'` |
| 枚举不完整 | 重构只保留 3 个，实际原代码有 10 个 | `git show` 原代码逐个核对枚举 |
| TS 不报错 | TS 类型检查通过但运行时 undefined → "Invalid Date" | 运行时实测 + 防御性 `if (!val) return '-'` |
| rowKey 用可选字段 | `rowKey={r => ${r.changedAt}-${i}}` 重复 key | 用必填 `rowKey={r => r.id}` |
| 同步覆盖人工调整 | 外部源 null 也覆盖 / 用户手改后被下次同步覆盖回 | 源端 null 不动 + last-sync-value 模式（mapping 表加 `last_xxx` 列对比） |

## 同步覆盖决策矩阵（陷阱 #5）

| 源端值 | 目标 == lastSyncValue | 决策 |
|--------|---------------------|------|
| null | 任意 | 不动（源缺失不清空） |
| 有值 | true（仍是上次同步值） | 覆盖（跟随同步） |
| 有值 | false（用户改过） | 跳过 + log.info |
| 有值 | 目标为 null | 覆盖（首次同步） |

## 必检清单

- [ ] dataIndex/字段名是否查了 `git show HEAD~1:file` 而非类型推测
- [ ] 枚举映射是否对照原代码逐个核对（完整性 + 拼写）
- [ ] rowKey 是否使用必填字段（id），不是可选字段
- [ ] render 函数是否有空值/异常防御（`if (!val) return '-'` + try/catch）
- [ ] 同步流程 `setXxx(newValue)` 前是否有 null 判断
- [ ] 用户可编辑字段是否考虑"人工调整不被覆盖"（last-sync-value 模式）

## 嗅探信号

代码评审看到立即怀疑：
- TypeScript 中 dataIndex 写的是可选字段（如带 `?` 的字段）
- typeMap / statusMap 条目数比原代码少
- `rowKey` 用了非 id 字段或拼接字段
- 外部同步代码 `entity.setXxx(value)` 前后无 null 判断
