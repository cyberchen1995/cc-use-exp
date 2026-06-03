#!/usr/bin/env bash
# verify-gemini-new-feature.sh - 验证 Gemini /new-feature 任务文件路径修复
#
# 用法：
#   ./tools/verify-gemini-new-feature.sh                # 仅校验本仓库 toml 配置
#   ./tools/verify-gemini-new-feature.sh /path/project  # 也校验目标项目同步状态
#
# 校验范围：
#   1. 本仓库 .gemini/commands/new-feature.toml 关键声明齐全
#   2. 目标项目（若给）的 toml 与本仓库一致
#   3. 输出实地验证步骤清单（用户跑 gemini 后手动确认）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_TOML="${REPO_ROOT}/.gemini/commands/new-feature.toml"

TARGET_PROJECT="${1:-}"

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

pass() { printf "${GREEN}✅${NC} %s\n" "$1"; }
fail() { printf "${RED}❌${NC} %s\n" "$1"; exit 1; }
warn() { printf "${YELLOW}⚠️ ${NC} %s\n" "$1"; }

assert_toml_contains() {
    local toml="$1"
    local pattern="$2"
    local desc="$3"
    if grep -qE "${pattern}" "${toml}"; then
        pass "${desc}"
    else
        fail "${desc}（缺失模式: ${pattern}）"
    fi
}

echo "════════════════════════════════════════"
echo "  Gemini /new-feature 路径修复验证"
echo "════════════════════════════════════════"
echo ""

echo "▶ 第 1 步：本仓库 toml 关键声明校验"
echo "  源文件: ${SRC_TOML}"
echo ""

[[ -f "${SRC_TOML}" ]] || fail ".gemini/commands/new-feature.toml 不存在"

assert_toml_contains "${SRC_TOML}" "\.gemini/tasks/" \
    "声明任务文件路径为 .gemini/tasks/"

assert_toml_contains "${SRC_TOML}" "cc-new-feature|cc-task-state|cc-\\*" \
    "禁止改派到 cc-* skill 系列"

assert_toml_contains "${SRC_TOML}" "禁止.*\.codex/tasks|不得.*\.codex/tasks" \
    "明确禁止写入 .codex/tasks/"

echo ""

if [[ -n "${TARGET_PROJECT}" ]]; then
    echo "▶ 第 2 步：目标项目同步一致性校验"
    echo "  目标: ${TARGET_PROJECT}"
    echo ""

    TARGET_TOML="${TARGET_PROJECT}/.gemini/commands/new-feature.toml"
    if [[ ! -f "${TARGET_TOML}" ]]; then
        fail "目标项目缺 .gemini/commands/new-feature.toml；请先在目标项目跑 ./tools/sync-config.sh"
    fi
    pass "目标项目存在 new-feature.toml"

    if diff -q "${SRC_TOML}" "${TARGET_TOML}" > /dev/null 2>&1; then
        pass "目标 toml 与本仓库一致"
    else
        fail "目标 toml 与本仓库不一致；diff:"
        diff "${SRC_TOML}" "${TARGET_TOML}" | head -30
    fi

    if [[ -d "${TARGET_PROJECT}/.gemini" ]]; then
        pass "目标项目 .gemini/ 目录存在"
    else
        warn "目标项目无 .gemini/ 目录（首次同步后才会有）"
    fi

    if [[ -d "${TARGET_PROJECT}/.codex/tasks" ]]; then
        warn "目标项目存在 .codex/tasks/ —— 若是历史任务文件，请确认非由 Gemini /new-feature 写入"
        ls "${TARGET_PROJECT}/.codex/tasks/" 2>/dev/null | head -5
    fi

    echo ""
else
    echo "▶ 第 2 步：跳过（未传目标项目路径）"
    echo "  提示：./tools/verify-gemini-new-feature.sh /path/to/your/project"
    echo ""
fi

echo "▶ 第 3 步：实地手动验证步骤（用户在目标项目执行）"
echo ""
cat <<'EOF'
  1. 进入任意已用 sync-config.sh 同步过的项目目录

  2. 启动 Gemini CLI 触发 /new-feature
     $ gemini
     > /new-feature 测试任务

  3. 等待 Gemini 创建任务文件后，查任务文件落点：
     $ find .gemini/tasks/ -name "*.md" -mmin -5 2>/dev/null
     $ find .codex/tasks/  -name "*.md" -mmin -5 2>/dev/null
     $ find ~/.codex/tasks/ -name "*.md" -mmin -5 2>/dev/null

  4. 预期结果：
     ✅ .gemini/tasks/ 下出现新 .md（路径修复成功）
     ❌ .codex/tasks/ 或 ~/.codex/tasks/ 下出现新 .md（路径污染未修复，需排查）
EOF

echo ""
echo "════════════════════════════════════════"
pass "静态校验全部通过；请按第 3 步完成实地验证"
echo "════════════════════════════════════════"
