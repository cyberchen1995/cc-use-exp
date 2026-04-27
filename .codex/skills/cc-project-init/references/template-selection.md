# Template Selection

优先规则：

1. 先生成或更新仓库根目录 `AGENTS.md`
2. 默认补齐项目级 `.codex` 骨架（`tasks/`、`tasks/archived/`、`templates/`）
3. 只有用户明确需要额外脚手架时，才从 `assets/` 选模板
4. 已有同名文件时，先 diff，再决定补丁式更新还是保留现状

## 模板映射

| 资源 | 适用场景 |
|------|---------|
| `assets/AGENTS.project.md` | 需要项目级 Codex 指导文件，并为后续 `project-scan` 预留 `AUTO:*` 自动区块 |
| `assets/codex-skeleton/` | 需要让项目原生支持 `new-feature` 任务持久化 |
| `assets/gitignore-go.tmpl` | Go 后端仓库缺少 `.gitignore` |
| `assets/dockerignore.tmpl` | 需要新增 `Dockerfile` 或容器构建 |
| `assets/Dockerfile-go.tmpl` | 纯 Go 后端服务 |
| `assets/Dockerfile-go-frontend.tmpl` | Go 后端 + `web/` 前端构建 |
| `assets/docker-compose-sqlite.yml.tmpl` | 单服务 + SQLite 挂载数据目录 |
| `assets/docker-compose-mysql.yml.tmpl` | 服务依赖 MySQL |
| `assets/docker-compose-redis.yml.tmpl` | 服务依赖 Redis |
| `assets/restart-go.sh.tmpl` | Go 服务需要统一重启脚本 |
| `assets/restart-java.sh.tmpl` | Java 服务需要统一重启脚本 |

`README.md` 不属于 `project-init` 的默认模板；生成或刷新 README 时使用 `project-scan` 的 README 更新规则。

## 选择细则

- `docker-compose` 模板是单用途基础版，不要把多份模板直接拼接后原样落盘。
- `.codex` 骨架只补目录与占位文件，避免覆盖项目已有任务文件或模板文件。
- 同时需要 MySQL 和 Redis 时，以其中一份为骨架，按当前项目配置手工合并。
- `restart-*.sh` 只适合单服务项目；已有 systemd、supervisor、容器编排时通常不该新增。
- `AGENTS.project.md` 应替换占位符，并删除不适用章节，不要把模板原样提交；保留 `AUTO:*` 区块结构，便于后续增量刷新。
- `.claudeignore.tmpl` 和软著相关文件不属于 Codex 项目初始化范围，故未迁入本技能。
- 如果用户明确要求 README、技术栈摘要、目录结构或快速开始说明，先转入 `project-scan`，不要在 `project-init` 中维护第二套 README 生成逻辑。
