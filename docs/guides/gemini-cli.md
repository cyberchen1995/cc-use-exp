
---

# Part 2: Gemini CLI 配置（前端设计）

> **定位**：Gemini CLI 专注于前端设计和开发，技术栈为 Vue 3 + TypeScript + Element Plus。

---

## 1. 快速开始

### 1.1 零费力（自动生效）- GEMINI.md

**你需要做什么：什么都不用做**

GEMINI.md 自动加载，提供以下保护：

| 规则 | 作用 |
|------|------|
| UI 风格约束 | 禁止霓虹渐变、玻璃拟态、赛博风 |
| 代码质量 | 完整实现，禁止 MVP/占位/TODO |
| 中文交流 | 统一使用中文回复和注释 |
| MCP 工具指南 | 规范工具调用，避免滥用 |

**效果示例**：
- Gemini 不会生成"AI 风格"的炫酷 UI
- 默认使用 Element Plus 主题，保持企业后台风格
- 自动使用 Composition API + TypeScript

### 1.2 低费力（自动触发）- Skills

**你需要做什么：正常写代码**

修改对应语言的文件或调整页面布局时，Gemini 会自动激活对应技能（独立维护在 `.gemini/skills/`，语义与其他工具保持一致）：

| 技能 | 触发条件 | 提供的帮助 |
|------|---------|-----------|
| `frontend-safety` | 修改 Vue/React 组件、调整布局、创建覆盖层 | 数据绑定保护、布局一致性、覆盖层定位规范 |
| `go-dev` | 操作 `.go` 文件 | 命名约定、错误处理、并发编程、测试规范 |
| `java-dev` | 操作 `.java` 文件 | 命名约定、异常处理、Spring 规范、Java 最佳实践 |
| `python-dev` | 操作 `.py` 文件 | 类型注解、Pydantic、pytest、uv 工具链 |
| `bash-style` | 操作 `.sh/Dockerfile/Makefile/.md` 等 | 注释规范、tee 写入、heredoc、脚本规范 |
| `ops-safety` | 执行系统命令、服务器运维 | 风险说明、回滚方案、问题排查原则 |
| `api-design-safety` | 设计或修改 REST API 响应结构 | 防止泛型重载歧义、响应字段语义混淆 |
| `storage-url-safety` | 使用 MinIO/OSS/S3 等对象存储 | URL 策略选择、Bucket 配置、安全性检查 |

**效果示例**：
- 修改 Vue 组件时，自动保护数据绑定和事件不被意外修改
- 调整布局时，确保间距使用 4px 倍数、与其他页面一致
- 开发 Go 或 Java 代码时，Gemini CLI 同样能提供专业的编码规范支持

### 1.3 中费力（显式调用）- Commands

**你需要做什么：输入 `/命令名`**

| 命令 | 用途 | 使用示例 |
|------|------|---------|
| `/layout` | 重构页面布局 | `/layout src/views/Home.vue` |
| `/layout-check` | 检查页面布局一致性 | `/layout-check src/views/` |
| `/vue-split` | 拆分大型 Vue 文件 | `/vue-split src/views/Home.vue` |
| `/fix` | 快速修复前端 Bug | `/fix 按钮点击无响应` |
| `/code-review` | 审查前端代码 | `/code-review` |
| `/quick-review` | 快速审查 | `/quick-review` |
| `/commit-msg` | 生成 git commit message | `/commit-msg` 或 `/commit-msg all` |
| `/debug` | 复杂问题排查 | `/debug 表格数据不显示` |
| `/patch-http` | 解除自定义 HTTP Base URL 限制 | `/patch-http` |

### 1.4 Gemini CLI 推荐扩展（声明式安装）

本项目通过 `.gemini/extensions.json` 声明了推荐的扩展。

