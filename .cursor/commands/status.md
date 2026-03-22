---
name: /status
id: status
category: 诊断
description: 显示当前 Cursor 配置加载状态（Rules / Skills / 可用命令）
---

显示当前 Cursor 配置的加载状态，帮助诊断配置问题。

## 输出格式

```
## 当前配置状态

### Project Rules（当前项目 .cursor/rules/）
- defensive.mdc - 防御性规则（Always Apply）
- ops-safety.mdc - 运维安全（Glob 匹配）
- bash-style.mdc - Bash 规范（Glob 匹配）
- doc-sync.mdc - 文档同步（Glob 匹配）
- date-calc.mdc - 日期计算（Glob 匹配）
- file-size-limit.mdc - 文件行数限制（Glob 匹配）

### User Skills（用户级 ~/.cursor/skills/）
[列出已安装的技能目录]
- go-dev — Go 开发规范
- java-dev — Java 开发规范
- frontend-dev — 前端开发规范
- python-dev — Python 开发规范
- bash-style — Bash 编写规范
- ops-safety — 运维安全规范
- redis-safety — Redis 安全规范
- size-check — 代码简化与行数检查
- ruanzhu — 软著 DOCX 生成
- ui-ux-pro-max — 专业级 UI/UX 规范

### Commands（可用命令）
日常：/fix, /review, /review quick, /commit-msg
开发：/new-feature, /review security, /optimize, /style-extract
设计：/design, /design checklist, /requirement, /requirement interrogate
初始化：/project-init, /project-scan
工具/诊断：/ruanzhu, /status

### 兼容性说明
- 项目级规则以当前仓库 `.cursor/rules/` 为主
- `~/.cursor/skills/` 中的 `/命令` 入口来自 `.cursor/commands/*.md` 的命令式技能兼容同步
- 若需跨项目个人偏好，优先检查 Cursor Settings 中的 User Rules
```

## 执行步骤

1. 列出当前项目 `.cursor/rules/` 下所有 `.mdc` 文件
2. 列出 `~/.cursor/skills/` 下所有技能目录
3. 对比 `.cursor/commands/*.md` 与 `~/.cursor/skills/{name}/SKILL.md` 是否一一对应
4. 如存在 `~/.cursor/rules/`，仅作为兼容性补充检查，不作为唯一真源
5. 对比项目源 `.cursor/` 和用户级 `~/.cursor/`，提示是否需要重新同步
