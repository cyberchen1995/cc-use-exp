---
name: cc-frontend-dev
description: Vue、React、TypeScript、CSS 与前端 UI 规范，适用于组件边界、样式、可访问性、前端测试，以及约束异常处理、容灾状态和抽象层级；不负责 review、debug 或运维流程。
---

# CC Frontend Dev

在编辑前端代码时使用本技能，重点处理组件边界、UI 一致性、TypeScript、CSS 和可访问性。

不要用于：

- 正式 review 或 fix/debug 工作流
- 运维风险判断
- 与前端无关的后端语言细节

## 核心规则

- 保持与现有设计系统和项目视觉语言一致。
- 前端实现优先直接、可读、贴近组件上下文。
- 组件拆分按职责和复用边界，而不是机械按行数。
- 只在真实不稳定边界处理异常，例如请求、`JSON.parse`、Storage/URL 解析、动态导入、第三方 SDK 和可能抛错的浏览器 API。
- 不为纯同步 UI 逻辑、简单状态派生或受控事件处理机械添加 `try/catch`。
- 没有明确需求、现有页面模式或真实失败路径时，不主动补齐 `loading / empty / error / retry / fallback` 全套状态。
- 单次使用且紧贴组件语义的小逻辑优先留在组件内；只有真实复用、隔离副作用或跨组件共享时才抽离 `utils`、`helper`、`hook`。
- TypeScript 类型要明确，不用随意 `any`。
- CSS 组织要清晰，避免不必要的全局污染。
- 页面和组件在桌面与移动端都应可用。

## 按需展开

- UI 风格：`references/ui-style.md`
- React/Vue：`references/react-vue.md`
- 实现边界：`references/implementation-boundaries.md`
- TypeScript：`references/typescript.md`
- CSS：`references/css.md`
- 可访问性：`references/accessibility.md`
- 测试：`references/testing.md`
