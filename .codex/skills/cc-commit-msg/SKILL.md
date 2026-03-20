---
name: commit-msg
description: 结构化 git commit message 生成工作流，适用于显式 commit message、提交说明或 commit-msg 场景；不负责实际执行 git commit。
---

# Commit Msg

当用户明确要求生成 commit message、整理提交说明，或提到 commit-msg 时，使用本技能。

不要用于：

- 自动执行 `git add` 或 `git commit`
- 代替正式 code review
- 生成 release notes 或 changelog

## 核心方式

1. 默认先看已暂存变更；用户明确说 `all`、全部变更或包含未暂存时，再看整个工作区 diff。
2. 先判断这批改动是否适合一个提交；过于混杂时，先提醒拆分。
3. 根据改动意图归类为 `feat`、`fix`、`refactor`、`style`、`docs`、`test` 或 `chore`。
4. 先给一条可直接使用的 subject，再给 2-5 条 body 要点。
5. 顺带列出主要变更文件，帮助用户判断 message 是否过宽。

## 输出要求

- 使用 Conventional Commit 风格：`<type>: <subject>`
- `subject` 简洁聚焦，不堆砌文件名
- `body` 使用中文 flat bullets，说明核心改动
- 不加 emoji、AI 声明或 `Co-Authored-By`
- 不替用户执行提交命令

## 按需展开

- 类型选择：`references/commit-types.md`
- 格式约束：`references/message-format.md`
