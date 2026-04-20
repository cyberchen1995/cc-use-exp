#!/bin/bash
set -e

# GitHub Copilot 一键安装脚本
# 用法: bash <(curl -sL https://raw.githubusercontent.com/doccker/cc-use-exp/main/tools/install-copilot.sh)

echo "=== cc-use-exp GitHub Copilot 安装器 ==="
echo ""

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

INSTALL_DIR="$HOME/.config/github-copilot/cc-use-exp"
TARGET_GITHUB_DIR="$HOME/.github"

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

    if [ ! -w "$HOME" ]; then
        echo "❌ 权限错误：无法写入 $HOME"
        exit 1
    fi

    mkdir -p "$HOME/.config/github-copilot"

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
echo "🔧 同步配置到 GitHub Copilot..."

mkdir -p "$TARGET_GITHUB_DIR/instructions"

if [ -d ".github/instructions" ]; then
    rsync -a --delete .github/instructions/ "$TARGET_GITHUB_DIR/instructions/"
    echo "  ✓ instructions/"
fi

if [ -f ".github/copilot-instructions.md" ]; then
    cp .github/copilot-instructions.md "$TARGET_GITHUB_DIR/copilot-instructions.md"
    echo "  ✓ copilot-instructions.md"
fi

if [ -f "AGENTS.md" ]; then
    cp AGENTS.md "$TARGET_GITHUB_DIR/AGENTS.md"
    echo "  ✓ AGENTS.md"
else
    echo "  ⚠️  未找到仓库根 AGENTS.md，已跳过"
fi

echo "cc-use-exp" > "$TARGET_GITHUB_DIR/instructions/.cc-use-exp-managed"

echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 已同步配置到："
echo "  - $TARGET_GITHUB_DIR/copilot-instructions.md"
echo "  - $TARGET_GITHUB_DIR/instructions/"
echo "  - $TARGET_GITHUB_DIR/AGENTS.md（若仓库存在）"
echo ""
echo "💡 提示："
echo "  - 更新配置：重新运行此脚本"
echo "  - GitHub Copilot coding agent 会优先读取仓库内 AGENTS.md 与 .github/copilot-instructions.md"
echo "  - 若使用本机用户级兜底，可复用已同步到 $TARGET_GITHUB_DIR 的配置"
echo ""
echo "📖 文档：https://github.com/doccker/cc-use-exp"
