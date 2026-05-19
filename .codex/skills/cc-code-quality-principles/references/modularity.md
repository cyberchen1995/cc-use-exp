# 模块化原则详细案例

> 配合 [SKILL.md](../SKILL.md) 使用。本文件提供原则 2、3、4 的详细案例与反例。

---

## 调用深度

### 衡量

调用栈深度 = 从入口到达最底层调用所需的函数跳转次数。

| 深度 | 评估 |
|------|------|
| 1-3 层 | ✅ 健康 |
| 4-5 层 | ⚠️ 可接受，需关注 |
| 6+ 层 | ❌ 坏味道，定位困难 |

### ❌ 反例：六层调用链

```go
// HTTP handler
func CreateOrder(c *gin.Context) {
    orderService.Create(...)
}

// Service A
func (s *OrderService) Create(...) {
    s.validator.Validate(...)
}

// Validator
func (v *OrderValidator) Validate(...) {
    v.userChecker.Check(...)
}

// User checker
func (c *UserChecker) Check(...) {
    c.permissionResolver.Resolve(...)
}

// Permission resolver
func (r *PermissionResolver) Resolve(...) {
    r.policyEngine.Evaluate(...)
}

// Policy engine
func (e *PolicyEngine) Evaluate(...) { ... }
```

**问题**：6 层栈，定位"权限不通过"需要进栈 6 次；任何中间层加日志都影响所有调用方。

### ✅ 正例：扁平化 + 边界统一

```go
// HTTP handler（边界层，统一异常包装）
func CreateOrder(c *gin.Context) {
    req := parseRequest(c)
    if err := req.Validate(); err != nil {  // 早期 return
        c.JSON(400, ErrorResp(err))
        return
    }

    order, err := orderService.Create(c.Request.Context(), req)
    if err != nil {
        c.JSON(500, ErrorResp(err))
        return
    }
    c.JSON(200, SuccessResp(order))
}

// Service（业务核心，2 层就到 DAO）
func (s *OrderService) Create(ctx context.Context, req CreateReq) (*Order, error) {
    if !s.userRepo.HasPermission(ctx, req.UserID, "order:create") {
        return nil, ErrPermissionDenied
    }
    return s.orderRepo.Insert(ctx, req.ToEntity())
}
```

**改善**：3 层调用，权限检查直接落到 Repo，无中间编排层。

### 改造手段

1. **提前 return**：用 guard clause 代替深嵌套，减少层次感
2. **合并适配器**：去掉只做转调用的"中间层" Service
3. **事件解耦**：跨模块协作走事件总线，不直接调用
4. **依赖反转**：通过接口注入打破长链

---

## 扇入扇出

### 衡量

- **扇出**（Fan-Out）：本方法直接调用的其他方法/模块数
- **扇入**（Fan-In）：本方法被多少处调用

| 指标 | 健康范围 |
|------|---------|
| 扇出 | ≤ 5 |
| 扇入 | 越高越好（说明复用价值大） |

### ❌ 反例：上帝服务（扇出 8）

```java
@Service
public class OrderService {
    @Autowired private UserService userService;
    @Autowired private CouponService couponService;
    @Autowired private PaymentService paymentService;
    @Autowired private StockService stockService;
    @Autowired private NotifyService notifyService;
    @Autowired private AuditService auditService;
    @Autowired private CacheService cacheService;
    @Autowired private MetricsService metricsService;

    public Order create(CreateOrderDTO dto) {
        // 在一个方法里串联 8 个 service
    }
}
```

**问题**：
- 任何一个 service 改动都可能炸这里
- 单元测试需要 mock 8 个依赖
- 难以拆分，难以复用

### ✅ 正例：拆分为编排 + 核心 + 适配器

