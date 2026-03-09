---
name: size-check
description: Review changed code for reuse, quality, and efficiency, then fix any issues found. Also scans project files for size limit violations.
---

# Size Check - 代码简化与文件行数检查

## 触发方式

用户执行 `/size-check` 或描述"简化代码"、"检查文件大小"时触发。

---

## 功能 1：代码简化（原有能力）

审查变更代码的复用性、质量和效率，修复发现的问题。

### 检查项

| 检查项 | 说明 |
|--------|------|
| 重复代码 | 提取公共方法/组件 |
| 过度抽象 | 简化不必要的设计模式 |
| 冗余逻辑 | 合并可简化的条件分支 |
| 未使用代码 | 删除死代码、无用 import |

---

## 功能 2：文件行数扫描

### 行数阈值

| 语言 | 上限 | 拆分方式 |
|------|------|---------|
| Java | 300 | Service 拆分职责、提取 Helper/Converter |
| Go | 400 | 按功能拆分同包文件 |
| Vue | 200 | 提取子组件、composables |
| TSX/JSX | 200 | 提取子组件 |
| TypeScript/JS | 300 | 提取工具函数、常量、类型 |
| Python | 300 | 按职责拆分模块 |

### 执行流程

**全项目扫描模式**（用户未指定文件时）：

```
1. 扫描项目所有代码文件（排除 node_modules、vendor、dist、build、.git）
2. 统计每个文件行数，对照阈值标记超限文件
3. 检测 Markdown 文件中的重复章节（相同标题出现多次）
4. 输出超限清单 + 拆分建议
```

**单文件模式**（用户指定文件时）：

```
1. 检查代码复用、质量、效率
2. 检查行数是否超限
3. 如果超限，给出具体拆分方案
```

### 输出格式

```markdown
## 文件行数扫描结果

### 超限文件

| 文件 | 行数 | 阈值 | 超限 | 建议 |
|------|------|------|------|------|
| path/to/file.py | 450 | 300 | +150 | 按职责拆分为 xxx.py 和 yyy.py |

### 合规文件（前 10 个最大的）

| 文件 | 行数 | 阈值 | 余量 |
|------|------|------|------|
| path/to/big.go | 380 | 400 | 20 |

### 总结

- 扫描文件数：N
- 超限文件数：N
- 建议操作：[具体建议]
```

### 扫描排除规则

以下目录和文件不参与扫描：

- 目录：`node_modules/`、`vendor/`、`dist/`、`build/`、`.git/`、`__pycache__/`、`.venv/`
- 文件：`*.min.js`、`*.min.css`、`*.lock`、`*.sum`
- 配置：`.toml`、`.json`、`.yaml`、`.yml`（命令/配置文件不适用代码行数限制）
- 文档：`.md`（Markdown 无硬性行数限制，但检测重复章节）

---

## 功能 3：CSS 提取检查

### 触发条件

扫描 Vue/TSX/JSX 文件时，检测内联 `<style>` 块行数。

### 检查规则

| 检查项 | 条件 | 建议 |
|--------|------|------|
| 内联样式过长 | `<style>` 块超过 30 行 | 提取公共样式到 `assets/styles/` |
| 非 scoped 全局样式 | Vue SFC 中存在 `<style>`（无 scoped） | 移到 `assets/styles/common.scss` |

**不触发**：`<style scoped>` 且行数 ≤ 30 行的组件级样式。

### 输出格式

在文件行数扫描结果中追加：

```markdown
### CSS 提取建议

| 文件 | <style> 行数 | 类型 | 建议 |
|------|-------------|------|------|
| src/views/User.vue | 45 | scoped | 提取公共部分（变量/mixin）到 assets/styles/ |
| src/views/Home.vue | 12 | 非 scoped | 移到 assets/styles/common.scss |
```

---

## 安全原则

- **只报告，不自动重构** —— 超限文件给出拆分建议，由用户确认后再执行
- **不改变现有行为** —— 拆分后的入口文件保持原有接口
- **渐进式处理** —— 优先处理超限最严重的文件

---

## 规则溯源

```
> 📋 本回复遵循：`size-check` - [功能1/功能2/功能3]
```
