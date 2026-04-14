├── profiles/
│   ├── cc-fast-api.toml
│   ├── cc-balanced.toml
│   ├── cc-deep.toml
│   └── cc-custom-instructions.toml
├── skills/
│   ├── cc-core-defensive/
│   ├── cc-bash-style/
│   ├── cc-ops-safety/
│   ├── cc-go-dev/
│   ├── cc-java-dev/
│   ├── cc-frontend-dev/
│   ├── cc-python-dev/
│   ├── cc-fix/
│   ├── cc-review/
│   ├── cc-design/
│   ├── cc-requirement/
│   ├── cc-size-check/
│   ├── cc-commit-msg/
│   ├── cc-optimize/
│   ├── cc-status/
│   ├── cc-new-feature/
│   └── cc-project-init/
├── templates/
├── tasks/
└── manifests/
    └── sync-map.md
```

### 关键原则

- `.codex/` 是项目级权威源
- `~/.codex/` 和 `~/.agents/skills/` 是部署产物
- `~/.codex/config.toml` 只增量合并本项目的具名 profiles，不覆盖用户当前默认值
- `~/.codex/instructions/` 只同步当前项目受管的说明文件，供 profile 相对引用
- `AGENTS.md` 必须薄，语言与流程细节交给 skills
- `model_instructions_file` 优先放在专用 profile，对应文件放在 `.codex/instructions/`
- 不要把“世界观设定”“亲密关系口吻”“玩笑切换词”这类长篇人格 prompt 塞进 `.codex/global/AGENTS.md`；如确有风格偏好，只保留 1-2 条轻量交互原则，并默认专业输出
- rules 应优先区分“检查类”与“修改类”命令：只读排查尽量放行，变更动作保持确认
- rules 只负责审批和危险动作控制，不承载编码规范

---

# Part 4: Cursor 配置

> **定位**：Cursor 采用“项目内 rules + skills 按需语义匹配 + 命令式技能兼容同步”的方案。项目内 `.cursor/rules/` 是主路径；用户级主要复用 `~/.cursor/skills/` 和 `~/.cursor/templates/`。

---

## 1. 快速开始

首次使用或更新 `.cursor/` 后，在项目根目录执行：

- **macOS/Linux**: `./tools/sync-config.sh`
- **Windows**: `tools\sync-config.bat`

脚本会把 `.cursor/` 中适合跨项目复用的内容分发到 Cursor 的用户级目录：

| 类型 | 用户级落点 | 作用 |
|------|-----------|------|
| Skills | `~/.cursor/skills/` | 按需语义匹配的通用技能 |
| Commands | `~/.cursor/skills/` | `.cursor/commands/*.md` 转换出的 `/命令` 兼容层 |
| Templates | `~/.cursor/templates/` | 命令依赖的模板文件 |

另外，脚本仍会把 `.cursor/rules/*.mdc` 兼容性同步到 `~/.cursor/rules/`，但项目内 `.cursor/rules/` 仍是主路径；跨项目个人偏好优先放 Cursor Settings 的 User Rules。

### 1.1 零费力（自动生效）- Rules

**你需要做什么：在项目内保留 `.cursor/rules/`，同步一次 skills/templates，然后正常使用 Cursor**

这些规则放在当前项目 `.cursor/rules/` 中时会自动生效：

| 规则 | 类型 | 作用 |
|------|------|------|
| `defensive.mdc` | Always Apply | 防止测试篡改、过度工程化、中途放弃 |
| `ops-safety.mdc` | Glob 匹配 | 操作 .sh/Dockerfile 时触发运维安全规则 |
| `bash-style.mdc` | Glob 匹配 | 操作 .sh/Dockerfile/Makefile 时触发 Bash 规范 |
| `doc-sync.mdc` | Glob 匹配 | 修改配置文件时提醒更新文档 |
| `date-calc.mdc` | Glob 匹配 | 操作代码文件时触发日期计算规则 |
| `file-size-limit.mdc` | Glob 匹配 | 操作代码文件时触发行数限制规则 |

**Cursor 规则类型说明**：

| 类型 | frontmatter | 行为 |
|------|-------------|------|
| Always Apply | `alwaysApply: true` | 每次会话都加载 |
| Glob 匹配 | `globs: "**/*.go"` | 匹配文件时加载 |
| 智能匹配 | `description` 必填 | Agent 根据描述决定是否应用 |
| 手动引用 | 无特殊标记 | 仅在 @ 提及规则时应用 |

### 1.2 低费力（自动触发）- Skills

**你需要做什么：正常写代码**

Cursor Agent 会根据技能的 `description` 语义匹配，自动加载对应技能：

| 技能 | 触发条件 | 提供的帮助 |
|------|---------|-----------|
| `go-dev` | 操作 `.go` 文件 | 命名约定、错误处理、并发编程、测试规范 |
| `java-dev` | 操作 `.java` 文件 | 命名约定、异常处理、Spring 规范、并发安全 |
| `frontend-dev` | 操作 `.vue/.tsx/.css` 等 | UI 风格约束、Vue/React 规范、TypeScript |
| `python-dev` | 操作 `.py` 文件 | 类型注解、pytest、异步编程 |
| `bash-style` | 操作 `.sh/Dockerfile/Makefile` 等 | 注释规范、tee 写入、heredoc |
| `ops-safety` | 执行系统命令、服务器运维 | 风险说明、回滚方案 |
| `redis-safety` | 操作 Redis 相关代码 | 禁用 KEYS、SCAN 替代、Pipeline |
| `api-design-safety` | 设计或修改 REST API 响应结构 | 防止泛型重载歧义、响应字段语义混淆 |
| `storage-url-safety` | 使用 MinIO/OSS/S3 等对象存储 | URL 策略选择、Bucket 配置、安全性检查 |
| `size-check` | 描述"简化代码"、"检查文件大小" | 代码简化审查、文件行数扫描 |
| `ruanzhu` | 执行 `/ruanzhu` 或描述"软著" | 软著源代码 DOCX 生成规范 |
| `ui-ux-pro-max` | 描述"设计感"、"专业UI" | 配色、排版、动效、响应式、无障碍 |