```java
// 1. 核心业务（仅依赖 Repo 和领域服务，扇出 2）
@Service
public class OrderCoreService {
    @Autowired private OrderRepository orderRepo;
    @Autowired private StockChecker stockChecker;

    public Order create(OrderCreateCmd cmd) {
        stockChecker.assertAvailable(cmd.items());
        return orderRepo.save(Order.from(cmd));
    }
}

// 2. 编排器（明确表达"创建订单"的完整流程，扇出 4，但仅做编排）
@Service
public class OrderOrchestrator {
    @Autowired private OrderCoreService coreService;
    @Autowired private CouponService couponService;
    @Autowired private PaymentService paymentService;
    @Autowired private OrderEventPublisher publisher;

    @Transactional
    public Order placeOrder(CreateOrderDTO dto) {
        couponService.consume(dto.couponId(), dto.userId());
        Order order = coreService.create(dto.toCmd());
        paymentService.charge(order);
        publisher.published(order);  // 通知/审计/缓存通过事件解耦
        return order;
    }
}

// 3. 监听器（通过事件订阅，与核心解耦，扇出 1）
@Component
public class OrderEventListener {
    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        notifyService.send(event);
        auditService.record(event);
        metricsService.count(event);
    }
}
```

**改善**：核心扇出 2，编排扇出 4（含事件发布），通知/审计/指标走事件订阅，扇出可控。

### 改造手段

1. **抽取核心**：把纯业务核心抽出，只依赖最少模块
2. **事件化副作用**：通知、审计、缓存、指标通过事件订阅
3. **门面模式**：把多个相关 service 合并为一个 facade，调用方扇出降为 1

---

## 边界清晰（接口契约统一）

### 衡量

| 维度 | 检查项 |
|------|--------|
| 入参 | 类型/必填/默认值有明确定义？ |
| 出参 | 成功/失败包装统一？分页结构一致？ |
| 异常 | 错误码体系统一？还是混合抛异常/返 null？ |

### ❌ 反例：三种返回路径混用

```typescript
// Service A：成功返回 data，失败返 null
async function getUser(id: string): Promise<User | null> {
    const user = await db.user.findUnique({ where: { id } })
    return user
}

// Service B：成功返回 data，失败抛异常
async function getOrder(id: string): Promise<Order> {
    const order = await db.order.findUnique({ where: { id } })
    if (!order) throw new NotFoundError('order not found')
    return order
}

// Service C：自定义包装
async function getProduct(id: string): Promise<{ ok: boolean, data?: Product, error?: string }> {
    // ...
}
```

**问题**：调用方需要为每个 service 写不同的处理逻辑：

```typescript
const user = await getUser(id)
if (!user) { /* 处理 null */ }

try {
    const order = await getOrder(id)
} catch (e) { /* 处理异常 */ }

const result = await getProduct(id)
if (!result.ok) { /* 处理 ok 字段 */ }
```

### ✅ 正例：统一契约

```typescript
// 全项目统一响应类型
type Result<T> = { code: 0, data: T } | { code: number, message: string }

async function getUser(id: string): Promise<Result<User>> {
    const user = await db.user.findUnique({ where: { id } })
    if (!user) return { code: 404, message: 'user not found' }
    return { code: 0, data: user }
}

async function getOrder(id: string): Promise<Result<Order>> { /* 同样的包装 */ }
async function getProduct(id: string): Promise<Result<Product>> { /* 同样的包装 */ }

// 调用方处理逻辑统一
const result = await getUser(id)
if (result.code !== 0) {
    return handleError(result)
}
const user = result.data
```

### 改造手段

1. **统一响应包装**：项目级 `Result<T>` / `ApiResponse<T>` 类型
2. **边界异常拦截**：业务层抛异常 → middleware/interceptor 转统一格式
3. **早期 return**：用 guard clause 替代深嵌套，函数仍有多个 return 点但语义清晰
4. **分页结构统一**：`{ list, total, page, pageSize }` 等结构跨接口一致

---

## 速查总结

| 原则 | 红线 | 改造方向 |
|------|------|---------|
| 调用深度 | > 5 层 | 扁平化、事件解耦、合并适配器 |
| 扇出 | > 5 | 抽核心、事件化、门面 |
| 扇入 | 越多越好 | 抽工具/纯函数复用 |
| 边界清晰 | 多种返回路径 | 统一 Result 类型，边界拦截 |
