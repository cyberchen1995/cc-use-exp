---
applyTo: "**"
---

# API 设计安全规范

> 完整规范见 `.claude/skills/api-design-safety/`，本文件是 Copilot 仓库级精简版。

防止响应字段错位、类型歧义、产物完整性缺失、异常类型用错等 REST API 设计缺陷。

## 6 个核心陷阱速记

| 陷阱 | 错误做法 | 正确做法 |
|------|---------|---------|
| 泛型重载歧义 | `return ApiResponse.success(stringValue)` → 进入 message 字段 | 明确 `success("提示", value)` 或 `<T>success(value)` 或包 DTO |
| 字段语义不清 | data 放 URL string；message 放堆栈 | message=用户提示；data=业务数据；code=业务状态码 |
| 空值不一致 | 时返 null 时返 `new VO()` | 单对象 `null`；列表 `[]`；分页 `{list:[], total:0}` |
| HTTP/业务码混淆 | 业务失败 `throw new RuntimeException` → HTTP 500 | 业务失败 HTTP 200 + 业务 code 4xx；只有代码 bug 才 500 |
| 产物缺字段静默 | 缺 `mchId/transactionId` 时空字符串兜底，Excel 能生成微信拒收 | 生成前预校验，缺失列出业务 ID（订单号）并抛 BusinessException 整体失败 |
| 业务错用框架异常 | `throw new IllegalArgumentException("分类不存在")` → 500 + 堆栈 | `throw new BusinessException("分类不存在")` → 200 + code + 友好 message |

## 响应字段语义

| 字段 | 用途 | 示例 |
|------|------|------|
| `code` | 业务状态码 | 200/400/500 |
| `message` | 用户可读提示 | "上传成功"、"参数错误" |
| `data` | 业务数据 | `{"url":"..."}` / `[...]` |

## 异常类型对照

| 场景 | 抛什么 | HTTP |
|------|--------|------|
| 业务规则不满足 | `BusinessException` | 200 + code 4xx |
| 参数格式错误 | `BusinessException` 或 `@Valid` 触发 | 200 + code 400 |
| 资源不存在 | `BusinessException` / `NotFoundException` | 200 + code 404 |
| 无权限 | `AccessDeniedException` (Security 处理) | 403 |
| 未认证 | `AuthenticationException` (Security 处理) | 401 |
| 代码 bug | `IllegalStateException` / `AssertionError` 冒泡 | 500（应告警） |

**核心**：业务可预期错 → `BusinessException`；代码 bug → 让框架异常冒泡告警。

## 下游产物必填字段三层次（生成前一次画全）

| 层次 | 含义 | 例子 |
|------|------|------|
| 业务字段 | 每条记录自身必填 | 订单号、金额、状态 |
| 依赖配置 | 整个产物所需全局配置 | `mchId`、API 凭证、模板 ID |
| 外键关联 | 必须关联的其他实体 | 支付记录（交易号非空）、物流单（公司+单号都在） |

**必填判断依据**来自下游消费方文档（微信开放平台/对账规范/第三方 API spec），不是源数据方便填。

## 嗅探信号

- Service 里 `throw new IllegalArgumentException(...)` 或 `throw new RuntimeException(...)` 包业务错
- `orElseThrow(() -> new IllegalArgumentException(...))` 表达"找不到资源"
- 导出/对账文件代码用 `""` / `null` / `0` 兜底缺失字段
- 业务失败返回 HTTP 500（应 200 + code 4xx）
- `data` 字段放了 String / 错误信息混进 `message` / 列表返回 `null`
