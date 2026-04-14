---
description: 一键安装 cc-use-exp 配置体系
---

# cc-use-exp 安装器

一键安装 cc-use-exp AI 编码助手配置体系到 Claude Code。

---

## 执行步骤

### 第 1 步：检查安装状态

```bash
# 检查三种可能的安装位置
EXTERNAL_DIR="$HOME/.claude/external/cc-use-exp"
PLUGIN_INSTALLED="$HOME/.claude/plugins/installed/cc-use-exp@cc-use-exp"
PLUGIN_CACHE=$(find "$HOME/.claude/plugins/cache" -name "cc-use-exp" -type d 2>/dev/null | head -1)

if [ -n "$PLUGIN_CACHE" ] || [ -d "$PLUGIN_INSTALLED" ]; then
  echo "✅ 检测到通过 Plugin Marketplace 安装"
  echo ""
  echo "安装位置: ${PLUGIN_CACHE:-$PLUGIN_INSTALLED}"
  echo ""
  echo "📝 说明："
  echo "- Plugin Marketplace 安装会自动同步 skills 和 commands"
  echo "- 如需完整配置（rules、templates 等），请继续执行同步"
  echo ""
  echo "是否执行完整同步？"
  INSTALL_DIR="${PLUGIN_CACHE:-$PLUGIN_INSTALLED}"
elif [ -d "$EXTERNAL_DIR" ]; then
  echo "✅ 检测到通过 external 方式安装"
  echo ""
  echo "安装位置: $EXTERNAL_DIR"
  echo ""
  cd "$EXTERNAL_DIR"
  echo "当前版本:"
  git log -1 --pretty=format:"%h - %s (%ar)" 2>/dev/null || echo "无法获取版本信息"
  echo ""
  echo ""
  echo "是否更新到最新版本？"
  INSTALL_DIR="$EXTERNAL_DIR"
fi
```

如果已安装，询问用户：
- Plugin Marketplace 安装 → 询问是否执行完整同步
- External 安装 → 询问是否更新
- 用户回答"是" → 继续执行
- 用户回答"否" → 退出

### 第 2 步：Clone 仓库（仅全新安装）

**仅在未检测到任何安装时执行此步骤。**

```bash
echo "📦 开始安装 cc-use-exp..."
echo ""

# 创建外部扩展目录
INSTALL_DIR="$HOME/.claude/external/cc-use-exp"
mkdir -p "$HOME/.claude/external"

# Clone 仓库
git clone https://github.com/doccker/cc-use-exp.git "$INSTALL_DIR"

if [ $? -ne 0 ]; then
  echo "❌ 克隆失败，请检查网络连接"
  exit 1
fi

echo "✓ 仓库克隆完成"
```

### 第 3 步：执行同步脚本

```bash
echo ""
echo "🔧 同步配置到 Claude Code..."
echo ""

cd "$INSTALL_DIR"

# 执行同步脚本
if [ -f "./tools/sync-config.sh" ]; then
  ./tools/sync-config.sh
else
  echo "❌ 错误：找不到同步脚本"
  exit 1
fi
```

### 第 4 步：显示安装结果

```bash
echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 已同步配置到："
echo "  - ~/.claude/rules/"
echo "  - ~/.claude/skills/"
echo "  - ~/.claude/commands/"
echo "  - ~/.claude/templates/"
echo ""
echo "🔄 配置已生效，无需重启"
echo ""
echo "💡 后续操作："
echo "  - 更新配置：/skill-update"
echo "  - 查看状态：/status"
echo "  - 卸载：手动删除 $INSTALL_DIR 和 ~/.claude/ 下的配置"
echo ""
echo "📖 文档：https://github.com/doccker/cc-use-exp"
```

---

## 错误处理

**网络错误**：
```bash
if ! git clone ...; then
  echo "❌ 网络错误，请检查："
  echo "  1. 网络连接是否正常"
  echo "  2. 是否可以访问 GitHub"
  echo "  3. 是否需要配置代理"
  exit 1
fi
```

**权限错误**：
```bash
if [ ! -w "$HOME/.claude" ]; then
  echo "❌ 权限错误：无法写入 ~/.claude/"
  echo "请检查目录权限"
  exit 1
fi
```

---

## 注意事项

- 安装位置：`~/.claude/external/cc-use-exp/`
- 配置同步到：`~/.claude/rules/`、`~/.claude/skills/`、`~/.claude/commands/`、`~/.claude/templates/`
- 不会覆盖用户自定义配置（sync-config.sh 使用增量同步）
- 支持重复安装（自动检测并提示更新）

---

## 规则溯源

```
> 📋 本回复遵循：`skill-install` - cc-use-exp 安装器
```
