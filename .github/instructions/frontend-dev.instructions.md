---
applyTo: "**"
---

# 前端开发规范

> 完整规范见 `.claude/skills/frontend-dev/`，本文件是 Copilot 仓库级精简版。

参考来源：Vue 官方风格指南、Element Plus 最佳实践。

## UI 风格红线

- ❌ 蓝紫色霓虹渐变、发光描边、玻璃拟态
- ❌ 大面积渐变、过多装饰性几何图形、赛博/暗黑科技/AI 风格 UI
- ❌ UI 文案中使用 emoji
- ✅ 后台系统默认黑白灰为主 + 1 主色点缀；用组件库默认主题

## 技术栈

| 层级 | Vue（首选） | React（备选） |
|------|------------|--------------|
| 框架 | Vue 3 + TS | React 18 + TS |
| 构建 | Vite | Vite |
| 路由 | Vue Router 4 | React Router 6 |
| 状态 | Pinia | Zustand |
| UI 库 | Element Plus | Ant Design |

## 核心规范速记

| 项 | 规则 |
|----|------|
| 命名 | 组件 PascalCase.vue；composable `useXxx`；store `useXxxStore` |
| 交互状态 | loading/empty/error/disabled/submitting 5 态必须处理 |
| API 类型安全 | `get<T>(url)` 泛型，禁止 `as any` 绕过 |
| 样式管理 | `.vue/.tsx` 内 style/CSS-in-JS ≤ 20 行；共享样式抽到 `src/assets/styles/` |
| 请求体完整性 | UI 表单字段必须全传 API；用 TS interface 约束请求体 |
| API 错误处理 | 成功 + 失败都处理（`if code !== 200` 必须 `message.error`）；`try/catch` 网络异常 |
| 类型复用 | `PageResponse`/`BaseResult` 统一放 `@/types/common.ts`，禁止多文件重复定义 |
| 性能 | 大列表虚拟滚动；路由 `() => import()` 懒加载；`computed` 缓存；大数据用 `shallowRef` |

## React / antd 5 大陷阱

| 陷阱 | 错误 | 正确 |
|------|------|------|
| controlled vs uncontrolled 误用 | `<Table pagination={{ pageSize: 20 }}>` 写死 → 切换无效 | 要么 `defaultPageSize` (uncontrolled)，要么 `pageSize + onShowSizeChange` 全套 |
| Tree defaultExpandAll 被重置 | setState 后 Tree 重新渲染弹开收起的节点 | controlled `expandedKeys + onExpand` + `initialExpandDoneRef` 守卫只初次填充 |
| useEffect 双轮询冲突 | 一个 setTimeout 递归 + 一个 status 依赖 setInterval | 只能一套：mount effect 只初次 fetch，polling 由 status effect 接管 |
| 跨组件状态同步太重 | Redux/Zustand 引入成本高，prop drilling 烦 | revision counter：父维护 `useState(0)`，bump 时 +1，子 `useEffect([counter])` 监听 |
| 同步接口超时前端硬扛 | 在前端加 timeout 重试 | 让后端改 trigger + polling（见 async-task-pattern），前端按钮 disabled + 进度条 |

## 嗅探信号

- `as any` / `as unknown as` 绕过类型 → 改泛型或断言到具体类型
- antd `<Table pagination={{ pageSize: N }}>` 没配对 `onShowSizeChange` → controlled/uncontrolled 误用
- `<Tree defaultExpandAll>` 出现在会 setState 的组件 → 必爆"展开被重置"
- 同一组件内两个 useEffect 都做 polling → 定时器冲突
- API 调用 `.then(res => list = res.data)` 没处理 `res.code !== 200` 或网络异常
- 大段 CSS-in-JS（> 20 行）或 `<style>` 块（> 20 行）→ 抽到 assets/styles