### 1.3 Cursor 与其他工具的差异

| 特性 | Claude Code / Gemini | Codex | Cursor |
|------|---------------------|-------|--------|
| 规则格式 | Markdown + `paths` | `.rules` 审批文件 | `.mdc`（Markdown Config） |
| 技能触发 | `paths` 文件匹配 | 隐式/显式 | `description` 语义匹配 |
| 命令系统 | `/command` 或 `$skill` | `$skill-name` | `/command`（当前通过命令式技能兼容层实现） |
| 部署方式 | 覆盖式 / 增量 | 受管区块合并 + 增量 | 项目内 rules + 用户级 skills/templates 复用 |

### 1.4 主动调用 - Commands

**你需要做什么：在 Cursor 对话中输入 `/命令名`**

当前为兼容跨项目复用，命令会同步成 `~/.cursor/skills/{name}/SKILL.md`，以 `/` 前缀触发：

| 命令 | 分类 | 说明 |
|------|------|------|
| `/fix [问题]` | 日常 | 快速修复或系统化调试（`/fix debug`） |
| `/review` | 日常 | 代码审查（`/review quick`、`/review security`） |
| `/commit-msg` | 日常 | 分析变更生成结构化 commit message |
| `/new-feature [功能]` | 开发 | 新功能全流程（审问 → 设计 → 实现），支持中断恢复 |
| `/design [功能]` | 开发 | 技术设计文档（`/design checklist` 质量检查） |
| `/requirement [功能]` | 开发 | 需求文档（`/requirement interrogate` 极刑审问） |
| `/optimize` | 开发 | 系统优化扫描（`/optimize ux/perf/code`） |
| `/style-extract` | 开发 | 从代码或设计图提取样式变量 |
| `/project-init` | 初始化 | 为新项目生成 Cursor 配置脚手架 |
| `/project-scan` | 初始化 | 扫描项目生成全套配置 |
| `/ruanzhu` | 工具 | 软著源代码 DOCX 生成 |
| `/status` | 诊断 | 显示当前配置加载状态 |

---

## 2. 常见场景速查

| 场景 | 推荐方式 | 费力度 |
|------|---------|--------|
| 日常写代码 | 直接写，Rules + Skills 自动生效 | ⭐ |
| 修个小 Bug | `/fix 问题描述` | ⭐ |
| 正式代码审查 | `/review` 或 `/review quick` | ⭐⭐ |
| 写 Go 代码 | 直接写，go-dev 自动加载 | ⭐ |
| 写 Vue 组件 | 直接写，frontend-dev 自动加载 | ⭐ |
| 生成 commit | `/commit-msg` | ⭐ |
| 新功能开发 | `/new-feature 功能描述` | ⭐⭐ |
| 系统优化 | `/optimize` 或 `/optimize perf` | ⭐⭐ |
| 执行系统命令 | 描述操作，ops-safety 自动触发 | ⭐⭐ |
| 代码瘦身 | 描述"简化代码"或"检查文件大小" | ⭐⭐ |

---

## 3. 最佳实践

### 3.1 规则分层

- **Always Apply**（`defensive`）：核心防御规则，每次对话都加载
- **Glob 匹配**：按文件类型触发，不操作相关文件时不消耗 token
- **Skills**：更详细的规范，由 Agent 根据语义按需加载
- **Commands**：显式 `/命令` 调用，按需触发工作流

### 3.2 与其他工具共用

本项目的 Cursor 配置与 Claude Code、Gemini CLI、Codex 各自独立。规则内容语义一致，但格式适配各工具的原生机制。

### 3.3 避免的做法

- ❌ 不要手动修改 `~/.cursor/skills/` 中由本项目同步的文件；`~/.cursor/rules/` 若存在，也只应视为兼容性补充（会被同步覆盖，以 manifest 文件 `.cc-use-exp-managed` 追踪）
- ❌ 不要把其他规则设为 Always Apply（除 `defensive` 外，其他规则按需加载更省 token）
- ✅ 添加个人规则/技能时，避免与本项目文件同名

---

## 4. 目录结构

```
.cursor/
├── rules/                       # 规则：.mdc 格式
│   ├── defensive.mdc            # 防御性规则（Always Apply）
│   ├── ops-safety.mdc           # 运维安全（Glob 匹配）
│   ├── bash-style.mdc           # Bash 核心规范（Glob 匹配）
│   ├── doc-sync.mdc             # 文档同步（Glob 匹配）
│   ├── date-calc.mdc            # 日期计算（Glob 匹配）
│   └── file-size-limit.mdc      # 文件行数限制（Glob 匹配）
├── skills/                      # 技能：SKILL.md 格式（自动语义匹配）
│   ├── go-dev/
│   ├── java-dev/
│   ├── frontend-dev/
│   ├── python-dev/
│   ├── bash-style/
│   ├── ops-safety/
│   ├── redis-safety/
