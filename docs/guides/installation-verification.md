# 安装验证指南

安装完成后，请按照以下步骤验证配置是否正确加载。

## Claude Code

### 验证配置加载

```bash
/status
```

应该看到：
- ✅ Rules 已加载（6+ 个规则）
- ✅ Skills 已加载（10+ 个技能）
- ✅ Commands 已加载（15+ 个命令）

### 验证 Plugin Marketplace

```bash
/plugin list
```

应该看到 `cc-use-exp@cc-use-exp` 在已安装列表中。

### 测试基本功能

```bash
# 测试命令
/fix 测试问题

# 测试技能（创建一个 .go 文件）
# 应该自动触发 go-dev 技能
```

---

## Codex

### 验证配置加载

```bash
$cc-status
```

应该看到：
- ✅ Global AGENTS 已加载
- ✅ Rules 已加载
- ✅ Skills 已同步到 `~/.agents/skills/`

### 验证文件存在

```bash
# 检查 AGENTS.md
cat ~/.codex/AGENTS.md | head -20

# 检查 skills
ls ~/.agents/skills/ | grep cc-
```

### 测试基本功能

```bash
# 测试 workflow skill
$fix 测试问题

# 测试 commit message 生成
$commit-msg
```

---

## Gemini CLI

### 验证配置加载

启动 Gemini CLI 后，检查配置：

```bash
# 检查 skills
/skills list
```

应该看到：
- `go-dev`
- `java-dev`
- `frontend-dev`
- `python-dev`
- 等技能

### 验证文件存在

```bash
# 检查 GEMINI.md
cat ~/.gemini/GEMINI.md | head -20

# 检查 skills
ls ~/.gemini/skills/
```

### 测试基本功能

```bash
# 测试命令
/fix 测试问题

# 测试 Context7 查询
帮我查一下 Vue 3 的 defineModel 怎么用
```

---

## Cursor

### 验证配置加载

在 Cursor 中打开项目，检查：

1. **Rules**：查看 `.cursor/rules/` 目录
   ```bash
   ls .cursor/rules/
   ```
   应该看到 `.mdc` 文件

2. **Skills**：查看 `~/.cursor/skills/`
   ```bash
   ls ~/.cursor/skills/ | grep -E "(go-dev|java-dev|frontend-dev)"
   ```

### 测试基本功能

在 Cursor Agent 中：

```bash
# 测试命令
/fix 测试问题

# 测试技能（创建一个 .go 文件）
# 应该自动触发 go-dev 技能
```

---

## 常见验证问题

### 配置未加载

**症状**：`/status` 或 `$cc-status` 显示配置未加载

**解决方案**：
1. 确认安装脚本执行成功
2. 重启 CLI/IDE
3. 检查文件权限：`ls -la ~/.claude/` 或 `~/.codex/`

### Skills 未触发

**症状**：操作 `.go` 文件时，go-dev 技能未自动加载

**解决方案**：
1. 确认 skills 目录存在：`ls ~/.claude/skills/go-dev/`
2. 检查 `SKILL.md` 的 frontmatter 是否正确
3. 重启 CLI/IDE

### Commands 无法执行

**症状**：输入 `/fix` 提示命令不存在

**解决方案**：
1. 确认 commands 目录存在：`ls ~/.claude/commands/`
2. 检查文件权限：`chmod +r ~/.claude/commands/*.md`
3. 重启 CLI/IDE

---

## 完整性检查清单

### Claude Code

- [ ] `~/.claude/CLAUDE.md` 存在
- [ ] `~/.claude/rules/` 包含 6+ 个 `.md` 文件
- [ ] `~/.claude/skills/` 包含 10+ 个子目录
- [ ] `~/.claude/commands/` 包含 15+ 个 `.md` 文件
- [ ] `/status` 命令可执行

### Codex

- [ ] `~/.codex/AGENTS.md` 存在
- [ ] `~/.codex/rules/` 包含 `.rules` 文件
- [ ] `~/.agents/skills/` 包含 `cc-*` 子目录
- [ ] `$cc-status` 命令可执行

### Gemini CLI

- [ ] `~/.gemini/GEMINI.md` 存在
- [ ] `~/.gemini/skills/` 包含技能子目录
- [ ] `~/.gemini/commands/` 包含 `.toml` 文件
- [ ] `/skills list` 命令可执行

### Cursor

- [ ] `.cursor/rules/` 包含 `.mdc` 文件
- [ ] `~/.cursor/skills/` 包含技能子目录
- [ ] `/fix` 命令可执行
