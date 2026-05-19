# 可预测性详细案例

> 配合 [SKILL.md](../SKILL.md) 使用。本文件提供原则 6（功能可预测）的详细案例与反例。

可预测性 = 给定相同的输入和环境，函数总是返回相同的输出，并且副作用可控。

---

## 幂等性

### 定义

对**写操作**：同一请求执行 N 次，结果与执行 1 次完全等价（不重复扣款、不重复发货、不重复发通知）。

### ❌ 反例：HTTP 重试导致重复扣款

```typescript
async function chargeOrder(orderId: string) {
    const order = await db.order.findUnique({ where: { id: orderId } })
    if (order.status !== 'PENDING') {
        throw new Error('order not in pending status')
    }

    await paymentGateway.charge(order.amount)
    await db.order.update({
        where: { id: orderId },
        data: { status: 'PAID' }
    })
}
```

**问题**：
- 客户端超时重试 → 同时两个请求进入
- 两个请求都看到 `status=PENDING`，都调用 `paymentGateway.charge()`
- 扣两次款，但最终状态仍是 `PAID`，难以察觉

### ✅ 正例：幂等键 + 数据库唯一约束

```typescript
async function chargeOrder(orderId: string, idempotencyKey: string) {
    // 1. 幂等键先行写入（数据库唯一约束）
    try {
        await db.paymentLog.create({
            data: { orderId, idempotencyKey, status: 'PROCESSING' }
        })
    } catch (e) {
        if (isUniqueViolation(e)) {
            // 重复请求，返回已有结果
            return await db.paymentLog.findUnique({ where: { idempotencyKey } })
        }
        throw e
    }

    // 2. 实际扣款（带网关侧幂等键）
    const result = await paymentGateway.charge({
        amount: order.amount,
        idempotencyKey  // 网关也用同一个 key 去重
    })

    // 3. 更新日志
    await db.paymentLog.update({
        where: { idempotencyKey },
        data: { status: 'SUCCESS', txId: result.txId }
    })

    return result
}
```

### 幂等键策略

| 策略 | 适用场景 | 示例 |
|------|---------|------|
| 客户端生成 UUID | API 调用 | `idempotency_key: uuid-v4` |
| 业务唯一标识 | 订单创建 | `out_trade_no` |
| 内容 hash | 消息去重 | `sha256(payload)` |
| 时间窗口 + 业务 key | 高频操作 | `userId + minute_bucket` |

### 数据库层

写操作的幂等性必须有**数据库层兜底**：
- 唯一索引（避免应用层判断失效）
- `INSERT ... ON CONFLICT DO NOTHING`（PostgreSQL）
- `INSERT IGNORE`（MySQL）

---

## 副作用控制

### 定义

副作用 = 函数除返回值外，对外界产生的任何变化（IO、DB、网络、全局变量、文件、随机数、时间）。

### 原则

1. **核心业务纯函数化**：能不依赖 IO 就不依赖
2. **副作用集中边界**：所有 IO 集中在 handler / repository / adapter
3. **显式注入**：不要在函数内部 `new SomeClient()`，通过参数注入

### ❌ 反例：业务函数内藏 IO

```python
def calculate_discount(order):
    # 业务计算
    base_discount = order.amount * 0.1

    # 副作用 1：访问 DB
    user = db.query(User).filter_by(id=order.user_id).first()
    if user.is_vip:
        base_discount *= 1.5

    # 副作用 2：访问 Redis
    promo_active = redis.get('promo:active')
    if promo_active == '1':
        base_discount += 10

    # 副作用 3：调用外部 API
    coupon_info = http.get(f'/coupons/{order.coupon_id}').json()
    if coupon_info['valid']:
        base_discount += coupon_info['value']

    return base_discount
```

**问题**：
- 单元测试需要 mock 3 个外部依赖
- 难以复现 bug（依赖 DB/Redis/HTTP 状态）
- 性能问题：每次计算都触发 IO

### ✅ 正例：纯函数 + 边界注入

