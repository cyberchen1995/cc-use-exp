# Status Checks

优先检查：

1. 项目内 `.codex/global/AGENTS.md`
2. 项目内 `.codex/global/rules/`
3. 项目内 `.codex/skills/`
4. 项目内 `.codex/profiles/`
5. 用户级 `~/.codex/AGENTS.md`
6. 用户级 `~/.codex/rules/`
7. 用户级 `~/.agents/skills/`
8. 用户级 `~/.codex/config.toml`
9. `codex --version`

常见结论：

- 项目内有，用户级没有：通常是没执行同步脚本
- skills 数量不一致：可能有未同步或手工残留
- profiles 缺少受管区块：通常是 `config.toml` 还没合并
- `codex` 不可用：先看 CLI 是否安装或 PATH 是否正确
