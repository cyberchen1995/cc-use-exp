---
paths:
  - "**/*.vue"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.ts"
  - "**/*.js"
  - "**/*.css"
  - "**/*.scss"
---
# 前端开发规范（补充）

> 补充 GEMINI.md 和 frontend-safety skill 未覆盖的前端规范。
> UI 风格约束见 GEMINI.md，布局/覆盖层规范见 skills/frontend-safety/。

---

## 1. 状态管理（Pinia）

### Store 定义
使用 Composition API 风格定义 Store，保持响应性。

---

## 2. API 请求与数据一致性规范

### 请求对齐深度要求 (Deep Alignment)
- **拦截器感知**：定义 API 前必须读取 `request.ts` 确认响应解包逻辑。
- **泛型对齐**：`Promise<T>` 必须与解包后的真实 JSON 100% 对齐。
- **工具链补齐**：缺少 `PATCH/DELETE` 封装时，必须先补全工具类，严禁使用 `(request as any)`。

---

## 3. TypeScript 与 交互状态
- **DTO 定义**：严禁大范围使用 `any`。
- **UX 标准**：必须处理 `loading` (n-spin), `empty` (n-empty), `error` (n-result), `submitting` (loading 属性)。

---

## 4. 严格模式与变量约束 (Strict Mode)

> 默认所有项目均已开启 TypeScript 严格模式（如 `noUnusedLocals`）。

- **严禁无用变量**：在编写 Vue 模板的 `v-for` 循环时，如果循环体内不使用 `index`，**绝对禁止**声明 `(item, index)`，必须直接写为 `item in list`。
- **严禁无用导入**：在 `<script setup>` 中，代码重构或删减后，必须同步清理未使用的 `import` 语句和局部变量。

---

> 📋 本回复遵循：`frontend-style` - [章节]
