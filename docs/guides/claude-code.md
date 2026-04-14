# Part 1: Claude Code 配置

---

## 1. 快速开始

### 1.1 零费力（自动生效）- Rules

**你需要做什么：什么都不用做**

这些规则始终自动加载，在后台默默保护你：

| 规则 | 作用 | 触发场景 |
|------|------|---------|
| `claude-code-defensive.md` | 防止测试篡改、过度工程化、中途放弃 | 始终生效 |
| `file-size-limit.md` | 文件行数超限时警告，提供简化选项 | 修改代码文件时 |
| `ops-safety.md` | 危险命令确认、回滚方案、风险提示 | 始终生效（详细规范见 skills） |
| `doc-sync.md` | 配置/结构变更时提醒更新文档 | 修改配置时 |
| `bash-style.md` | Bash 核心规范：禁止行尾注释 | 始终生效（详细规范见 skills） |
| `date-calc.md` | 日期加减保持日不变，禁止默认月末对齐 | 始终生效 |

**效果示例**：
- Claude 不会修改测试来适配错误代码
- 文件行数超限时自动警告，可选择立即简化或稍后处理
- 执行 `sysctl` 等危险命令前会提示风险和回滚方案
- 新增命令后会提醒你更新 README

### 1.2 低费力（自动触发）- Skills

**你需要做什么：正常写代码**

操作相关文件时自动加载对应的开发规范：

| 技能 | 触发条件 | 提供的帮助 |
|------|---------|-----------|
| `go-dev` | 操作 `.go` 文件 | 命名约定、错误处理、并发编程、测试规范 |
| `java-dev` | 操作 `.java` 文件 | 命名约定、异常处理、Spring 规范、不可变集合、线程池、代码模式 |
| `frontend-dev` | 操作 `.vue/.tsx/.css` 等 | UI 风格约束、Vue/React 规范、TypeScript |
| `python-dev` | 操作 `.py` 文件 | 类型注解、Pydantic、pytest、uv 工具链 |
| `bash-style` | 操作 `.sh/Dockerfile/Makefile/.md` 等 | 注释规范、tee 写入、heredoc、脚本规范 |
| `ops-safety` | 执行系统命令、服务器运维 | 风险说明、回滚方案、问题排查原则 |
| `redis-safety` | 操作 Redis 相关代码 | 禁用 KEYS、SCAN 替代、Pipeline、TTL 规范 |
| `refactor-safety` | 重构代码（提取组件、合并逻辑） | 重构安全检查清单、防止丢失原始上下文 |
| `field-mapping-safety` | 重构字段映射（dataIndex、枚举映射） | 防止字段名推测错误、枚举映射不完整 |
| `api-design-safety` | 设计或修改 REST API 响应结构 | 防止泛型重载歧义、响应字段语义混淆、空值处理不一致 |
| `storage-url-safety` | 使用 MinIO/OSS/S3 等对象存储 | URL 策略选择（公开/预签名/CDN）、Bucket 配置、安全性检查 |
| `size-check` | `/size-check` 或描述"简化代码" | 完整代码简化审查、全项目文件行数扫描 |

**效果示例**：
- 写 Go 代码时，自动遵循 Effective Go 规范
- 写 Vue 组件时，自动使用 Composition API + TypeScript
- 文件行数超限时，Rules 层会自动警告
- 需要全项目扫描时，调用 `/size-check` 获取完整报告
- 不操作这些文件时，不消耗额外 token

### 1.3 中费力（显式调用）- Commands

**你需要做什么：输入 `/命令名`**

#### 高频命令（日常使用）

| 命令 | 用途 | 使用示例 |
|------|------|---------|
| `/fix` | 快速修复 Bug | `/fix 登录接口返回 500` |
| `/fix debug` | 复杂问题排查（复现→假设→验证→修复） | `/fix debug 定时任务不执行` |
| `/review` | 正式代码审查 | `/review` |
| `/review quick` | 快速审查（git diff + 简要意见） | `/review quick` |
| `/commit-msg` | 生成 git commit message | `/commit-msg` 或 `/commit-msg all` |

