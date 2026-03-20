---
name: cc-frontend-dev
description: Vue、React、TypeScript、CSS 与前端 UI 规范，适用于组件边界、样式、可访问性和前端测试；不负责 review、debug 或运维流程。
---

# CC Frontend Dev

在编辑前端代码时使用本技能，重点处理组件边界、UI 一致性、TypeScript、CSS 和可访问性。

不要用于：

- 正式 review 或 fix/debug 工作流
- 运维风险判断
- 与前端无关的后端语言细节

## 核心规则

- 保持与现有设计系统和项目视觉语言一致。
- 组件拆分按职责和复用边界，而不是机械按行数。
- TypeScript 类型要明确，不用随意 `any`。
- CSS 组织要清晰，避免不必要的全局污染。
- 页面和组件在桌面与移动端都应可用。

## 按需展开

- UI 风格：`references/ui-style.md`
- React/Vue：`references/react-vue.md`
- TypeScript：`references/typescript.md`
- CSS：`references/css.md`
- 可访问性：`references/accessibility.md`
- 测试：`references/testing.md`
