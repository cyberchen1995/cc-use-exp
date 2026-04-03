#!/usr/bin/env bash
set -euo pipefail

# [0/4] 版本检查
echo "[0/4] 检查 Gemini CLI 版本 ..."
if ! command -v gemini >/dev/null 2>&1; then
    echo "❌ 未找到 gemini 命令。"
    exit 1
fi

# 获取当前版本号
CURRENT_VERSION=$(gemini --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0.0.0")
MIN_VERSION="0.35.0"

# 简易版本比较函数
version_ge() {
    [ "$(printf '%s\n%s' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if ! version_ge "$CURRENT_VERSION" "$MIN_VERSION"; then
    echo "⚠️ 当前版本 $CURRENT_VERSION 低于 $MIN_VERSION，不受该协议限制影响，无需补丁。"
    exit 0
fi

echo "[1/4] 查找 Gemini CLI 核心文件 ..."

# 搜寻路径列表
SEARCH_PATHS=()

# 1. npm 全局路径
if command -v npm >/dev/null 2>&1; then
    NPM_ROOT=$(npm root -g 2>/dev/null || true)
    if [[ -n "$NPM_ROOT" ]]; then
        SEARCH_PATHS+=("$NPM_ROOT")
    fi
fi

# 2. Homebrew 路径
GEMINI_PATH=$(which gemini 2>/dev/null || true)
if [[ -n "$GEMINI_PATH" ]]; then
    # 处理符号链接
    REAL_GEMINI_PATH="$GEMINI_PATH"
    if [[ -L "$GEMINI_PATH" ]]; then
        LINK_TARGET=$(readlink "$GEMINI_PATH")
        if [[ "$LINK_TARGET" == /* ]]; then
            REAL_GEMINI_PATH="$LINK_TARGET"
        else
            REAL_GEMINI_PATH="$(dirname "$GEMINI_PATH")/$LINK_TARGET"
        fi
    fi
    # 查找 libexec 或 node_modules 目录
    BASE_DIR=$(dirname "$(dirname "$REAL_GEMINI_PATH")")
    if [[ -d "$BASE_DIR/libexec/lib/node_modules" ]]; then
        SEARCH_PATHS+=("$BASE_DIR/libexec/lib/node_modules")
    fi
    if [[ -d "$BASE_DIR/lib/node_modules" ]]; then
        SEARCH_PATHS+=("$BASE_DIR/lib/node_modules")
    fi
fi

target=""
for p in "${SEARCH_PATHS[@]}"; do
    if [[ -d "$p" ]]; then
        # 在该路径下查找包含特定错误信息的 contentGenerator.js
        found=$(grep -rl "Custom base URL must use HTTPS unless it is localhost" "$p" 2>/dev/null \
          | grep 'contentGenerator\.js$' \
          | grep -v '\.test\.js$' \
          | head -1 || true)
        if [[ -n "$found" ]]; then
            target="$found"
            break
        fi
    fi
done

if [[ -z "$target" ]]; then
  echo "未找到目标文件。请确认已安装 @google/gemini-cli 或 @google/gemini-cli-core。"
  exit 1
fi

echo "找到目标文件: $target"

if [[ ! -w "$target" ]]; then
  echo "当前用户无写权限，请用 sudo 运行此脚本。"
  exit 1
fi

echo "[2/4] 创建备份 ..."
backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$target" "$backup"
echo "备份已保存: $backup"

echo "[3/4] 应用补丁 ..."
TARGET_FILE="$target" python3 - <<'PY'
import os
import re
from pathlib import Path

p = Path(os.environ["TARGET_FILE"])
s = p.read_text(encoding="utf-8")

if "Custom base URL must use HTTP or HTTPS." in s:
    print("已是补丁状态，无需重复修改。")
    raise SystemExit(0)

pattern = re.compile(
    r"""if\s*\(\s*url\.protocol\s*!==\s*'https:'\s*&&\s*!LOCAL_HOSTNAMES\.includes\(url\.hostname\)\s*\)\s*\{\s*throw new Error\('Custom base URL must use HTTPS unless it is localhost\.'\);\s*\}""",
    re.S,
)

replacement = """if (!['http:', 'https:'].includes(url.protocol)) {
        throw new Error('Custom base URL must use HTTP or HTTPS.');
    }"""

new_s, count = pattern.subn(replacement, s, count=1)
if count != 1:
    raise SystemExit("未匹配到目标代码（版本可能已变化），已保留备份，请手动检查。")

p.write_text(new_s, encoding="utf-8")
print("补丁已写入。")
PY

echo "[4/4] 验证结果 ..."
if grep -q "Custom base URL must use HTTP or HTTPS." "$target"; then
  echo "✅ Patch 成功"
else
  echo "❌ Patch 可能失败，请检查 $target 与备份 $backup"
  exit 1
fi

echo
echo "完成。若需回滚："
echo "mv \"$backup\" \"$target\""