#### 中频命令（按需使用）

| 命令 | 用途 | 使用示例 |
|------|------|---------|
| `/review security` | 安全审查当前分支代码 | `/review security` |
| `/optimize` | 系统优化（UX/性能/代码/安全/语法糖/最佳实践） | `/optimize` 或 `/optimize perf` |
| `/new-feature` | 新功能全流程（需求→设计→实现） | `/new-feature 用户导出功能` |
| `/design doc` | 生成技术设计文档框架 | `/design doc 用户权限模块` |
| `/requirement doc` | 生成需求文档框架 | `/requirement doc 报表功能` |

#### 低频命令（特定场景）

| 命令 | 用途 | 使用示例 |
|------|------|---------|
| `/skill-install` | 一键安装 cc-use-exp 配置体系 | `/skill-install` |
| `/skill-update` | 更新配置体系到最新版本 | `/skill-update` |
| `/requirement interrogate` | 需求极刑审问，挖掘逻辑漏洞 | `/requirement interrogate 用户要导出数据` |
| `/design checklist` | 生成设计质量检查清单 | `/design checklist` |
| `/project-init` | 为新项目初始化 Claude Code 配置 | `/project-init` |
| `/project-scan` | 扫描项目生成配置（CLAUDE.md/restart.sh/ignore/Docker） | `/project-scan` |
| `/style-extract` | 从代码或设计图提取样式变量 | `/style-extract` |
| `/ruanzhu` | 生成软著源代码 DOCX 文件 | `/ruanzhu "系统名称" 60` |
| `/check-toolsearch` | 检查 ToolSearch/WebSearch 是否可用 | `/check-toolsearch` |
| `/cache-patch` | 1h 缓存补丁 | `/cache-patch` 或 `/cache-patch status` |
| `/patch` | Claude Code 综合补丁（一键全部） | `/patch` 或 `/patch status` |
| `/status` | 显示当前配置状态（Rules/Skills/LSP） | `/status` |


`/cache-patch`验证效果:
![cache-check](./pic/cache-check.png)


注：`/patch` 只是让 CC 绕过 Chrome 订阅检查。如需要自定义渠道的插件，可以扫码联系作者免费获取插件地址，仅供学习使用。

![Chrome 插件独立配置界面（可指定自定义模型）](./pic/cc-chrome-plugin-1.png)

Claude Code 联动 Chrome 扩展效果图：
![Claude Code 联动 Chrome 扩展效果图](./pic/cc-chrome-plugin-2.png)

### 1.4 Claude Code 推荐插件（声明式安装）

本项目通过 `.claude/plugins.json` 声明了推荐的插件。

| 插件 | 用途 |
|------|------|
| `context7` | 精准第三方库文档查询 |
| `frontend-design` | 生成高质量前端界面代码 |
| `gopls-lsp` | Go 语言 LSP 支持 |
| `jdtls-lsp` | Java 语言 LSP 支持 |
| `playwright` | 浏览器自动化测试 |
| `pyright-lsp` | Python 语言 LSP 支持 |
| `security-guidance` | 代码安全审计指导 |
| `typescript-lsp` | TypeScript/JS LSP 支持 |
| `superpowers` | 结构化开发框架：TDD、调试、头脑风暴 |
| `code-review` | 多审查者代码审查 + 置信度评分 |

**推荐安装方式：**
运行 `./tools/sync-config.sh`，脚本会自动检测缺失的插件并引导你一键安装。

**手动安装：**
```bash
claude plugin install context7@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
# ... 其他插件同理
```

---

## 2. 常见场景速查

