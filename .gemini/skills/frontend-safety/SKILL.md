---
name: frontend-safety
description: 前端修改安全约束。当用户修改 Vue/React 组件、调整页面布局、创建覆盖层/蒙版组件时激活。提供数据绑定保护、布局一致性规范、覆盖层定位规范。
---

# 前端修改安全约束

修改 Vue/React 文件时，必须遵守以下规则，防止破坏已有功能。

## 绝对禁止修改

| 类型 | 说明 | 示例 |
|------|------|------|
| 数据绑定 | v-model / v-bind 的字段名 | `v-model="form.username"` |
| Props | props 定义和传递的属性名 | `:user-id="userId"` |
| 事件 | emit 事件名和 @ 绑定 | `@click="handleSubmit"` |
| 响应式变量 | ref / reactive 变量名 | `const loading = ref(false)` |
| API 调用 | 接口路径、参数、响应处理 | `api.getUser(id)` |
| 类型定义 | TypeScript interface/type | `interface User { ... }` |
| 函数名 | 已有的方法和函数名 | `function handleSubmit()` |

## 允许修改

| 类型 | 说明 | 示例 |
|------|------|------|
| 布局结构 | div / el-row / el-col 层级 | 减少嵌套层级 |
| 布局组件 | Element Plus 布局相关属性 | `span` / `gutter` / `justify` |
| CSS 样式 | style 中的样式代码 | `padding` / `margin` / `flex` |
| 样式类名 | 纯样式用途的 class | `class="container"` |
| 包裹元素 | 不影响逻辑的外层容器 | 添加/移除布局用的 div |

---

# 1. 布局稳定性规范 (Layout Stability)

解决“按钮跳动”、“渲染闪烁”和“响应式错位”问题。

- **显式宽度锚定**：在使用 Flex 布局（`display: flex`）的 Header 或操作栏中，必须显式设置 `width: 100%`。
- **强制推向边缘**：当需要将操作按钮（如“新建”）锁定在右侧时，应为左侧标题区设置 `flex: 1`。严禁仅依赖 `justify-content: space-between`，因为容器宽度计算偏差会导致按钮位置跳动。
- **全局边缘对齐 (Page Padding)**：所有内部页面必须拉齐边缘间距。统一依赖最外层 Layout 的 `--page-padding`（通常为 24px）。禁止在子页面内部设置 `max-width` 或 `margin: 0 auto`，防止侧边栏收起时内容产生横向跳变。

---

# 2. UI 审美与组件覆盖规范

解决“图标不居中”、“样式脱靶”和“视觉补丁感”问题。

- **选择器精准覆盖 (Scoped CSS)**：修改 Element Plus 等第三方组件时，必须确认父子 class 的关系。
  - **并列关系**：`.menu.el-menu--collapse`（中间无空格）用于修改当前节点。
  - **嵌套关系**：`.menu :deep(.el-menu-item)` 用于穿透修改子节点。
- **绝对居中算法**：在收起状态（Collapse）的菜单中，必须彻底剥离默认的 `padding` 和 `margin` 偏移。
  - **公式**：容器（如 64px） - 选中块（如 44px） = 左右留白各 10px。使用 `margin: 4px auto` 强制居中。
- **视觉降噪原则**：
  - **冗余隐藏**：当侧边栏收起且支持“点击 Logo 展开”时，应主动隐藏边缘的悬浮折叠按钮，避免视觉重叠。
  - **呼吸感**：在窄空间（如 64px 侧边栏）内，背景块不宜过大（推荐 40px-44px），确保存留足够的“呼吸空间”。

---

# 3. 工程执行逻辑与代码完整性

解决“语法错误（TS1128）”和“代码片段损坏”问题。

- **严禁占位符**：在执行 `replace` 操作时，**禁止**在 `new_string` 中使用 `...` 或 `// ... rest of code`。必须提供语法完整的代码片段。
- **闭合匹配校验**：修改大型组合式函数（Composables）或复杂的嵌套组件时，必须严格检查花括号 `{}` 和括号 `()` 的配对。替换后必须确认 `export` 语句未被意外删除。
- **写入安全**：多行代码写入强制使用 `write_file` 工具而非 `cat <<EOF`。

---

# 4. UI 诊断工作流

遇到 UI 不美观、布局异常或用户反馈“很丑”时，必须遵循以下步骤：

1. **结构分析**：检查 DOM 结构，确认是否存在残留的 `padding`、`margin` 或 `width` 计算偏差。
2. **原因定位**：给出技术结论（如：选择器脱靶、Flex 宽度未撑满、响应式断点冲突）。
3. **方案提案**：
   - **方案 A (极简)**：隐藏冲突元素，优化空间比例。
   - **方案 B (微调)**：调整定位参数，避让视觉密集区。
4. **精准应用**：获取确认后，执行不破坏历史 DOM 结构和业务逻辑的样式更新。

---

# 修改前检查清单 (Checklist)

修改前端组件前，必须确认：
- [ ] 是否存在 redundant 的旧脚本块（确保只有一个 `<script setup>`）。
- [ ] 异步数据（如 `list.value`）是否有空值保护（`?.` 或 `|| []`）。
- [ ] Element Plus 属性是否已升级（如 `el-radio` 使用 `value` 而非 `label`）。
- [ ] 所有的 `import` 图标和组件是否在模板中被实际使用。
- [ ] 替换的代码片段是否语法完整且不含占位符。
