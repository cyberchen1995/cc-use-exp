---
name: project-scan
description: 扫描当前仓库并生成或更新项目级 AGENTS.md / README.md，适用于显式 project-scan、项目认知初始化或刷新项目级 Codex 上下文的场景；默认补齐项目内最小 .codex 骨架。
---

# Project Scan

当用户明确要求 `project-scan`、扫描项目、生成项目级 `AGENTS.md`、生成或刷新 `README.md`，或刷新项目级 Codex 上下文时，使用本技能。

不要用于：

- feature 开发或 bug 修复
- 代替 `project-init` 批量生成脚手架文件
- 无确认地覆盖已有 `AGENTS.md` 或 `README.md`
- 为 Claude 或 Gemini 生成专属配置文件

## 核心方式

1. 先扫描仓库中的关键信号文件和目录，区分“明确识别”的事实与“基于结构的推断”。
2. 默认确保项目级 `.codex/tasks/`、`.codex/tasks/archived/`、`.codex/templates/` 存在；若项目根目录写入触发权限边界，先走平台审批，不静默跳过。
3. 读取根目录现有 `AGENTS.md`、`README.md`，以及可参考的 `.claude/CLAUDE.md`；复用 `cc-project-init/assets/AGENTS.project.md` 作为项目级 `AGENTS.md` 模板来源。
4. 先输出扫描摘要，再追问 3-5 个扫描无法可靠确认的关键问题，例如项目一句话描述、高风险区域、统一 API 契约和禁改约定。
5. 若根目录 `AGENTS.md` 不存在，则基于模板生成；若已存在且包含自动区块，则优先增量更新；若已存在但无自动区块，必须先让用户选择“首次全量重建 / 追加自动区块 / 跳过”。
6. 自动区块只更新 `<!-- AUTO:* -->` 包围的内容，保留区块外的手写说明和项目经验，不整文件覆盖。
7. `README.md` 不存在时，可基于扫描事实生成最小可用说明；已存在时，优先更新 `<!-- AUTO:* -->` 区块，若没有自动区块，必须先让用户选择“追加自动区块 / 首次全量重建 / 跳过”。
8. 默认不生成 Dockerfile、docker-compose、restart 或 ignore 文件；只有用户明确追加脚手架需求时，才转交 `project-init` 的方式处理。
9. 完成后说明扫描结论、写入策略、已补齐的项目级 `.codex` 骨架，以及仍需用户补充的项目事实。

## 协作约束

- 项目级 `AGENTS.md` 模板资产复用 `cc-project-init/assets/AGENTS.project.md`
- 项目初始化脚手架需求转交 `project-init`
- `README.md` 生成和更新遵循 `references/readme-update.md`
- 后续 feature 任务持久化依赖 `new-feature`
- 若涉及接口契约总结或列表/分页/筛选结构判断，遵循 `cc-api-contract-safety` 的方式，不臆测响应结构

## 输出要求

- 明确区分“扫描识别”与“待确认项”
- 明确说明 `AGENTS.md` 与 `README.md` 分别采用“新建 / 增量更新 / 首次全量重建 / 追加自动区块 / 跳过”中的哪一种
- 若补齐了 `.codex/tasks/`、`.codex/tasks/archived/`、`.codex/templates/`，必须明确说明
- 若已有 `AGENTS.md` 但用户选择跳过更新，要说明后续风险：Codex 新 session 仍可能缺少项目级上下文
- 若接口契约无法从代码或文档确定，要在 `AGENTS.md` 中标注“待用户确认”，不要伪造规范
- 若无法可靠确认项目启动方式、端口、部署方式或许可证，`README.md` 中必须标注“待确认”，不要编造命令

## 按需展开

- 扫描项：`references/scan-checks.md`
- 自动区块：`references/agents-blocks.md`
- 重建策略：`references/rebuild-strategy.md`
- README 更新：`references/readme-update.md`
