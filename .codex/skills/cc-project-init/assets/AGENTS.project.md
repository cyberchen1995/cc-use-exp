# [项目名称] AGENTS

作者：wwj
版本：v1.0
日期：[当前日期]

<!--
使用说明：
1. 复制此文件到仓库根目录的 AGENTS.md
2. 替换 [方括号] 中的内容
3. 删除不需要的章节和注释
4. 只保留项目特定约定，不重复用户级全局规则
-->

---

## 项目概述

[项目名称] 是一个 [项目描述]。

---

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 后端 | Go / Java / Node.js / Python | x.x+ |
| Web 框架 | Gin / Spring Boot / Express / FastAPI | x.x+ |
| ORM | GORM / JPA / Prisma / SQLAlchemy | x.x+ |
| 数据库 | SQLite / MySQL / PostgreSQL / MongoDB | x.x+ |
| 前端框架 | Vue / React | x.x+ |
| 前端语言 | TypeScript / JavaScript | x.x+ |
| UI 组件库 | Element Plus / Ant Design / 无 | x.x+ |
| 构建工具 | Vite / Webpack / 无 | x.x+ |

---

## 目录结构

```text
项目名/
├── cmd/ / src/main/java / app/  # 入口与启动
├── internal/ / src/             # 业务代码
│   ├── handler/ / controller/   # HTTP 处理器
│   ├── service/                 # 业务逻辑
│   ├── repository/ / dao/       # 数据访问
│   └── model/ / entity/         # 数据模型
├── web/ / frontend/             # 前端代码（如有）
│   ├── src/
│   └── package.json
├── deploy/ / scripts/           # 部署与脚本（如有）
└── go.mod / pom.xml / package.json / pyproject.toml
```

---

## 项目定制

### 开发约定

| 约定 | 说明 |
|------|------|
| 启动方式 | 使用 `./restart.sh` / `docker compose up` / `npm run dev` / `go run` |
| 数据库迁移 | GORM AutoMigrate / Flyway / Alembic / 手动 SQL |
| 注释风格 | 不使用行尾注释，注释单独成行 |
| 作者署名 | 所有文档和代码署名使用 wwj |

### API 规范

```go
type Response struct {
    Code    int         `json:"code"`
    Message string      `json:"message"`
    Data    interface{} `json:"data,omitempty"`
}
```

```java
public class Result<T> {
    private int code;
    private String message;
    private T data;
}
```

错误码建议：

- `0`: 成功
- `1xxx`: 参数错误
- `2xxx`: 业务错误
- `5xxx`: 系统错误

### 前端规范

| 约定 | 说明 |
|------|------|
| UI 风格 | [Element Plus / Ant Design / 自定义设计系统] |
| 设计原则 | 降低用户操作费力度，信息密度适中 |
| 避免 | 花哨装饰、复杂动效、无证据的大改版 |

---

## 常用操作

```bash
# 开发模式
./restart.sh

# 后端编译
go build ./... / mvn package / uv run pytest / npm run build

# 前端开发
cd web && npm run dev
```

---

## 与 Codex 协作

### 期望你主动做的

- 发现类型错误、明显 bug 和回归风险
- 在真实输入、IO、外部依赖和明确失败路径上补齐必要处理、边界校验和最小必要验证
- 对前端局部同步逻辑，不机械添加 `try/catch`、`fallback` 或额外工具层封装
- 在现有模式内做最小改动，避免无证据重构

### 不希望你做的

- 不要添加未要求的功能
- 不要为了“更优雅”而大改已稳定代码
- 不要覆盖现有部署脚本或环境配置，除非明确要求

### 禁止事项

- 不要直接操作生产数据库
- 不要在代码中硬编码敏感信息
- 不要跳过现有项目约定自行引入新框架
