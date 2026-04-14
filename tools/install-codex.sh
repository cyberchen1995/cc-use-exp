#!/bin/bash
set -e

# Codex CLI 一键安装脚本
# 用法: bash <(curl -sL https://raw.githubusercontent.com/doccker/cc-use-exp/main/tools/install-codex.sh)

echo "=== cc-use-exp Codex CLI 安装器 ==="
echo ""

# 依赖检查
check_dependencies() {
    local missing_deps=()

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
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
echo ""

# 检查是否已安装
INSTALL_DIR="$HOME/.codex/.cc-use-exp"
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
    mkdir -p "$HOME/.codex"

    # Clone 到 Codex 配置目录
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
echo "🔧 同步配置到 Codex CLI..."
echo ""

# 执行同步脚本（只同步 Codex 部分）
if [ -f "./tools/sync-config.sh" ]; then
    # 提取 Codex 同步逻辑
    CODEX_DIR="$HOME/.codex"
    AGENTS_SKILLS_DIR="$HOME/.agents/skills"

    mkdir -p "$CODEX_DIR/rules"
    mkdir -p "$CODEX_DIR/instructions"
    mkdir -p "$AGENTS_SKILLS_DIR"

    # 同步 rules
    if [ -d ".codex/global/rules" ]; then
        rsync -a .codex/global/rules/ "$CODEX_DIR/rules/"
        echo "  ✓ rules/"
    fi

    # 同步 instructions
    if [ -d ".codex/instructions" ]; then
        rsync -a .codex/instructions/ "$CODEX_DIR/instructions/"
        echo "  ✓ instructions/"
    fi

    # 同步 skills
    if [ -d ".codex/skills" ]; then
        rsync -a .codex/skills/ "$AGENTS_SKILLS_DIR/"
        echo "  ✓ skills/"
    fi

    # 同步 AGENTS.md（受管区块合并）
    if [ -f ".codex/global/AGENTS.md" ]; then
        if [ -f "$CODEX_DIR/AGENTS.md" ]; then
            # 简单追加（实际应该用受管区块合并）
            echo "" >> "$CODEX_DIR/AGENTS.md"
            cat .codex/global/AGENTS.md >> "$CODEX_DIR/AGENTS.md"
        else
            cp .codex/global/AGENTS.md "$CODEX_DIR/AGENTS.md"
        fi
        echo "  ✓ AGENTS.md"
    fi

    # 创建 manifest 标记
    echo "cc-use-exp" > "$CODEX_DIR/rules/.cc-use-exp-managed"
    echo "cc-use-exp" > "$CODEX_DIR/instructions/.cc-use-exp-managed"
    echo "cc-use-exp" > "$AGENTS_SKILLS_DIR/.cc-use-exp-managed"
else
    echo "❌ 错误：找不到同步脚本"
    exit 1
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 已同步配置到："
echo "  - $CODEX_DIR/rules/"
echo "  - $CODEX_DIR/instructions/"
echo "  - $AGENTS_SKILLS_DIR/"
echo ""

# 安装验证
echo "🔍 验证安装..."
verify_success=true

if [ ! -d "$AGENTS_SKILLS_DIR" ] || [ -z "$(ls -A "$AGENTS_SKILLS_DIR" 2>/dev/null)" ]; then
    echo "  ⚠️  skills/ 目录为空"
    verify_success=false
fi

if [ ! -d "$CODEX_DIR/rules" ] || [ -z "$(ls -A "$CODEX_DIR/rules" 2>/dev/null)" ]; then
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
echo "  - 会话内安装：在 Codex 中执行 \$skill-installer install"
echo "  - 卸载：删除 $INSTALL_DIR 和上述配置目录"
echo ""
echo "📖 文档：https://github.com/doccker/cc-use-exp"