| 场景 | 推荐方式 | 费力度 |
|------|---------|--------|
| 日常写代码 | 直接写，Rules + Skills 自动生效 | ⭐ |
| 修个小 Bug | `/fix 问题描述` | ⭐⭐ |
| 提交前快速看看 | `/review quick` | ⭐⭐ |
| 生成 commit message | `/commit-msg` | ⭐⭐ |
| 正式代码审查 | `/review` | ⭐⭐ |
| 复杂 Bug 排查 | `/fix debug 问题描述` | ⭐⭐⭐ |
| 安全审查 | `/review security` | ⭐⭐⭐ |
| 系统优化评估 | `/optimize` | ⭐⭐⭐ |
| 开发新功能 | `/new-feature 功能名` | ⭐⭐⭐ |
| 新项目初始化 | `/project-init` | ⭐⭐⭐ |

```
遇到 Bug？
├─ 简单 Bug → /fix 问题描述
└─ 复杂 Bug → /fix debug 问题描述

代码审查？
├─ 快速看看 → /review quick
├─ 正式审查 → /review
└─ 安全审查 → /review security

新功能？
├─ 完整流程 → /new-feature 功能名
└─ 只要设计 → /design doc 模块名

系统优化？
├─ 全量评估 → /optimize
├─ 仅性能 → /optimize perf
├─ 仅代码质量 → /optimize code
└─ 仅 UX → /optimize ux
```

---

## 3. 综合补丁工具

### 补丁项一览

| 补丁 | 说明 | 管理工具 |
|------|------|---------|
| Chrome 订阅绕过 | `/chrome` 命令不再要求 claude.ai 订阅 | `patch-claude.py` |
| Context Warning 禁用 | 禁用上下文接近上限时的警告（不影响 auto-compact） | `patch-claude.py` |
| Auth conflict 抑制 | 抑制 Chrome 补丁导致的误触发 OBK 警告 | `patch-claude.py` |
| Read/Search 折叠禁用 | 禁止 Read/Search 工具结果折叠 | `patch-claude.py` |
| ToolSearch 域名解除 | 允许 ToolSearch 访问任意域名（第三方中转用户） | `patch-toolsearch.py` |
| 1h Prompt Cache | 启用 1 小时 prompt 缓存 | `claude-1h-cache-patch.js` |

### 支持的安装方式

bun 官方二进制 / npm / pnpm / Homebrew / VS Code / Cursor

### 使用方法

**1. 一键全部补丁（推荐）**

```bash
/patch
```

**2. 查看全部补丁状态**

```bash
/patch status
```

**3. 单独管理某项补丁**

```bash
/patch toolsearch    # ToolSearch 域名解除
/patch cache         # 1h Prompt Cache
/patch tui           # 交互式 TUI（Chrome/Context/Auth/Collapse）
/patch restore       # 还原 patch-claude.py 管理的补丁
```

> **注意**：Claude Code 更新后补丁会被覆盖，需重新执行 `/patch`。

---

## 4. 最佳实践

### 4.1 让自动化为你工作

- **不要干预 Rules**：它们在后台保护你，比如防止 Claude 修改测试
- **不要手动加载 Skills**：操作相关文件时自动生效
- **相信防御机制**：复杂任务会自动要求确认计划后再执行

### 4.2 避免的做法

- ❌ 不要绕过 Rules 的保护机制
- ❌ 不要在简单任务上使用复杂命令
- ❌ 不要忽略文档同步提醒

### 4.3 上下文管理（省 token）

- 一个 session 一个任务，避免"顺便再帮我..."加速上下文膨胀
- 旁路问题用 `/btw`，问答不写入对话历史，不消耗上下文
- 长任务在 60-70% 时主动 `/compact`，compact 前先把关键决策记到任务文件
- 大文件用 Grep 定位 + Read 局部读取，避免整文件加载

---

## 5. 常见问题

### Q: 为什么 Claude 总是先说明计划再执行？

A: 这是 `claude-code-defensive.md` 规则的要求。复杂任务（超过 3 个步骤或涉及多个文件）必须先说明计划，等你确认后再执行。这是为了防止 Claude 盲目修改代码。

