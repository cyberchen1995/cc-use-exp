#!/bin/bash
set -e

# Gemini CLI 一键安装脚本
# 用法: bash <(curl -sL https://raw.githubusercontent.com/doccker/cc-use-exp/main/tools/install-gemini.sh)

echo "=== cc-use-exp Gemini CLI 安装器 ==="
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
INSTALL_DIR="$HOME/.gemini/.cc-use-exp"
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
    mkdir -p "$HOME/.gemini"

    # Clone 到 Gemini 配置目录
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
echo "🔧 同步配置到 Gemini CLI..."

# 执行同步脚本（只同步 Gemini 部分）
if [ -f "./tools/sync-config.sh" ]; then
    GEMINI_DIR="$HOME/.gemini"

    mkdir -p "$GEMINI_DIR/commands"
    mkdir -p "$GEMINI_DIR/skills"
    mkdir -p "$GEMINI_DIR/rules"
    mkdir -p "$GEMINI_DIR/policies"

    # 同步 commands
    if [ -d ".gemini/commands" ]; then
        rsync -a --delete .gemini/commands/ "$GEMINI_DIR/commands/"
        echo "  ✓ commands/"
    fi

    # 同步 skills
    if [ -d ".gemini/skills" ]; then
        rsync -a --delete .gemini/skills/ "$GEMINI_DIR/skills/"
        echo "  ✓ skills/"
    fi

    # 同步 rules
    if [ -d ".gemini/rules" ]; then
        rsync -a .gemini/rules/ "$GEMINI_DIR/rules/"
        echo "  ✓ rules/"
    fi

    # 同步 policies
    if [ -d ".gemini/policies" ]; then
        rsync -a .gemini/policies/ "$GEMINI_DIR/policies/"
        echo "  ✓ policies/"
    fi

    # 同步 GEMINI.md（如果不存在）
    if [ -f ".gemini/GEMINI.md" ] && [ ! -f "$GEMINI_DIR/GEMINI.md" ]; then
        cp .gemini/GEMINI.md "$GEMINI_DIR/GEMINI.md"
        echo "  ✓ GEMINI.md"
    fi

    # 同步 settings.json（如果不存在）
    if [ -f ".gemini/settings.json" ] && [ ! -f "$GEMINI_DIR/settings.json" ]; then
        cp .gemini/settings.json "$GEMINI_DIR/settings.json"
        echo "  ✓ settings.json"
    fi

    # 创建 manifest 标记
    echo "cc-use-exp" > "$GEMINI_DIR/commands/.cc-use-exp-managed"
    echo "cc-use-exp" > "$GEMINI_DIR/skills/.cc-use-exp-managed"
    echo "cc-use-exp" > "$GEMINI_DIR/rules/.cc-use-exp-managed"
else
    echo "❌ 错误：找不到同步脚本"
    exit 1
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 已同步配置到："
echo "  - $GEMINI_DIR/commands/"
echo "  - $GEMINI_DIR/skills/"
echo "  - $GEMINI_DIR/rules/"
echo "  - $GEMINI_DIR/policies/"
echo ""

# 安装验证
echo "🔍 验证安装..."
verify_success=true

if [ ! -d "$GEMINI_DIR/skills" ] || [ -z "$(ls -A "$GEMINI_DIR/skills" 2>/dev/null)" ]; then
    echo "  ⚠️  skills/ 目录为空"
    verify_success=false
fi

if [ ! -d "$GEMINI_DIR/rules" ] || [ -z "$(ls -A "$GEMINI_DIR/rules" 2>/dev/null)" ]; then
    echo "  ⚠️  rules/ 目录为空"
    verify_success=false
fi

if [ "$verify_success" = true ]; then
    echo "  ✓ 配置文件完整"
    echo ""
    echo "🔄 配置已生效，无需重启"
else
    echo ""
    echo "⚠️  部分配置可能未同步成功，请检查上述目录"
fi

echo ""
echo "💡 提示："
echo "  - 更新配置：重新运行此脚本"
echo "  - 验证安装：在 Gemini CLI 中执行 /skills list"
echo "  - 卸载：删除 $INSTALL_DIR 和上述配置目录"
echo ""
echo "📖 文档：https://github.com/doccker/cc-use-exp"
