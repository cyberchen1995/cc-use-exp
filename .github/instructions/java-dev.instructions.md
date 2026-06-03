---
applyTo: "**"
---

# Java 开发规范

> 完整规范见 `.claude/skills/java-dev/`，本文件是 Copilot 仓库级精简版。

参考来源：Google Java Style Guide、阿里巴巴 Java 开发手册。

## 命名约定速记

| 类型 | 规则 | 示例 |
|------|------|------|
| 包名 | 全小写域名反转 | `com.example.project` |
| 类名 | 大驼峰名词 | `UserService`, `HttpClient` |
| 方法名 | 小驼峰动词开头 | `findById`, `isValid` |
| 常量 | 全大写下划线 | `MAX_RETRY_COUNT` |
| 布尔返回 | is/has/can 前缀 | `isActive()` |

## 核心规范速记

| 项 | 规则 |
|----|------|
| DTO/VO | 一律 Lombok `@Data`（不可变用 `@Value`），禁止手写 getter/setter；Entity 慎用 `@Data` |
| 注入方式 | 构造函数注入（`@RequiredArgsConstructor`），不用 `@Autowired` 字段注入 |
| 批量查询 | `IN_BATCH_SIZE=500` 分批，超过分批合并 |
| N+1 防范 | 循环内禁止 `repo.findById/exists/count`；改为外部批量 IN + Map 查找 |
| 并发安全 | 禁止 read-modify-write；用原子 SQL `UPDATE SET x = x + :d` 或 `@Version` 乐观锁；唯一索引兜底 |
| 异常处理 | 捕获具体异常 + 加上下文，禁止 `catch (Exception)` + `e.printStackTrace()` |
| 资源释放 | 必须 try-with-resources |
| 空值 | `Optional` + `Objects.requireNonNull(x, "msg")` |
| 并发 | 用 `ExecutorService` / `CompletableFuture`，禁止 `new Thread().start()` |
| 日志 | 参数化 `log.info("user {}", id)`，禁止字符串拼接 |

## Spring Boot 高频陷阱

| 陷阱 | 规则 |
|------|------|
| self-invocation | `this.method()` 不走代理 → `@Transactional`/`@Async`/`@Cacheable` 失效；用 self-injection (`@Lazy` 注入自己) 或拆 Bean |
| `@Modifying` JPA | 必须在 `@Transactional` 中调用，否则抛 `Executing an update/delete query` |
| 循环依赖 | Spring Boot 3.x 默认禁止；拆 Service 时先提取共享工具类，避免子服务回调父服务 |
| 分页参数 | 全栈统一 0-based，Controller `defaultValue = "0"`，Service `PageRequest.of(page, size)` 不减 1 |
| Auth 降级 | optional-auth 路径遇无效 token 降级为匿名，不返回 401/403 |
| Bean 命名冲突 | `@Bean(name=X)` 不要和 `@Service class X` 的默认 bean name 撞车；**禁止用 `spring.main.allow-bean-definition-overriding=true` 掩盖** |

## 输入校验

| 字段类型 | 必须注解 |
|---------|---------|
| quantity 数量 | `@NotNull @Min(1)` 防 0/负数 |
| amount/price 金额 | `@NotNull @Positive` 或 `@DecimalMin("0.01")` |
| 分页 size | `@Min(1) @Max(100)` 防 size=999999 |
| 分页 page | `@Min(1)` |
| RequestBody | 必须 `@Valid` |

## 其他高频

- 第三方 API HTTP 客户端：避免 RestTemplate 默认（HttpURLConnection）调微信/支付宝（CDN 兼容性 412/403）；用 `java.net.http.HttpClient` 或 Apache HttpClient
- Native SQL 别名避开 MySQL 保留字：`year_month`/`order`/`status`/`rank` 等用短别名 `ym`/`cnt`

## 嗅探信号

- 类成员变量用 `@Autowired` 字段注入而非构造函数
- service 类内 `this.someTxMethod()` 调用带 `@Transactional` 的方法
- 出现 `Executing an update/delete query` 错误 → 先排查 self-invocation
- 启动报 `BeanDefinitionStoreException` / `no qualifying bean of type` → 优先排查同名 Bean
- application.properties 出现 `allow-bean-definition-overriding=true` → 必须移除
