# .codex 同步映射

本目录是项目级权威源，不直接作为 Codex 原生仓库入口使用。当前 `tools/sync-config.sh` 已按以下映射部署：

| 源路径 | 目标路径 | 策略 |
|------|------|------|
| `.codex/global/AGENTS.md` | `~/.codex/AGENTS.md` | 受管区块合并，不整文件覆盖 |
| `.codex/global/rules/*.rules` | `~/.codex/rules/` | 增量复制，文件名保留 `cc-` 前缀 |
| `.codex/instructions/*.md` | `~/.codex/instructions/` | 增量复制，清理当前项目受管文件 |
| `.codex/skills/*` | `~/.agents/skills/` | 增量复制，保留目录名 |
| `.codex/templates/` | `~/.codex/templates/` | 增量复制，供 workflow skill 复用模板 |
| `.codex/tasks/` | `~/.codex/tasks/` | 仅同步目录骨架与占位文件，保证其他项目可继承任务目录 |
| `.codex/{tasks,templates}` 骨架 | `~/.codex/project-template/.codex/` | 为其他项目提供可复制的项目级 `.codex` 目录骨架 |
| `.codex/profiles/*.toml` | `~/.codex/{profile}.config.toml` | 增量复制，文件名从 `{profile}.toml` 转为 `{profile}.config.toml` |

## 不同步内容

- `.codex/manifests/`
- `.codex/.env`（仅作为可选代理模板，避免自动覆盖用户本地 `~/.codex/.env`）

## 特殊同步说明

- `tools/sync-config.sh` 会确保 `~/.codex/templates/` 与 `~/.codex/tasks/` 存在
- `~/.codex/tasks/` 仅同步目录骨架与占位文件，不覆盖其他项目运行时新增的任务文件
- `tools/sync-config.sh` 还会生成 `~/.codex/project-template/.codex/`，供其他项目直接复制项目级 `.codex` 骨架
- `tools/sync-config.sh` 会移除旧版 `~/.codex/config.toml` 中的 cc-use-exp profiles 受管区块，并改用 Codex 0.134.0+ 支持的独立 profile 文件
- 其他项目若未自带 `.codex/tasks/`，应先复制该骨架到项目根目录，再使用 `new-feature`

## 明确禁止

- 不删除 `~/.codex/` 运行态文件
- 不覆盖 `~/.codex/auth.json`
- 不覆盖 `~/.codex/history.jsonl`
- 不覆盖日志、sqlite、cache
- 不改用户现有默认 provider/model/base_url
- 不写入项目私有绝对路径
- 不覆盖用户已有非 cc-use-exp profile 文件
