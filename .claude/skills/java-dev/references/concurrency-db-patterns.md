# 并发与数据库模式

> 解决 Race Condition、N+1 查询、原子更新等常见问题的标准模式。

---

## 1. 解决 Get-Or-Create 并发竞争

**场景**：高并发下检查记录是否存在，不存在则创建。
**反模式**：`check-then-act`（先 `findBy` 后 `save`），并发时会产生重复数据或异常。

### ✅ 推荐方案：唯一索引兜底 + 异常捕获

利用数据库唯一索引作为最后防线，代码层面捕获冲突异常。

```java
public Account getOrCreateAccount(Long userId) {
    // 1. 尝试直接查询
    return accountRepo.findByUserId(userId)
        .orElseGet(() -> {
            try {
                // 2. 并发关键点：可能多个线程同时进入此处
                Account newAccount = new Account(userId);
                return accountRepo.save(newAccount);
            } catch (DataIntegrityViolationException e) {
                // 3. 捕获唯一索引冲突，说明已被其他线程创建
                // 4. 重新查询（此时一定存在）
                return accountRepo.findByUserId(userId)
                    .orElseThrow(() -> new IllegalStateException("Account creation conflict handling failed", e));
            }
        });
}
```

---

## 2. N+1 查询防范

**场景**：在循环中调用 Repository 查询方法（如 `findById`, `countBy`）。
**反模式**：`items.forEach(item -> repo.findById(item.getId()))`。

### ✅ 推荐方案：循环外批量查询 + 内存匹配

将 N 次数据库交互合并为 1 次。

```java
public List<OrderDTO> calculatePoints(List<Order> orders) {
    // 1. 提取所有需要的 ID
    List<Long> userIds = orders.stream().map(Order::getUserId).distinct().collect(Collectors.toList());

    // 2. 批量查询（一次 DB 交互）
    Map<Long, Integer> userLevels = userRepo.findAllById(userIds).stream()
        .collect(Collectors.toMap(User::getId, User::getLevel));

    // 3. 内存匹配计算
    return orders.stream().map(order -> {
        Integer level = userLevels.getOrDefault(order.getUserId(), 1);
        return new OrderDTO(order, calculate(order, level));
    }).collect(Collectors.toList());
}
```

---

## 3. 原子更新（余额/库存扣减）

**场景**：扣减余额、库存等数值。
**反模式**：`read-modify-write`（先 `get`，内存计算，再 `set`），并发会导致丢失更新。

### ✅ 推荐方案：CAS 思想 SQL 更新

让数据库保证原子性，通过影响行数判断成功。

**Repository:**

```java
@Modifying
@Query("UPDATE Account a SET a.balance = a.balance - :amount WHERE a.id = :id AND a.balance >= :amount")
int deductBalance(@Param("id") Long id, @Param("amount") BigDecimal amount);
```

**Service:**

```java
@Transactional
public void pay(Long accountId, BigDecimal amount) {
    int updatedRows = accountRepo.deductBalance(accountId, amount);
    if (updatedRows == 0) {
        throw new BusinessException("余额不足或账户不存在");
    }
}
```

---

## 4. SQL 聚合优化（多重 Count）

**场景**：需要统计多个不同条件的总数（如：总订单数、逾期订单数）。
**反模式**：执行多条 SQL (`countByStatus`, `countByOverdue`)。

### ✅ 推荐方案：CASE WHEN 聚合

一条 SQL 计算所有指标。

**Repository:**

```java
@Query("SELECT new com.example.dto.StatsDTO(" +
       "  COUNT(o), " +
       "  SUM(CASE WHEN o.status = 'PAID' THEN 1 ELSE 0 END), " +
       "  SUM(CASE WHEN o.dueDate < CURRENT_DATE AND o.status != 'PAID' THEN 1 ELSE 0 END) " +
       ") FROM Order o WHERE o.tenantId = :tenantId")
StatsDTO getStats(@Param("tenantId") Long tenantId);
```
