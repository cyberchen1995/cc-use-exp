---
name: refactor-safety
description: 当用户要求重构代码（提取组件、合并重复逻辑、重命名变量、优化结构）时触发。提供重构安全检查清单，防止丢失原始上下文。
---

# 重构安全规范

## 触发场景

- 用户说"重构"、"提取"、"合并"、"优化结构"、"简化代码"
- 涉及表格列、数据结构、配置项的修改
- 合并条件分支（if/else/switch）

---

## 重构流程

### 1. 读取原始代码（必须）

**不要凭记忆或推测重构**，必须完整读取原始代码：

```bash
# 读取完整文件
Read: file_path="src/views/Order.vue"

# 如果是条件分支，读取所有分支的代码
Grep: pattern="if.*健康云" -A 50 -B 5
Grep: pattern="else" -A 50 -B 5
```

**常见错误**：
- ❌ 只读一个分支，推测其他分支
- ❌ 凭记忆重构表格列
- ❌ 假设两个条件分支结构相似

---

### 2. 制作对比清单

#### 表格重构示例

**原始代码（健康云租户）**：
```
列1: 订单编号
列2: 订单日期
列3: 材料名称
列4: 材料数量
列5: 单价
列6: 金额
```

**原始代码（非健康云租户）**：
```
列1: 订单编号
列2: 创建时间
列3: 材料名称
列4: 单价
列5: 金额
```

**对比清单**：

| 健康云 | 非健康云 | 状态 |
|--------|---------|------|
| 订单编号 | 订单编号 | ✅ 一致 |
| 订单日期 | 创建时间 | ⚠️ 名称不同 |
| 材料名称 | 材料名称 | ✅ 一致 |
| 材料数量 | - | ❌ 非健康云无此列 |
| 单价 | 单价 | ✅ 一致 |
| 金额 | 金额 | ✅ 一致 |

#### 数据结构重构示例

**原始接口**：
```typescript
interface Order {
  id: string
  date: string
  items: Item[]
  total: number
}
```

**重构后接口**：
```typescript
interface Order {
  id: string
  createdAt: string  // 重命名：date → createdAt
  items: Item[]
  total: number
}
```

**对比清单**：
- ✅ 字段数量一致（4 个）
- ⚠️ 字段重命名：date → createdAt
- ✅ 字段顺序一致
- ✅ 字段类型一致

---

### 3. 验证检查点

重构完成后，必须逐项检查：

#### 表格重构检查

- [ ] 列数一致（原始 6 列 → 重构后 6 列）
- [ ] 列顺序一致（第 1 列是订单编号，第 2 列是日期...）
- [ ] 列名一致（或有明确映射关系）
- [ ] 没有遗漏列
- [ ] 没有多余列

#### 条件分支检查

- [ ] 所有 if/else/switch 分支都已处理
- [ ] 每个分支的逻辑与原始代码一致
- [ ] 没有假设某个分支与另一个分支相似

#### 数据结构检查

- [ ] 字段数量一致
- [ ] 字段类型一致
- [ ] 字段顺序一致（如果顺序重要）
- [ ] 没有遗漏字段

---

### 4. 输出格式

重构完成后，输出对比清单：

```markdown
## 重构对比

### 原始结构（健康云租户）
- 列1: 订单编号
- 列2: 订单日期
- 列3: 材料名称
- 列4: 材料数量
- 列5: 单价
- 列6: 金额

### 原始结构（非健康云租户）
- 列1: 订单编号
- 列2: 创建时间
- 列3: 材料名称
- 列4: 单价
- 列5: 金额

### 重构后结构
- 列1: 订单编号
- 列2: 日期（健康云显示"订单日期"，非健康云显示"创建时间"）
- 列3: 材料名称
- 列4: 材料数量（仅健康云显示）
- 列5: 单价
- 列6: 金额

### 变更说明
- 合并：订单日期 + 创建时间 → 日期（条件显示）
- 条件显示：材料数量仅在健康云租户显示
- 删除：无
- 新增：无
```

---

## 常见陷阱

### 1. 假设驱动重构

**错误示例**：
```javascript
// 只读了健康云租户的代码
if (isHealthCloud) {
  columns = ['订单编号', '订单日期', '材料名称', '材料数量', '单价', '金额']
}

// ❌ 假设非健康云租户只是列名不同
else {
  columns = ['订单编号', '创建时间', '材料名称', '材料数量', '单价', '金额']
}
```

**正确做法**：
```javascript
// 读取两个分支的原始代码
if (isHealthCloud) {
  columns = ['订单编号', '订单日期', '材料名称', '材料数量', '单价', '金额']
} else {
  // 非健康云租户没有"材料数量"列
  columns = ['订单编号', '创建时间', '材料名称', '单价', '金额']
}
```

### 2. 记忆重构

**错误示例**：
```javascript
// ❌ 凭记忆重构，没有读取原始代码
const columns = ['订单编号', '材料名称', '单价', '金额', '订单日期']
```

