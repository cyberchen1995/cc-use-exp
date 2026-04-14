#!/bin/bash
set -e

# Cursor 一键安装脚本
# 用法: bash <(curl -sL https://raw.githubusercontent.com/doccker/cc-use-exp/main/tools/install-cursor.sh)

echo "=== cc-use-exp Cursor 安装器 ==="
echo ""

# 依赖检查
check_dependencies() {
    local missing_deps=()

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v rsync &> /dev/null; then
        missing_deps+=("rsync")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ 缺少依赖：${missing_deps[*]}"
        echo ""
        echo "请先安装："
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

echo "🔍 检查依赖..."
check_dependencies
echo "  ✓ git"
echo "  ✓ rsync"
echo ""

# 检查是否已安装
INSTALL_DIR="$HOME/.cursor/.cc-use-exp"
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  检测到已安装"
    echo ""
    echo "安装位置: $INSTALL_DIR"
    cd "$INSTALL_DIR"
    echo "当前版本: $(git log -1 --pretty=format:'%h - %s (%ar)' 2>/dev/null || echo '无法获取版本信息')"
    echo ""
    echo "是否更新到最新版本？(y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ 取消安装"
        exit 0
    fi
    echo ""
    echo "🔄 更新现有安装..."
    if ! git pull origin main; then
        echo "❌ 更新失败，请检查网络连接或手动更新"
        exit 1
    fi
else
    echo "📦 开始安装..."
    echo ""

    # 检查目录权限
    if [ ! -w "$HOME" ]; then
        echo "❌ 权限错误：无法写入 $HOME"
        exit 1
    fi

    # 创建父目录
    mkdir -p "$HOME/.cursor"

    # Clone 到 Cursor 配置目录
    if ! git clone https://github.com/doccker/cc-use-exp.git "$INSTALL_DIR"; then
        echo "❌ 克隆失败，请检查："
        echo "  1. 网络连接是否正常"
        echo "  2. 是否可以访问 GitHub"
        echo "  3. 是否需要配置代理"
        exit 1
    fi
    cd "$INSTALL_DIR"
    echo "  ✓ 仓库克隆完成"
fi

echo ""
echo "🔧 同步配置到 Cursor..."

# 执行同步脚本（只同步 Cursor 部分）
if [ -f "./tools/sync-config.sh" ]; then
    # 提取 Cursor 同步逻辑
    CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
    CURSOR_TEMPLATES_DIR="$HOME/.cursor/templates"
    CURSOR_RULES_DIR="$HOME/.cursor/rules"

    mkdir -p "$CURSOR_SKILLS_DIR"
    mkdir -p "$CURSOR_TEMPLATES_DIR"
    mkdir -p "$CURSOR_RULES_DIR"

    # 同步 skills
    if [ -d ".cursor/skills" ]; then
        rsync -a --delete .cursor/skills/ "$CURSOR_SKILLS_DIR/"
        echo "  ✓ skills/"
    fi

    # 同步 commands（转换为 skills）
    if [ -d ".cursor/commands" ]; then
        for cmd_file in .cursor/commands/*.md; do
            if [ -f "$cmd_file" ]; then
                cmd_name=$(basename "$cmd_file" .md)
                cmd_skill_dir="$CURSOR_SKILLS_DIR/$cmd_name"
                mkdir -p "$cmd_skill_dir"
                cp "$cmd_file" "$cmd_skill_dir/SKILL.md"
            fi
        done
        echo "  ✓ commands/ (转换为 skills)"
    fi

    # 同步 templates
    if [ -d ".cursor/templates" ]; then
        rsync -a --delete .cursor/templates/ "$CURSOR_TEMPLATES_DIR/"
        echo "  ✓ templates/"
    fi

    # 同步 rules（兼容性补充）
    if [ -d ".cursor/rules" ]; then
        rsync -a .cursor/rules/ "$CURSOR_RULES_DIR/"
        echo "  ✓ rules/ (兼容性补充)"
    fi

    # 创建 manifest 标记
    echo "cc-use-exp" > "$CURSOR_SKILLS_DIR/.cc-use-exp-managed"
    echo "cc-use-exp" > "$CURSOR_TEMPLATES_DIR/.cc-use-exp-managed"
    echo "cc-use-exp" > "$CURSOR_RULES_DIR/.cc-use-exp-managed"
else
    echo "❌ 错误：找不到同步脚本"
    exit 1
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 已同步配置到："
echo "  - $CURSOR_SKILLS_DIR"
echo "  - $CURSOR_TEMPLATES_DIR"
echo "  - $CURSOR_RULES_DIR"
echo ""

# 安装验证
echo "🔍 验证安装..."
verify_success=true

if [ ! -d "$CURSOR_SKILLS_DIR" ] || [ -z "$(ls -A "$CURSOR_SKILLS_DIR" 2>/dev/null)" ]; then
    echo "  ⚠️  skills/ 目录为空"
    verify_success=false
fi

if [ ! -d "$CURSOR_RULES_DIR" ] || [ -z "$(ls -A "$CURSOR_RULES_DIR" 2>/dev/null)" ]; then
    echo "  ⚠️  rules/ 目录为空"
    verify_success=false
fi

if [ "$verify_success" = true ]; then
    echo "  ✓ 配置文件完整"
    echo ""
    echo "🔄 请重启 Cursor 使配置生效"
else
    echo ""
    echo "⚠️  部分配置可能未同步成功，请检查上述目录"
fi

echo ""
echo "💡 提示："
echo "  - 更新配置：重新运行此脚本"
echo "  - 验证安装：在 Cursor Agent 中查看可用 skills"
echo "  - 卸载：删除 $INSTALL_DIR 和上述配置目录"
echo ""
echo "📖 文档：https://github.com/doccker/cc-use-exp"
