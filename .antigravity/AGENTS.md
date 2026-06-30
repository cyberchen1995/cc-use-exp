@./rules/file-size-limit.md
@./rules/frontend-style.md
@./rules/defensive.md
@./rules/ops-safety.md
@./rules/doc-sync.md
@./rules/chinese-language.md

# AGENTS.md - Antigravity 智能工作规则 (Optimized)

版本：v1.4
作者：wwj
更新：2026-06-30

---

## 个人身份与全局偏好 (Memory First)

- **全局内存使用**：首次启动或技术栈偏好变更时，**必须**调用 `save_memory` 将您的技术栈（Go/Java/Vue）、数据库偏好（SQLite/MySQL）和沟通风格写入全局内存。
- **配置降级**：若当前项目或全局缺少专属配置，Antigravity 将自动回退并依赖全局内存提供的个人偏好进行编码。

---

## 沟通语言 (Communication)

> CRITICAL: You MUST respond in Simplified Chinese at ALL times unless explicitly requested otherwise.
> 详细规范见 `rules/chinese-language.md`。默认使用简体中文，技术术语保持英文原文。

---

## UI 风格与审美约束 (UI Style)

- **核心风格**：默认使用 **Element Plus** 主题，保持简洁、专业、克制的企业后台风格。
- **严格禁止**：严禁生成带有“AI 风格”的炫酷 UI。禁止使用蓝紫色霓虹渐变、发光描边、玻璃拟态（glassmorphism）、赛博风或暗黑科技风。
- **视觉降噪**：禁止在大面积背景使用渐变或装饰性几何图形。

---

## 技术栈默认偏好 (Tech Stack)

- **前端框架**：优先使用 **Vue 3 (Composition API)** + **TypeScript**。
- **状态管理**：优先使用 **Pinia** (Composition API 风格)。
- **CSS 规范**：优先使用原生 CSS (Scoped)，除非项目已有明确的其他规范（如 Tailwind）。

---

## 核心原则与防御策略

> 详细规范见 `rules/defensive.md` 和 `rules/file-size-limit.md`

- **质量底线**：严禁篡改测试、严禁幽灵代码、严禁添加 AI 元数据。提供完整实现，**严禁使用 MVP、占位符或 TODO**。
- **行数约束（全局生效）**：`rules/file-size-limit.md` 已通过 `@import` 在所有项目自动加载。Java 300 / Go 400 / Vue·TSX 200 / TS·JS·Python 300 为默认阈值，新建文件预估超限必须先拆分骨架，禁止“先写完再拆”；项目级 `AGENTS.md` 可定义 `## 文件行数限制` 章节覆盖默认值。
- **复杂任务流**：涉及 3+ 文件时执行 **“方案说明 -> 用户确认 ⏸️ -> 分步实施”**。
- **流式导出安全**：当收到生成或修改包含数据导出、Excel/CSV 下载、PDF 报表生成的需求时，必须主动使用 `activate_skill` 加载 `streaming-export-safety` 规范。

---



## 工具链与自愈能力 (Self-Healing & Fail-Fast)

### 1. 工具选择优先级
- **文档查询**：首选 `context7`（精准溯源）。
- **任务规划**：复杂重构强制使用 `sequentialthinking`。
- **页面审计**：前端布局问题首选 `chrome-devtools`。

### 2. 网络异常与防挂起机制 (Anti-Hang) ⚠️
当调用 MCP 工具（特别是 `sequentialthinking`, `context7`）遇到**超时、网络断开或无响应**时，必须严格执行以下流程：
- **立即中止**：严禁死循环重试或静默等待。
- **抛出提示**：立即向用户输出标准化的错误提示与排查建议：
  > "⚠️ **[工具名称] 调用失败/超时。**
  > **可能原因**：网络波动、npx 进程僵死或 MCP 服务未启动。
  > **排查建议**：
  > 1. 在终端运行 `/mcp list` 检查服务连接状态。
  > 2. 检查网络代理设置。
  > 3. 若由于 npx 下载卡顿，建议手动终止 Node 进程或改为全局安装。"
- **自动降级 (Fallback)**：在提示用户后，主动询问是否使用降级方案继续（例如：放弃 `context7` 改用普通的 `read_file` 检索本地文档；放弃 `sequentialthinking` 改为标准的单步思考输出）。

---

## 规则按需加载说明

本项目采用 **“Frontmatter Paths”** 技术实现规则的按需激活。
- **全局规则**：`defensive.md`, `file-size-limit.md`, `doc-sync.md` (全路径匹配)。
- **领域规则**：`frontend-style.md`, `ops-safety.md` (仅匹配相关后缀时加载)。

---

## 工程执行逻辑

- **数据对齐**：修改 API 前必须 `read_file` 后端 Handler 确认真实 JSON 结构。
- **写入安全**：多行代码写入强制使用 `write_file`。
- **LSP 导航**：大型项目查找引用优先使用 `gopls` 等 LSP 工具。

---

> 📋 本回复遵循：`defensive` - [章节]