### Q: 为什么执行系统命令时 Claude 会问很多问题？

A: 这是 `ops-safety.md` 规则的要求。危险命令（如 sysctl、iptables）必须说明影响范围、风险等级和回滚方案。这是为了防止误操作导致系统故障。

### Q: 为什么 Claude 提醒我更新文档？

A: 这是 `doc-sync.md` 规则的要求。当你修改了配置（commands/skills/rules）或项目结构时，会提醒你同步更新相关文档，保持文档与代码一致。

### Q: 如何添加新的语言支持？

A: 在 `.claude/skills/` 下创建新目录（如 `rust-dev/`），添加 `SKILL.md` 文件定义触发条件和规范内容，然后更新本文档。

### Q: 为什么重构代码时 Claude 会反复确认原始代码？

A: 这是 `refactor-safety` 和 `field-mapping-safety` skill 以及 `claude-code-defensive.md` 规则的要求。重构容易丢失原始上下文，导致：
1. **表格列顺序错误**：列顺序错乱、列遗漏
2. **字段名推测错误**：使用了错误的字段名（changedAt vs createdAt）
3. **枚举映射不完整**：遗漏部分枚举值
4. **循环依赖**：提取子服务时回调父服务，导致启动失败

Claude 会：
1. 完整读取原始代码（不凭记忆或推测）
2. 制作对比清单（列/字段/枚举映射）
3. 逐项验证一致性（数量/顺序/命名）
4. 检查依赖方向（拆分后是否存在循环依赖）
5. 运行时测试（TypeScript 无法检测字段名错误）

这是为了防止"假设驱动重构"、"记忆重构"和"字段名推测错误"。

---

## 6. 目录结构

```
.claude/
├── CLAUDE.md                     # 核心配置：身份、偏好、技术栈
├── rules/                        # 规则：始终加载（精简版）
│   ├── claude-code-defensive.md  # 防御性规则
│   ├── ops-safety.md             # 运维安全（核心）
│   ├── doc-sync.md               # 文档同步
│   ├── bash-style.md             # Bash 核心规范
│   └── date-calc.md              # 日期计算规则
├── skills/                       # 技能：按需加载（完整版）
│   ├── go-dev/
│   ├── java-dev/
│   ├── frontend-dev/
│   ├── python-dev/
│   ├── bash-style/               # Bash 完整规范
│   ├── ops-safety/               # 运维安全完整规范
│   ├── redis-safety/             # Redis 安全与性能规范
│   ├── refactor-safety/          # 重构安全检查清单
│   ├── field-mapping-safety/     # 字段映射安全检查
│   ├── size-check/               # 代码简化 + 文件行数扫描
│   └── ruanzhu/                  # 软著源代码生成
├── commands/                     # 命令：显式调用
│   ├── fix.md                    # 快速修复 / 系统化调试
│   ├── review.md                 # 代码审查（full/quick/security）
│   ├── design.md                 # 技术设计（doc/checklist）
│   ├── requirement.md            # 需求分析（doc/interrogate）
│   ├── optimize.md               # 系统优化（full/ux/perf/code）
│   ├── check-toolsearch.md      # ToolSearch 可用性检查
│   ├── ruanzhu.md                # 软著源代码 DOCX 生成
│   ├── status.md
│   └── ...
└── templates/                    # 模板文件
    └── ruanzhu/                  # 软著生成脚本

tools/                            # 工具脚本（不同步到 ~/.claude/）
├── patch-toolsearch.py           # ToolSearch 域名限制解除补丁
├── sync-config.sh                # 配置同步脚本（macOS/Linux）
└── sync-config.bat               # 配置同步脚本（Windows）
```

### 核心概念