```python
# 纯函数（核心计算）
def calculate_discount(
    base_amount: Decimal,
    is_vip: bool,
    promo_active: bool,
    coupon_value: Decimal,
) -> Decimal:
    discount = base_amount * Decimal('0.1')
    if is_vip:
        discount *= Decimal('1.5')
    if promo_active:
        discount += Decimal('10')
    discount += coupon_value
    return discount

# 边界层（聚合 IO）
def get_order_discount(order_id: int) -> Decimal:
    order = order_repo.find(order_id)
    user = user_repo.find(order.user_id)
    promo_active = promo_cache.is_active()
    coupon = coupon_api.fetch(order.coupon_id)

    return calculate_discount(
        base_amount=order.amount,
        is_vip=user.is_vip,
        promo_active=promo_active,
        coupon_value=coupon.value if coupon.valid else Decimal('0'),
    )
```

**改善**：核心计算纯函数化，可独立测试；IO 集中在 `get_order_discount`。

---

## 时间与隐式依赖

### ❌ 反例：业务依赖系统时区

```go
func IsBusinessHours() bool {
    now := time.Now()
    hour := now.Hour()
    return hour >= 9 && hour < 18
}
```

**问题**：
- 部署到不同时区机器，行为不一致
- 单元测试无法稳定（依赖 `time.Now()`）
- 跨夜定时任务可能跑两次或跑零次

### ✅ 正例：时间作为参数 + UTC 内部表达

```go
func IsBusinessHours(now time.Time, tz *time.Location) bool {
    local := now.In(tz)
    hour := local.Hour()
    return hour >= 9 && hour < 18
}

// 调用方注入
tz, _ := time.LoadLocation("Asia/Shanghai")
ok := IsBusinessHours(time.Now(), tz)
```

**改善**：可测试（注入 fixed time），时区明确（注入 location）。

> 详见 `time-zone-safety` skill。

### 其他隐式依赖

| 隐式依赖 | 注入方式 |
|---------|---------|
| 当前时间 | 函数参数 `now time.Time` |
| 随机数 | 注入 `rng *rand.Rand` |
| UUID | 注入 ID 生成器接口 |
| 配置 | 显式 config 对象，不读全局 |
| 当前用户 | 显式 context.Context |

---

## 可测试性

### 检查清单

- [ ] 核心业务能不能在**不启动整个应用**的情况下跑通测试？
- [ ] 是否依赖了**外部不可控的状态**（真实 DB/Redis/HTTP）？
- [ ] 给定**固定输入**，是否能得到**确定输出**？
- [ ] 测试是否能在 **CI 跑 100 次都通过**（无 flaky）？

### ❌ 反例：测试需要真实 Redis

```java
@Test
void testRateLimit() {
    // 必须有真实 Redis
    rateLimiter.acquire("user-1");
    rateLimiter.acquire("user-1");
    rateLimiter.acquire("user-1");
    assertThrows(RateLimitExceededException.class, () -> {
        rateLimiter.acquire("user-1");
    });
}
```

**问题**：CI 环境必须装 Redis；并发跑测试会污染状态。

### ✅ 正例：限流逻辑纯函数化

```java
// 纯计算
public class TokenBucket {
    public Result tryAcquire(BucketState state, long now, int tokens) {
        // 纯函数：根据当前状态和时间，计算是否放行
        BucketState newState = refill(state, now);
        if (newState.tokens >= tokens) {
            return Result.ok(newState.consume(tokens));
        }
        return Result.denied(newState);
    }
}

// 测试无需任何外部依赖
@Test
void testRateLimit() {
    BucketState state = BucketState.of(capacity=3, refillRate=1);
    long now = 0;

    state = bucket.tryAcquire(state, now, 1).getNewState();
    state = bucket.tryAcquire(state, now, 1).getNewState();
    state = bucket.tryAcquire(state, now, 1).getNewState();

    Result fourth = bucket.tryAcquire(state, now, 1);
    assertFalse(fourth.isAllowed());
}
```

---

## 速查总结

| 维度 | 红线 | 改造方向 |
|------|------|---------|
| 幂等性 | 写操作无幂等键 | 幂等键 + DB 唯一约束 |
| 副作用 | 核心业务函数内含 IO | 纯函数 + 边界注入 |
| 时间 | 业务直接调 time.Now() | 时间作为参数 |
| 测试 | 单测依赖真实外部服务 | 抽离纯函数核心 |

---

## 相关 skill

- `time-zone-safety`：时间处理具体规范
- `redis-safety`：Redis 幂等键的具体写法
- `query-performance-safety`：N+1 等性能陷阱
- `payment-callback-safety`：支付回调幂等性的专项
