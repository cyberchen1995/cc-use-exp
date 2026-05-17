# Scaffold Files

`project-scan` 默认补齐的脚手架文件清单与内容规范。所有脚手架文件落盘前都要按"已存在 → 询问；不存在 → 直接生成"的原则处理，不静默覆盖。

## 必生成清单（9 项）

| 序号 | 文件 | 模板 / 内容来源 |
|------|------|----------------|
| 1 | `AGENTS.md` | `cc-project-init/assets/AGENTS.project.md` |
| 2 | `README.md` | `references/readme-update.md` 最小结构 |
| 3 | `restart.sh` | `cc-project-init/assets/restart-go.sh.tmpl` / `restart-java.sh.tmpl`，按技术栈适配 Rust / Python / Node |
| 4 | `.claudeignore` | 见下方"忽略文件内容规范" |
| 5 | `.geminiignore` | 内容必须与 `.claudeignore` 完全一致 |
| 6 | `.gitignore` | 见下方"忽略文件内容规范"，按技术栈追加 |
| 7 | `.dockerignore` | `cc-project-init/assets/dockerignore.tmpl` + 下方追加项 |
| 8 | `Dockerfile` | `cc-project-init/assets/Dockerfile-go.tmpl` / `Dockerfile-go-frontend.tmpl`；Rust / Java / Node 按真实技术栈生成多阶段构建 |
| 9 | `docker-compose.yml` | `cc-project-init/assets/docker-compose-{sqlite,mysql,redis}.yml.tmpl`，按数据库选择，必要时合并 |

清单不可缩减；缺项必须在最终摘要中显式说明原因。

## 模板选择

| 技术栈 | restart | Dockerfile | docker-compose |
|--------|---------|------------|----------------|
| Go | `restart-go.sh.tmpl` | `Dockerfile-go.tmpl` | 按数据库选 |
| Go + 前端 | `restart-go.sh.tmpl` | `Dockerfile-go-frontend.tmpl` | 按数据库选 |
| Java | `restart-java.sh.tmpl` | 自行生成（Maven / Gradle 多阶段） | 按数据库选 |
| Rust + 前端 | 按 Go 脚本风格改写为 `cargo build --release` + `npm run build` | 自行生成（node 构建前端 + rust 构建后端 + slim 运行） | 按数据库选 |
| Python | 自行生成（`uvicorn` / `gunicorn`） | 自行生成（python:slim 多阶段） | 按数据库选 |
| Node | 自行生成（`pnpm` / `npm`） | 自行生成（node:slim 多阶段） | 按数据库选 |

数据库识别：

| 关键词 | 选用 compose 模板 |
|--------|------------------|
| `sqlite` / `*.db` | `docker-compose-sqlite.yml.tmpl` |
| `mysql` | `docker-compose-mysql.yml.tmpl` |
| `postgres` | 自行生成（参考 mysql 模板） |
| `redis` | `docker-compose-redis.yml.tmpl` |
| 多个 | 合并模板 |

## 忽略文件内容规范

### `.claudeignore` / `.geminiignore`（基础内容）

~~~text
# 依赖目录
node_modules/
vendor/

# 构建产物
dist/
build/
*.exe

# IDE 和编辑器
.idea/
.vscode/
*.swp

# 系统文件
.DS_Store
Thumbs.db

# 日志和临时文件
*.log
tmp/
logs/

# MCP 插件缓存
.playwright-mcp/

# 数据库文件
*.db
*.sqlite
*.sqlite-journal
*.sqlite-wal
*.sqlite-shm
~~~

按技术栈追加：

- Go：`bin/`
- Rust：`target/`、`**/*.rs.bk`
- Java：`target/`、`*.class`
- Python：`__pycache__/`、`*.pyc`、`.venv/`

### `.gitignore`（在 `.claudeignore` 基础上追加）

~~~text
# 环境配置
.env
.env.local

# 敏感文件
*.pem
*.key

# 进程文件
*.pid
~~~

### `.dockerignore`（在 `.claudeignore` 基础上追加）

~~~text
# Git
.git/
.gitignore

# 文档
*.md
LICENSE

# 测试
*_test.go
__tests__/

# 项目配置
.claude/
.codex/
.cursor/
.gemini/
.idea/
.vscode/
~~~

## 落盘后处理

- `restart.sh` 必须 `chmod +x`
- 生成完毕后执行 `bash -n restart.sh` 做语法校验
- `docker-compose.yml` 中默认密码、暴露端口需在摘要中提醒用户修改

## 已存在文件的处理

- 默认询问"覆盖 / 跳过"，不静默覆盖
- `AGENTS.md` / `README.md` 走自动区块增量逻辑（见 `agents-blocks.md`、`readme-update.md`）
- `docker-compose.yml` 已存在时建议"跳过"而非覆盖，避免冲掉用户已调好的端口、卷、密码
