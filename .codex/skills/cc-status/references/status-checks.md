# Status Checks

优先检查：

1. 项目内 `.codex/global/AGENTS.md`
2. 项目内 `.codex/global/rules/`
3. 项目内 `.codex/instructions/`
4. 项目内 `.codex/skills/`
5. 项目内 `.codex/profiles/`
6. 用户级 `~/.codex/AGENTS.md`
7. 用户级 `~/.codex/rules/`
8. 用户级 `~/.codex/instructions/`
9. 用户级 `~/.agents/skills/`
10. 用户级 `~/.codex/{profile}.config.toml`
11. `~/.codex/AGENTS.md` 是否包含 `cc-use-exp codex managed:start/end`
12. `~/.codex/.cc-use-exp-profiles`
13. `~/.codex/rules/.cc-use-exp-managed`
14. `~/.codex/instructions/.cc-use-exp-managed`
15. `~/.agents/skills/.cc-use-exp-managed`
16. `~/.codex/*.config.toml` 中被本项目 profile 引用的 `./instructions/*.md` 是否存在
17. `codex --version`
18. 当前项目 `.codex/tasks/`
19. 当前项目 `.codex/tasks/archived/`
20. 当前项目 `.codex/templates/`
21. `.codex/tasks/` 根目录中是否存在活动任务文件
22. 是否只有一个主任务处于 `进行中`
23. 是否存在明确的候选任务、被打断状态、恢复入口和下一步
24. 当前项目根目录 `AGENTS.md`
25. 根目录 `AGENTS.md` 是否包含 `<!-- AUTO:tech-stack -->` 等自动区块
26. 当前会话是否明确在目标项目根目录执行
27. 当前症状是“目录缺失”还是“目录存在但写入失败”
28. 是否已经看到过平台原生审批提示
29. 若未看到审批提示，是否可能根本没走到项目根目录写入动作
30. 若目录已存在但仍写入失败，是否应优先怀疑当前会话仍在受限 sandbox / workspace scope 中

如果 `codex execpolicy check` 可用，再做规则抽样验证：

1. `docker ps` 预期 `allow`
2. `systemctl status nginx` 预期 `allow`
3. `docker compose down` 预期 `prompt`
4. `rm -rf tmp` 预期 `forbidden`

输出时建议拆成两段：

- 文件/同步状态：项目权威源、用户级部署产物、受管区块、manifest、数量差异
- 规则生效状态：抽样命令、命中规则、实际决策、是否符合预期

若项目内存在活动任务，建议再补一段：

- 任务状态：当前主线、候选任务、被打断点、最近更新时间、建议恢复顺序

若当前项目缺少 `.codex/tasks/`、`.codex/tasks/archived/` 或 `.codex/templates/`，建议额外单列：

- `new-feature` 前置条件：项目级 `.codex` 骨架是否齐全、是否建议先执行 `$project-init` 或 `$project-scan`

若当前项目缺少根目录 `AGENTS.md`，或 `AGENTS.md` 不含自动区块，建议额外单列：

- 项目级上下文状态：`AGENTS.md` 是否已建立、是否适合执行 `$project-scan`

若当前项目骨架已齐全但任务仍无法持久化，建议额外单列：

- 当前会话是否在目标项目根目录
- 当前会话是否已触发平台审批
- 当前会话是否仍处在受限 sandbox / workspace scope 中
- 当前问题更像“workflow 没走到写入动作”还是“写入动作已执行但被权限边界拦截”

常见结论：

- 项目内有，用户级没有：通常是没执行同步脚本
- instructions 数量不一致：通常是没执行最新同步脚本，或用户级目录仍是旧结构
- skills 数量不一致：可能有未同步或手工残留
- profiles 缺少 `.cc-use-exp-profiles`：通常是还没执行最新同步脚本
- AGENTS 缺少受管区块：通常是 `AGENTS.md` 还没合并，或被手工覆盖
- rules/skills 缺少 manifest：通常是没走同步脚本，或用户级目录被手工改动
- 文件都在但抽样规则不符合预期：优先怀疑用户级 rules 不是当前项目版本，或命中了更严格的外部规则
- 当前项目缺少 `.codex/tasks/` 或 `.codex/templates/`：通常说明还没做项目级初始化，先执行 `$project-init`
- `.codex/tasks/` 中多个任务同时标记为 `进行中`：通常说明任务状态漂移，先用 `$cc-task-state` 收敛主线和候选任务
- `.codex/tasks/` 里只有一句自然语言备注、缺少恢复入口和下一步：通常说明任务只是被记下，但还没被结构化沉淀
- 当前项目缺少根目录 `AGENTS.md` 或缺少自动区块：通常说明还没做项目级上下文初始化或刷新，先执行 `$project-scan`
- 项目骨架已齐全但仍写入失败：优先怀疑当前会话不在目标项目根目录，或仍处在受限 sandbox / workspace scope 中
- `codex` 不可用：先看 CLI 是否安装或 PATH 是否正确