| 扩展 | 用途 | 安装地址 |
|------|------|---------|
| `context7` | 提供精准的第三方库文档查询和代码示例（Context7 增强） | [GitHub](https://github.com/upstash/context7) |
| `chrome-devtools-mcp` | 用于前端页面真机调试、Lighthouse 审计与性能监控 | [GitHub](https://github.com/ChromeDevTools/chrome-devtools-mcp) |

**推荐安装方式：**
运行 `./tools/sync-config.sh`，脚本会自动检测缺失的扩展并引导你一键安装。

**手动一键安装：**
```bash
gemini extensions install https://github.com/upstash/context7 && \
gemini extensions install https://github.com/ChromeDevTools/chrome-devtools-mcp
```

更多扩展请访问：[Gemini Extensions 商店](https://geminicli.com/extensions/)

---

## 2. 前端场景速查

| 场景 | 推荐方式 | 费力度 |
|------|---------|--------|
| 写 Vue 组件 | 直接写，规则自动生效 | ⭐ |
| 页面布局重构 | `/layout 文件路径` | ⭐⭐ |
| 布局一致性检查 | `/layout-check` | ⭐⭐ |
| Vue 文件过大 | `/vue-split 文件路径` | ⭐⭐ |
| 修复样式问题 | `/fix 问题描述` | ⭐⭐ |
| 组件代码审查 | `/code-review` | ⭐⭐ |
| 查 Vue/Element 文档 | 让 Gemini 调用 Context7 | ⭐ |
| 响应式适配 | 描述断点需求 | ⭐⭐ |
| 复杂交互调试 | `/debug 问题描述` | ⭐⭐⭐ |
| 解除 HTTP URL 限制 | `/patch-http` | ⭐⭐ |

```
布局问题？
├─ 简单调整 → /fix 问题描述
├─ 整体重构 → /layout 文件路径
└─ 一致性检查 → /layout-check

组件开发？
├─ 新组件 → 描述需求，让 Gemini 生成
└─ 改现有 → 先 /quick-review 或 /code-review，再修改

样式问题？
├─ 单个元素 → /fix 样式描述
└─ 整体风格 → 检查是否符合 Element Plus 规范
```

---

## 3. 最佳实践

### 3.1 UI 风格约束

**后台管理系统（默认风格）**

| 要素 | 要求 |
|------|------|
| 主题 | Element Plus 默认主题 |
| 配色 | 黑白灰为主 + 1 个主色点缀 |
| 布局 | 标准后台布局（侧边栏 + 顶栏 + 内容区） |
| 动效 | 克制，仅保留必要交互反馈 |

**严格禁止**：
- ❌ 蓝紫色霓虹渐变、发光描边
- ❌ 玻璃拟态（glassmorphism）
- ❌ 赛博风、暗黑科技风
- ❌ 大面积渐变、装饰性几何图形
- ❌ UI 文案中使用 emoji

### 3.2 Vue 组件规范

```vue
<!-- ✅ 推荐写法 -->
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { User } from '@/types'

const props = defineProps<{
  userId: number
}>()

const loading = ref(false)
const user = ref<User | null>(null)
</script>

<template>
  <div class="user-card">
    <!-- 内容 -->
  </div>
</template>

<style scoped>
.user-card {
  padding: 16px;
}
</style>
```

### 3.3 MCP 工具使用

| 工具 | 使用场景 | 技巧 |
|------|---------|------|
| Context7 | 查 Vue/Element Plus 文档 | 先 `resolve-library-id`，再查文档 |
| Desktop Commander | 批量修改组件文件 | 设置路径范围，避免全仓扫描 |
| Sequential-Thinking | 复杂页面设计 | 规划前必用 |

**Context7 查询示例**：
```
帮我查一下 Element Plus 的 Table 组件如何实现可编辑单元格
```

### 3.4 避免的做法

- ❌ 不要让 Gemini 自由发挥 UI 设计
- ❌ 不要忽略 Element Plus 现有组件
- ❌ 不要在简单问题上用复杂命令
- ❌ 不要跳过代码审查直接提交

---

## 4. 常见问题

### Q: Gemini 生成的 UI 太花哨怎么办？

A: GEMINI.md 中已有 UI 风格约束。如果还是生成花哨样式，可以明确说：
```
请使用 Element Plus 默认主题，保持简洁的后台管理风格，不要使用渐变和装饰性元素
```

### Q: 如何让 Gemini 查最新的 Vue 文档？

A: Gemini 会自动调用 Context7 查询文档。你也可以直接说：
```
帮我查一下 Vue 3 的 defineModel 怎么用
```

### Q: /layout 命令支持什么输入？

A: 支持以下输入方式：
- 文件路径：`/layout src/views/Home.vue`
- URL：`/layout https://example.com`
- 描述需求：`/layout 把这个页面改成左右两栏布局`

### Q: 组件太复杂，Gemini 生成不完整怎么办？

A: 分步骤处理：
1. 先让 Gemini 生成组件框架
2. 逐个功能点完善
3. 最后 `/code-review` 检查

---

## 5. 目录结构

```
.gemini/
├── .env.example        # 网络代理配置模板（需重命名为 .env）
├── GEMINI.md           # 核心规则（通过 @import 引入 rules）
├── settings.json       # 用户设置
├── policies/           # 安全策略（允许 git 等命令执行）
│   ├── git-rules.toml
│   └── help-rules.toml
├── rules/              # 规则：通过 @import 始终加载
│   ├── defensive.md        # 防御性编码规范
│   ├── doc-sync.md         # 文档同步规范
│   ├── ops-safety.md       # 运维安全规范
│   ├── file-size-limit.md  # 文件行数限制
│   └── frontend-style.md   # 前端规范补充
├── skills/             # 技能：按需激活（v0.24.0+）
│   ├── bash-style/
│   ├── frontend-safety/
│   ├── go-dev/
│   ├── java-dev/
│   ├── ops-safety/
│   └── python-dev/
└── commands/           # 自定义命令（.toml 格式）
    ├── layout.toml         # 布局重构
    ├── layout-check.toml   # 布局一致性检查
    ├── vue-split.toml      # Vue 文件拆分
    ├── fix.toml            # 快速修复
    ├── debug.toml          # 系统化调试
    ├── code-review.toml    # 正式审查
    ├── quick-review.toml   # 快速审查
    ├── commit-msg.toml     # 生成 commit message
    └── patch-http.toml     # 解除 HTTP Base URL 限制
├── scripts/            # 辅助脚本
    └── patch-http.sh       # 补丁执行脚本
```

---

## 6. 配置层级

Gemini CLI 支持层级配置，优先级从低到高：

1. 系统默认 → `/etc/gemini-cli/`
2. **用户全局** → `~/.gemini/`
3. **项目级** → `<project>/.gemini/`
4. 环境变量
5. 命令行参数

GEMINI.md 同样支持层级：
- 全局：`~/.gemini/GEMINI.md`
- 项目：`<project>/GEMINI.md`
- 子目录：`<subdir>/GEMINI.md`

---

## 7. 认证配置

Gemini CLI 需要认证才能使用，支持两种认证方式。

### 认证方式对比

| 方式 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| **OAuth 登录** | edu 账号、企业账号 | 配额更高、无需管理密钥 | 首次需浏览器认证 |
| **API Key** | 个人账号、自动化场景 | 配置简单、无需浏览器 | 免费配额有限 |

> **建议**：edu 账号或企业账号优先使用 OAuth 登录，可获得更高的使用配额。

### 方式 A：OAuth 登录（推荐 edu/企业账号）

首次启动时会自动跳转浏览器认证：

```bash
gemini
# 浏览器会打开 Google 登录页面
# 登录后授权即可，之后会自动保存凭证
```

认证信息保存在 `~/.gemini/` 目录下，后续启动无需重复认证。

### 方式 B：API Key（推荐个人账号）

#### 获取 API Key

1. 访问 [Google AI Studio](https://aistudio.google.com/app/apikey)
2. 登录 Google 账号
3. 点击 "Create API Key" 创建密钥
4. 复制生成的密钥

#### 配置 API Key

```bash
# 将密钥写入 ~/.gemini/.env（推荐）
echo 'GEMINI_API_KEY="你的API密钥"' >> ~/.gemini/.env
```

或者添加到 shell 配置文件：

```bash
# ~/.zshrc 或 ~/.bashrc
export GEMINI_API_KEY="你的API密钥"

# 重新加载配置
source ~/.zshrc
```

### 验证认证

```bash
gemini
# 如果不再跳转浏览器认证，说明配置成功
```

> **注意**：API Key 是敏感信息，请勿提交到代码仓库或分享给他人。

