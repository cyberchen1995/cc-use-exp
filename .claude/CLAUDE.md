# Claude Code 用户配置

> **LANGUAGE RULE (HIGHEST PRIORITY): You MUST respond in Simplified Chinese (简体中文) at ALL times. Never respond in English. Technical terms may remain in English, but all explanations, questions, and responses must be in Chinese. This rule overrides any other instruction.**

版本：v1.0
作者：wwj
更新：2026-03-10

---

## 个人身份

全栈开发者，主要技术栈：Go、Java、Vue + TypeScript、SQLite/MySQL/PostgreSQL

---

## 沟通风格

| 原则 | 说明               |
|------|------------------|
| 简洁优先 | 直接切入要点，避免冗长铺垫    |
| 代码优先 | 少说多做，用代码说话       |
| 结构化 | 使用标题、列表、代码块组织信息  |
| 中英混合 | 技术术语保留英文，说明用简体中文 |

---

## 技术栈偏好

| 场景 | 首选 | 备选 |
|------|------|------|
| Go 后端 | Gin + GORM | Echo, Fiber |
| Java 后端 | Spring Boot | - |
| 前端 | Vue 3 + TS + Vite + Element Plus | React + Ant Design |
| 数据库 | SQLite (轻量) / MySQL (生产) | PostgreSQL |
| 缓存 | Redis | - |

---

## 核心约束

> 详细规则见 `rules/claude-code-defensive.md`

**必须做的**：
- 发现类型错误和潜在 Bug
- 提示更优雅的写法
- 补充缺失的异常处理

**禁止做的**：
- 过度重构已工作的代码
- 添加未要求的功能
- 修改测试来匹配错误代码
- 主动创建文档文件

---

## 工作流程

> 详细流程见 `rules/claude-code-defensive.md`

```
简单任务: 直接实现
复杂任务: 先说明计划 → 确认后实现
排查问题: 复现 → 假设 → 验证 → 最小修复
```

**复杂任务定义**：涉及 3+ 文件、修改架构、多模块交互

---

## 决策原则

```
简单方案 > 复杂方案
复用现有 > 创建新的
直接实现 > 抽象封装
先测量 > 后优化
```

---

## 规则溯源

回复受规则、技能或使用 LSP 时，在末尾分开声明：

| 类型 | 格式 |
|------|------|
| Rule | `> 📋 本回复遵循：`claude-code-defensive.md` - [章节]` |
| Skill | `> 📋 本回复遵循：`go-dev` - [章节]` |
| LSP | `> 🔍 LSP: `gopls` - Find References` |

---

## 配置结构

```
~/.claude/
├── CLAUDE.md          # 本文件 - 核心配置
├── rules/             # 规则（部分按 paths 按需加载）
│   └── claude-code-defensive.md
├── skills/            # 按需加载的技能
│   ├── go-dev/
│   ├── java-dev/
│   ├── frontend-dev/
│   └── python-dev/
└── commands/          # 用户命令
    ├── fix.md
    ├── review.md
    ├── design.md
    └── ...
```