**正确做法**：
```javascript
// ✅ 读取原始代码，确认列顺序
Read: file_path="src/views/Order.vue"
// 原始代码：['订单编号', '订单日期', '材料名称', '材料数量', '单价', '金额']
const columns = ['订单编号', '订单日期', '材料名称', '材料数量', '单价', '金额']
```

### 3. 跳过验证

**错误示例**：
```javascript
// 重构完成，直接提交
// ❌ 没有验证列数、列顺序、列名
```

**正确做法**：
```markdown
## 验证清单
- [x] 列数一致：原始 6 列 → 重构后 6 列
- [x] 列顺序一致：订单编号、订单日期、材料名称、材料数量、单价、金额
- [x] 列名一致：完全一致
- [x] 没有遗漏列
- [x] 没有多余列
```

### 5. 提取子模块导致循环依赖

**场景**：从大服务/组件拆分子模块时，子模块需要回调父模块的方法

**错误示例**：
```java
// ❌ ReportService 拆分出 ReportInvoiceService
// 但 ReportInvoiceService 又需要调用 ReportService.resolveTenantIds()
@Service
@RequiredArgsConstructor
public class ReportInvoiceService {
    private final ReportService reportService; // 循环依赖！
}
```

**正确做法（按优先级）**：
```java
// ✅ 方案1：提取公共方法到独立工具类（推荐）
@Component
public class TenantHelper {
    public List<Long> resolveTenantIds(Long tenantId) { ... }
}

// ✅ 方案2：@Lazy 字段注入（应急）
@Service
public class ReportInvoiceService {
    @Autowired @Lazy
    private ReportService reportService;
}

// ✅ 方案3：函数式回调
public void process(Function<Long, List<Long>> tenantResolver) { ... }
```

**检查清单**：
- [ ] 画依赖图：拆分后是否存在 A → B → A 的循环？
- [ ] 子模块回调父模块的方法是否为纯工具方法？是 → 提取到独立类
- [ ] 依赖方向是否单向：父 → 子（禁止子 → 父）
- [ ] Spring Boot 3.x 默认禁止构造器循环依赖

**不仅限于 Spring**：
- Go：包级循环引用（编译错误）→ 提取公共包
- Vue：组件循环引用 → 异步组件或提取公共逻辑到 composables
- TypeScript：模块循环引用 → 提取公共模块

---

### 4. 字段名推测重构（极其隐蔽）

**场景**：类型定义中有多个相似字段，重构时选错了

**错误示例**：
```typescript
// 类型定义
interface InvoiceHistory {
  changedAt?: string  // 可选字段
  createdAt: string   // 必填字段
  changeType?: string // 错误字段
  operationType: string // 正确字段
}

// ❌ 根据类型定义推测，选择了可选字段
dataIndex: 'changedAt'  // 可能为 undefined → Invalid Date
dataIndex: 'changeType' // 字段不存在 → 显示为空

// ❌ 枚举映射不完整
typeMap: {
  CREATE: { text: '创建', color: 'green' },
  UPDATE: { text: '更新', color: 'blue' },
  DELETE: { text: '删除', color: 'red' },
  // 遗漏了 UPLOAD、OCR_START、OCR_SUCCESS 等 7 个类型
}
```

**正确做法**：
```typescript
// ✅ 查看原始代码的实际使用
git show HEAD~1:src/components/InvoiceHistoryTab.tsx

// 原始代码使用 createdAt（必填）和 operationType（正确）
dataIndex: 'createdAt'
dataIndex: 'operationType'

// 原始代码有 10 个枚举类型
typeMap: {
  UPLOAD: { text: '上传发票', color: 'blue' },
  OCR_START: { text: '开始OCR', color: 'cyan' },
  OCR_SUCCESS: { text: 'OCR成功', color: 'green' },
  OCR_FAILED: { text: 'OCR失败', color: 'red' },
  OCR_RETRY: { text: '重试OCR', color: 'orange' },
  MANUAL_EDIT: { text: '手动编辑', color: 'orange' },
  LINK_ORDER: { text: '关联订单', color: 'purple' },
  UNLINK_ORDER: { text: '取消关联', color: 'magenta' },
  FIELD_CONFIRM: { text: '确认字段', color: 'green' },
  DELETE: { text: '删除发票', color: 'red' },
}

// ✅ 防御性编程
render: (val: string) => {
  if (!val) return '-'
  try {
    return new Date(val).toLocaleString('zh-CN')
  } catch {
    return val
  }
}
```

**检查清单**：
- [ ] 查看原始代码的实际字段名（不要只看类型定义）
- [ ] 优先使用必填字段，避免可选字段
- [ ] 枚举映射必须完整（对照原始代码逐个检查）
- [ ] 运行时测试（TypeScript 无法检测字段名错误）
- [ ] 防御性编程（if (!val) return '-'）

**为什么 TypeScript 无法检测**：
```typescript
// ❌ TypeScript 不会报错（changedAt 在类型定义中存在）
dataIndex: 'changedAt'  // 类型检查通过
render: (val: string) => new Date(val).toLocaleString()
// 运行时：val 为 undefined → Invalid Date
```

---

## 规则溯源

```
> 📋 本回复遵循：`refactor-safety` - [章节]
```