| 类型 | 加载时机 | 触发方式 | 适用场景 |
|------|---------|---------|---------|
| **Rules** | 始终加载 | 自动生效 | 核心约束、防御规则 |
| **Skills** | 按需加载 | 根据文件类型自动触发 | 语言规范、领域知识 |
| **Commands** | 调用时加载 | 用户输入 `/命令名` | 明确的工作流任务 |

### Rules 与 Skills 的关键区别

> **重要**：Rules 的 `paths` frontmatter 只是语义提示，**不影响加载**。

| 特性 | Rules | Skills |
|------|-------|--------|
| 加载时机 | 每次对话启动时**全部加载** | 启动时仅加载名称和描述 |
| 内容加载 | 完整内容立即加载 | 匹配时才加载完整内容 |
| `paths` 作用 | 条件应用（不节省 tokens） | N/A |
| Token 消耗 | 始终消耗 | 按需消耗 |

**最佳实践**：
- Rules 保持精简（核心禁止项），详细规范放 Skills
- 例如 `bash-style`：rules 放 37 行核心规则，skills 放 200+ 行完整规范

### 设计理念

1. **按需加载**：语言规范用 Skills，只在操作相关文件时加载，节省 tokens
2. **规则溯源**：每次回复声明依据的规则/技能，便于追踪和调整
3. **简洁优先**：CLAUDE.md 只放身份/偏好，具体约束放 rules

---

## 7. 开发指南

### LSP 服务器配置（v2.0.67+ 支持）

> **前提**：需安装 `@anthropic-ai/claude-code@2.0.67` 或更高版本。

#### 安装命令

```bash
# Go
go install golang.org/x/tools/gopls@latest

# TypeScript/JavaScript + Vue
npm install -g typescript typescript-language-server @vue/language-server

# Python
npm install -g pyright

# Java (macOS)
brew install jdtls
```

#### LSP 使用策略

LSP 的核心优势是"精准打击"——查找定义时只返回相关代码，而非整个文件，可节省大量 Token。

| 场景 | 建议 | 原因 |
|------|------|------|
| 查找定义/引用 | 优先用 LSP | 精准定位，节省 ~99% Token |
| 理解模块整体逻辑 | 读取完整文件 | 避免"管中窥豹"，获取完整上下文 |
| 大型项目导航 | LSP + 选择性读文件 | 混合策略最优 |

#### 注意事项

- **环境就绪**：使用前确保依赖已安装（`npm install` / `go mod download`）
- **避免过度依赖**：复杂逻辑需要读取完整文件上下文
- **LSP 失败时**：退回到读取文件的方式

### 修改现有配置

1. 在 `.claude/` 下修改对应文件
2. 在本项目目录启动 Claude Code 测试
3. 验证功能符合预期
4. 复制到 `~/.claude/` 正式使用

### 新增命令（Command）

1. 创建 `.claude/commands/<name>.md`
2. 编写 frontmatter（description）和内容
3. 测试 `/<name>` 命令
4. 更新本文档的命令列表

**命令模板**：

```markdown
---
description: 命令的简要描述
---

命令的详细说明和执行逻辑。

## 输入

「$ARGUMENTS」— 用户输入的参数

## 流程

### 第 1 步：...
### 第 2 步：...

## 输出格式

...
```

### 新增技能（Skill）

1. 创建 `.claude/skills/<name>/SKILL.md`
2. 编写 frontmatter（name、description）和内容
3. 可选：添加 `references/` 目录存放详细参考
4. 测试触发是否正确
5. 更新本文档的技能列表

**技能模板**：

```markdown
---
name: skill-name
description: 当用户操作 xxx 文件时触发。提供 xxx 开发规范。
---

# 技能名称

## 核心规范

...

## 详细参考

详细内容见 `references/` 目录。
```

### 测试验证

```bash
# 在本项目目录启动 Claude Code
cd /path/to/cc-use-exp
claude

# 测试命令
> /fix 测试问题

# 测试技能（操作相关文件类型）
> 帮我看看这个 Go 代码有什么问题

# 检查配置加载
> /memory
```
