# 故障排查指南

本文档提供常见问题的排查和解决方案。

## 安装问题

### 问题 1：网络连接失败

**症状**：
```
❌ 克隆失败，请检查网络连接
```

**原因**：
- 无法访问 GitHub
- 网络代理配置问题
- DNS 解析失败

**解决方案**：
1. 检查网络连接：`ping github.com`
2. 配置代理（如果需要）：
   ```bash
   export HTTP_PROXY=http://127.0.0.1:7890
   export HTTPS_PROXY=http://127.0.0.1:7890
   ```
3. 使用镜像源（国内用户）：
   ```bash
   git clone https://mirror.ghproxy.com/https://github.com/doccker/cc-use-exp.git
   ```

---

### 问题 2：权限错误

**症状**：
```
❌ 权限错误：无法写入 ~/.claude/
```

**原因**：
- 目录权限不足
- 文件被其他进程占用

**解决方案**：
```bash
# 检查权限
ls -la ~/.claude/

# 修复权限
chmod -R u+w ~/.claude/

# 如果目录不存在，创建它
mkdir -p ~/.claude/
```

---

### 问题 3：依赖缺失

**症状**：
```
❌ 缺少依赖：git rsync
```

**原因**：
- 系统未安装必要工具

**解决方案**：

**macOS**：
```bash
# 安装 Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装依赖
brew install git rsync
```

**Ubuntu/Debian**：
```bash
sudo apt update
sudo apt install git rsync
```

**CentOS/RHEL**：
```bash
sudo yum install git rsync
```

---

## 配置加载问题

### 问题 4：Rules 未加载

**症状**：
- `/status` 显示 Rules 数量为 0
- Claude 不遵循防御性规则

**原因**：
- 文件路径错误
- 文件权限问题
- CLI 未重启

**解决方案**：
```bash
# 1. 检查文件是否存在
ls ~/.claude/rules/

# 2. 检查文件权限
chmod +r ~/.claude/rules/*.md

# 3. 重启 Claude Code
# 退出并重新启动
```

---

### 问题 5：Skills 未触发

**症状**：
- 操作 `.go` 文件时，go-dev 技能未自动加载
- `/status` 显示 Skills 数量为 0

**原因**：
- Skills 目录为空
- `SKILL.md` frontmatter 格式错误
- 文件路径不匹配

**解决方案**：
```bash
# 1. 检查 skills 目录
ls ~/.claude/skills/

# 2. 检查 go-dev 技能
cat ~/.claude/skills/go-dev/SKILL.md | head -10

# 3. 验证 frontmatter 格式
# 应该包含：
# ---
# name: go-dev
# description: ...
# ---

# 4. 重新同步配置
cd /path/to/cc-use-exp
./tools/sync-config.sh
```

---

### 问题 6：Commands 无法执行

**症状**：
- 输入 `/fix` 提示命令不存在
- `/status` 显示 Commands 数量为 0

**原因**：
- Commands 目录为空
- 文件权限问题
- 命令名称冲突

**解决方案**：
```bash
# 1. 检查 commands 目录
ls ~/.claude/commands/

# 2. 检查文件权限
chmod +r ~/.claude/commands/*.md

# 3. 验证命令格式
cat ~/.claude/commands/fix.md | head -5

# 4. 重启 Claude Code
```

---

## Plugin Marketplace 问题

### 问题 7：Marketplace 添加失败

**症状**：
```
/plugin marketplace add doccker/cc-use-exp
❌ Failed to add marketplace
```

**原因**：
- GitHub 访问受限
- 仓库不存在或私有
- 网络问题

**解决方案**：
```bash
# 1. 验证仓库可访问
curl -I https://github.com/doccker/cc-use-exp

# 2. 检查 .claude-plugin/marketplace.json
curl https://raw.githubusercontent.com/doccker/cc-use-exp/main/.claude-plugin/marketplace.json

# 3. 使用完整 URL
/plugin marketplace add https://github.com/doccker/cc-use-exp.git
```

---

### 问题 8：Plugin 安装失败

**症状**：
```
/plugin install cc-use-exp@cc-use-exp
❌ Plugin not found
```

**原因**：
- Marketplace 未正确添加
- Plugin 名称错误
- 缓存问题

**解决方案**：
```bash
# 1. 列出已添加的 marketplaces
/plugin marketplace list

# 2. 更新 marketplace
/plugin marketplace update cc-use-exp

# 3. 重新安装
/plugin install cc-use-exp@cc-use-exp
```

---

## Codex 特定问题

### 问题 9：$skill-installer 不可用

