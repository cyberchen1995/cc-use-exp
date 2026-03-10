#!/usr/bin/env bash
set -euo pipefail

# 同步 .claude 和 .gemini 配置到用户根目录

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${GREEN}=== 配置同步工具 ===${NC}"
echo -e "源目录: ${SCRIPT_DIR}"
echo -e "目标目录: ${HOME}"
echo ""

# --- Claude Code ---
if [[ -d "${SCRIPT_DIR}/.claude" ]]; then
    echo -e "${GREEN}[Claude Code] 开始同步${NC}"

    # 确保目标目录存在
    mkdir -p ~/.claude

    # 删除旧配置目录（保留历史记录、projects 等）
    rm -rf ~/.claude/rules ~/.claude/skills ~/.claude/commands ~/.claude/templates ~/.claude/tasks
    echo -e "${YELLOW}  已清理旧配置目录${NC}"

    # 复制配置目录
    cp -r "${SCRIPT_DIR}/.claude/rules" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/skills" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/commands" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/templates" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/tasks" ~/.claude/
    cp "${SCRIPT_DIR}/.claude/CLAUDE.md" ~/.claude/

    echo -e "${GREEN}  ✓ rules/ skills/ commands/ templates/ tasks/ CLAUDE.md${NC}"
else
    echo -e "${YELLOW}[Claude Code] 源目录不存在，跳过${NC}"
fi

echo ""

# --- Gemini CLI ---
if [[ -d "${SCRIPT_DIR}/.gemini" ]]; then
    echo -e "${GREEN}[Gemini CLI] 开始同步${NC}"

    # 确保目标目录存在
    mkdir -p ~/.gemini

    # 删除旧配置目录（保留认证信息）
    rm -rf ~/.gemini/commands ~/.gemini/skills ~/.gemini/rules
    echo -e "${YELLOW}  已清理旧配置目录${NC}"

    # 复制配置
    cp -r "${SCRIPT_DIR}/.gemini/commands" ~/.gemini/
    cp -r "${SCRIPT_DIR}/.gemini/skills" ~/.gemini/
    cp -r "${SCRIPT_DIR}/.gemini/rules" ~/.gemini/
    cp "${SCRIPT_DIR}/.gemini/GEMINI.md" ~/.gemini/
    cp "${SCRIPT_DIR}/.gemini/settings.json" ~/.gemini/

    echo -e "${GREEN}  ✓ commands/ skills/ rules/ GEMINI.md settings.json${NC}"

    # --- MCP 扩展检测 ---
    EXT_JSON="${SCRIPT_DIR}/.gemini/extensions.json"
    if [[ -f "$EXT_JSON" ]]; then
        echo ""
        echo -e "${YELLOW}[Gemini CLI] 正在检测推荐扩展...${NC}"
        
        # 获取当前已安装的扩展列表
        INSTALLED_EXTS=$(gemini extensions list 2>/dev/null || echo "")
        
        # 使用 python3 解析 JSON 并检查缺失
        MISSING_EXTS=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    installed = sys.argv[2]
    for ext in data.get('recommendations', []):
        if ext['id'] not in installed:
            print(ext['id'] + '|' + ext['name'] + '|' + ext['url'])
except Exception:
    pass
" "$EXT_JSON" "$INSTALLED_EXTS")

        if [[ -n "$MISSING_EXTS" ]]; then
            echo -e "${YELLOW}检测到以下推荐扩展尚未安装：${NC}"
            IFS=$'\n'
            for item in $MISSING_EXTS; do
                IFS='|' read -r id name cmd <<< "$item"
                echo -e "  - ${YELLOW}$name${NC} ($id)"
            done
            
            echo ""
            read -p "是否现在安装上述缺失的扩展？[Y/n] " confirm
            if [[ "$confirm" =~ ^[Yy]$ || "$confirm" == "" ]]; then
                IFS=$'\n'
                for item in $MISSING_EXTS; do
                    IFS='|' read -r id name url <<< "$item"
                    echo -e "${GREEN}正在安装 $name...${NC}"
                    gemini extensions install "$url"
                done
                echo -e "${GREEN}✓ 扩展安装完成${NC}"
            else
                echo -e "${YELLOW}已跳过扩展安装。你可以之后手动安装。${NC}"
            fi
        else
            echo -e "${GREEN}✓ 所有推荐扩展已安装${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[Gemini CLI] 源目录不存在，跳过${NC}"
fi

echo ""
echo -e "${GREEN}=== 同步完成 ===${NC}"