**症状**：
```
$skill-installer install
❌ Skill not found
```

**原因**：
- Skill 未同步到 `~/.agents/skills/`
- Codex 未识别 skill

**解决方案**：
```bash
# 1. 检查 skill 是否存在
ls ~/.agents/skills/cc-skill-installer/

# 2. 手动同步
cd /path/to/cc-use-exp
./tools/sync-config.sh

# 3. 使用 Shell 脚本替代
bash <(curl -sL https://raw.githubusercontent.com/doccker/cc-use-exp/main/tools/install-codex.sh)
```

---

### 问题 10：Profile 切换无效

**症状**：
```
codex -p cc-balanced
# 但行为未改变
```

**原因**：
- Profile 未正确合并到 `~/.codex/config.toml`
- Profile 配置错误

**解决方案**：
```bash
# 1. 检查 config.toml
cat ~/.codex/config.toml | grep -A 10 "\[profiles.cc-balanced\]"

# 2. 重新同步
cd /path/to/cc-use-exp
./tools/sync-config.sh

# 3. 验证 profile
codex -p cc-balanced --version
```

---

## Gemini CLI 特定问题

### 问题 11：认证失败

**症状**：
```
❌ Authentication failed
```

**原因**：
- API Key 未配置
- OAuth 认证过期

**解决方案**：

**方式 A：OAuth 重新认证**
```bash
# 删除旧凭证
rm ~/.gemini/oauth_creds.json

# 重新启动 Gemini CLI
gemini
# 浏览器会自动打开认证页面
```

**方式 B：配置 API Key**
```bash
# 获取 API Key：https://aistudio.google.com/app/apikey
echo 'GEMINI_API_KEY="你的API密钥"' >> ~/.gemini/.env
```

---

### 问题 12：网络超时（国内用户）

**症状**：
```
❌ Connection timeout
```

**原因**：
- 无法访问 Google API
- 网络代理未配置

**解决方案**：
```bash
# 1. 复制代理配置模板
cp .gemini/.env.example .gemini/.env

# 2. 编辑 .env 文件
# HTTP_PROXY=http://127.0.0.1:你的端口
# HTTPS_PROXY=http://127.0.0.1:你的端口

# 3. 重启 Gemini CLI
gemini
```

---

## Cursor 特定问题

### 问题 13：Rules 未生效

**症状**：
- Cursor Agent 不遵循规则
- `.cursor/rules/` 中的规则未加载

**原因**：
- Rules 格式错误（`.mdc` 格式）
- `alwaysApply` 或 `globs` 配置错误

**解决方案**：
```bash
# 1. 检查 rules 文件
cat .cursor/rules/defensive.mdc | head -10

# 2. 验证 frontmatter 格式
# ---
# alwaysApply: true
# ---

# 3. 重启 Cursor
```

---

### 问题 14：Skills 未自动触发

**症状**：
- 操作 `.go` 文件时，go-dev 技能未加载

**原因**：
- Skills 的 `description` 不够明确
- Cursor Agent 未识别语义

**解决方案**：
```bash
# 1. 检查 skill 的 description
cat ~/.cursor/skills/go-dev/SKILL.md | grep -A 5 "description"

# 2. 手动引用 skill
# 在 Cursor Agent 中输入：@go-dev

# 3. 使用命令替代
/fix 问题描述
```

---

## 通用调试技巧

### 启用调试模式

**Claude Code**：
```bash
claude --debug
```

**Codex**：
```bash
codex --verbose
```

**Gemini CLI**：
```bash
gemini --log-level debug
```

### 检查日志文件

**Claude Code**：
```bash
tail -f ~/.claude/logs/claude-code.log
```

**Codex**：
```bash
tail -f ~/.codex/logs/codex.log
```

**Gemini CLI**：
```bash
tail -f ~/.gemini/logs/gemini-cli.log
```

### 清理缓存

**Claude Code**：
```bash
rm -rf ~/.claude/cache/
```

**Codex**：
```bash
rm -rf ~/.codex/cache/
```

**Gemini CLI**：
```bash
rm -rf ~/.gemini/cache/
```

---

## 获取帮助

如果以上方法都无法解决问题，请：

1. **查看完整日志**：启用调试模式并复制完整错误信息
2. **检查版本**：确认使用的是最新版本
3. **提交 Issue**：[GitHub Issues](https://github.com/doccker/cc-use-exp/issues)
4. **联系作者**：参考 README 中的联系方式

提交 Issue 时，请包含：
- 操作系统和版本
- CLI/IDE 版本
- 完整错误信息
- 复现步骤
