#!/usr/bin/env bash
# sync-skill.sh - 单向同步 Claude skills 到其他 5 平台
#
# Usage:
#   ./tools/sync-skill.sh                    # 同步所有 Claude skill
#   ./tools/sync-skill.sh redis-safety       # 只同步指定 skill
#   ./tools/sync-skill.sh --target codex     # 只同步到指定平台
#   ./tools/sync-skill.sh --dry-run          # 仅打印计划，不实际操作
#   ./tools/sync-skill.sh --force            # 覆盖已存在的 skill
#
# Codex agents/openai.yaml 保护：
#   sync_to_codex 默认生成短模板（interface + policy.allow_implicit_invocation: true），
#   适用于 safety / dev 类隐式触发 skill。
#   若目标 .codex/skills/cc-*/agents/openai.yaml 已存在，即使加 --force 也会
#   保留该 yaml 原内容，仅同步 SKILL.md / references 等其他文件。
#   如需强制重置 yaml，请手动删除目标 agents/openai.yaml 后再 sync。
#
# Copilot 人工精简保护：
#   sync_to_copilot 默认生成 AUTO-GENERATED 长版本（带 <!-- AUTO-GENERATED ... --> 注释）。
#   若目标文件已不含该注释（视为人工接管的精简版），即使 --force 也会跳过，
#   防止用户手动精简的内容被脚本回写覆盖。
#   如需重置回 AUTO-GENERATED 版本，请手动 rm 目标文件后再 sync。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SRC_DIR="${REPO_ROOT}/.claude/skills"
GEMINI_DIR="${REPO_ROOT}/.gemini/skills"
CURSOR_DIR="${REPO_ROOT}/.cursor/skills"
CODEX_DIR="${REPO_ROOT}/.codex/skills"
COPILOT_DIR="${REPO_ROOT}/.github/instructions"
ANTIGRAVITY_DIR="${REPO_ROOT}/.antigravity/skills"

DRY_RUN=0
FORCE=0
TARGET="all"
SKILL_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --target=*)
            TARGET="${1#*=}"
            shift
            ;;
        -h|--help)
            grep -E '^# ' "$0" | sed 's/^# //'
            exit 0
            ;;
        -*)
            echo "❌ 未知参数: $1" >&2
            exit 1
            ;;
        *)
            SKILL_NAME="$1"
            shift
            ;;
    esac
done

case "${TARGET}" in
    all|gemini|cursor|codex|copilot|antigravity) ;;
    *)
        echo "❌ --target 必须是 all/gemini/cursor/codex/copilot/antigravity 之一" >&2
        exit 1
        ;;
esac

if [[ ! -d "${SRC_DIR}" ]]; then
    echo "❌ 源目录不存在: ${SRC_DIR}" >&2
    exit 1
fi

log() {
    local prefix=""
    [[ "${DRY_RUN}" -eq 1 ]] && prefix="[DRY] "
    printf '%s%s\n' "${prefix}" "$1"
}

run() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        printf '[DRY] %s\n' "$*"
    else
        "$@"
    fi
}

skill_exists_at_target() {
    local target_path="$1"
    [[ -e "${target_path}" ]]
}

should_sync() {
    local target_path="$1"
    local skill="$2"
    local platform="$3"
    if skill_exists_at_target "${target_path}" && [[ "${FORCE}" -eq 0 ]]; then
        log "⏭️  跳过 ${platform}/${skill}（已存在，--force 强制覆盖）"
        return 1
    fi
    return 0
}

normalize_non_claude_skill_text() {
    local target_path="$1"

    if [[ -d "${target_path}" ]]; then
        find "${target_path}" -type f \( -name '*.md' -o -name '*.toml' -o -name '*.yaml' \) -print0 \
            | xargs -0 sed -i.bak \
                -e "s/\`superpowers:systematic-debugging\`/通用系统化调试流程/g" \
                -e "s/\`superpowers:brainstorming\`/通用头脑风暴流程/g" \
                -e "s/\`superpowers:writing-plans\`/通用计划编写流程/g" \
                -e "s/superpowers 自身的优先级规则/用户显式指令优先原则/g" \
                -e "s/走通用 systematic-debugging/走通用系统化调试流程/g" \
                -e "s|\.claude/skills/|~/.agents/skills/|g"
        find "${target_path}" -type f -name '*.bak' -delete
    elif [[ -f "${target_path}" ]]; then
        sed -i.bak \
            -e "s/\`superpowers:systematic-debugging\`/通用系统化调试流程/g" \
            -e "s/\`superpowers:brainstorming\`/通用头脑风暴流程/g" \
            -e "s/\`superpowers:writing-plans\`/通用计划编写流程/g" \
            -e "s/superpowers 自身的优先级规则/用户显式指令优先原则/g" \
            -e "s/走通用 systematic-debugging/走通用系统化调试流程/g" \
            -e "s|\.claude/skills/|~/.agents/skills/|g" \
            "${target_path}"
        rm -f "${target_path}.bak"
    fi
}

sync_to_gemini() {
    local skill="$1"
    local src="${SRC_DIR}/${skill}"
    local dst="${GEMINI_DIR}/${skill}"

    should_sync "${dst}" "${skill}" "gemini" || return 0

    log "📦 Gemini ← ${skill}"
    run mkdir -p "${GEMINI_DIR}"
    run rm -rf "${dst}"
    run cp -R "${src}" "${dst}"
    [[ "${DRY_RUN}" -eq 1 ]] || normalize_non_claude_skill_text "${dst}"
}

sync_to_antigravity() {
    local skill="$1"
    local src="${SRC_DIR}/${skill}"
    local dst="${ANTIGRAVITY_DIR}/${skill}"

    should_sync "${dst}" "${skill}" "antigravity" || return 0

    log "📦 Antigravity ← ${skill}"
    run mkdir -p "${ANTIGRAVITY_DIR}"
    run rm -rf "${dst}"
    run cp -R "${src}" "${dst}"

    if [[ "${DRY_RUN}" -eq 0 ]]; then
        local tmp_file
        tmp_file="$(mktemp)"
        awk '
            BEGIN { in_fm=0; keep=0 }
            NR==1 && /^---$/ { in_fm=1; print; next }
            in_fm && /^---$/ { in_fm=0; print; next }
            in_fm {
                if ($0 ~ /^(name|description):/) { keep=1; print; next }
                if ($0 ~ /^[a-zA-Z0-9_-]+:/) { keep=0; next }
                if (keep) { print }
                next
            }
            { print }
        ' "${dst}/SKILL.md" > "${tmp_file}"
        mv "${tmp_file}" "${dst}/SKILL.md"

        normalize_non_claude_skill_text "${dst}"
    fi
}

sync_to_cursor() {
    local skill="$1"
    local src="${SRC_DIR}/${skill}"
    local dst="${CURSOR_DIR}/${skill}"

    should_sync "${dst}" "${skill}" "cursor" || return 0

    log "📦 Cursor ← ${skill}"
    run mkdir -p "${CURSOR_DIR}"
    run rm -rf "${dst}"
    run cp -R "${src}" "${dst}"
    [[ "${DRY_RUN}" -eq 1 ]] || normalize_non_claude_skill_text "${dst}"
}

sync_to_codex() {
    local skill="$1"
    local src="${SRC_DIR}/${skill}"
    local cc_name="cc-${skill}"
    local dst="${CODEX_DIR}/${cc_name}"

    should_sync "${dst}" "${cc_name}" "codex" || return 0

    local preserve_openai_yaml=0
    local existing_openai_yaml=""
    if [[ -f "${dst}/agents/openai.yaml" ]]; then
        preserve_openai_yaml=1
        existing_openai_yaml="$(cat "${dst}/agents/openai.yaml")"
        log "🛡️  保护 codex/${cc_name}/agents/openai.yaml（已存在，将保留原内容）"
    fi

    log "📦 Codex ← ${cc_name}"
    run mkdir -p "${CODEX_DIR}"
    run rm -rf "${dst}"
    run cp -R "${src}" "${dst}"

    if [[ "${DRY_RUN}" -eq 0 ]]; then
        local tmp_file
        tmp_file="$(mktemp)"
        awk '
            BEGIN { in_fm=0; keep=0 }
            NR==1 && /^---$/ { in_fm=1; print; next }
            in_fm && /^---$/ { in_fm=0; print; next }
            in_fm {
                if ($0 ~ /^(name|description):/) { keep=1; print; next }
                if ($0 ~ /^[a-zA-Z0-9_-]+:/) { keep=0; next }
                if (keep) { print }
                next
            }
            { print }
        ' "${dst}/SKILL.md" > "${tmp_file}"
        mv "${tmp_file}" "${dst}/SKILL.md"
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  - frontmatter name 改为 ${cc_name}"
        log "  - 替换内部跨 skill 引用为 cc- 前缀"
        if [[ "${preserve_openai_yaml}" -eq 1 ]]; then
            log "  - 保留原 agents/openai.yaml"
        else
            log "  - 生成 agents/openai.yaml（短模板）"
        fi
        return 0
    fi

    sed -i.bak "s/^name: ${skill}$/name: ${cc_name}/" "${dst}/SKILL.md"
    rm -f "${dst}/SKILL.md.bak"

    local other_skills
    other_skills="$(find "${SRC_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
        | grep -vFx "${skill}" | LC_ALL=C sort -u)"

    while IFS= read -r other; do
        [[ -n "${other}" ]] || continue
        find "${dst}" -type f \( -name '*.md' -o -name '*.yaml' \) -print0 \
            | xargs -0 sed -i.bak \
                -e "s/\`${other}\`/\`cc-${other}\`/g" \
                -e "s|/${other}/|/cc-${other}/|g" \
                -e "s|/${other})|/cc-${other})|g"
    done <<< "${other_skills}"

    normalize_non_claude_skill_text "${dst}"
    find "${dst}" -type f -name '*.bak' -delete

    sed -i.bak "s/\`${skill}\`/\`${cc_name}\`/g" "${dst}/SKILL.md"
    rm -f "${dst}/SKILL.md.bak"

    mkdir -p "${dst}/agents"
    if [[ "${preserve_openai_yaml}" -eq 1 ]]; then
        printf '%s\n' "${existing_openai_yaml}" > "${dst}/agents/openai.yaml"
    else
        local desc
        desc="$(awk '/^description:/{sub(/^description: */,""); print; exit}' "${src}/SKILL.md")"
        cat > "${dst}/agents/openai.yaml" <<YAML
interface:
  display_name: "${cc_name}"
  short_description: >-
    ${desc}
policy:
  allow_implicit_invocation: true
YAML
    fi
}

sync_to_copilot() {
    local skill="$1"
    local src="${SRC_DIR}/${skill}/SKILL.md"
    local dst="${COPILOT_DIR}/${skill}.instructions.md"

    if [[ -f "${dst}" ]] && ! grep -q "AUTO-GENERATED by tools/sync-skill.sh" "${dst}"; then
        log "🛡️  保护 copilot/${skill}.instructions.md（无 AUTO-GENERATED 标记，视为人工精简，跳过；如需重置请手动 rm 后再 sync）"
        return 0
    fi

    should_sync "${dst}" "${skill}" "copilot" || return 0

    log "📦 Copilot ← ${skill}.instructions.md（半自动，需人工精简）"
    run mkdir -p "${COPILOT_DIR}"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  - 提取 SKILL.md 主体生成精简版（applyTo: **）"
        return 0
    fi

    local title body
    title="$(awk '/^# /{sub(/^# */,""); print; exit}' "${src}")"
    body="$(awk 'BEGIN{p=0} /^# /{if(p==0){p=1;next}} /^## (规则溯源|相关 skill|与其他 skill 的边界)/{p=0} p==1{print}' "${src}")"

    {
        echo "---"
        echo "applyTo: \"**\""
        echo "---"
        echo ""
        echo "<!-- AUTO-GENERATED by tools/sync-skill.sh from .claude/skills/${skill}/SKILL.md -->"
        echo "<!-- 建议人工精简到 ~50 行以下，符合 Copilot 仓库级指令风格 -->"
        echo ""
        echo "# ${title}"
        echo ""
        echo "${body}"
    } > "${dst}"
    normalize_non_claude_skill_text "${dst}"
}

list_skills_to_sync() {
    if [[ -n "${SKILL_NAME}" ]]; then
        if [[ ! -d "${SRC_DIR}/${SKILL_NAME}" ]]; then
            echo "❌ skill 不存在: ${SRC_DIR}/${SKILL_NAME}" >&2
            exit 1
        fi
        echo "${SKILL_NAME}"
    else
        find "${SRC_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
            | LC_ALL=C sort
    fi
}

sync_one_skill() {
    local skill="$1"
    case "${TARGET}" in
        all)
            sync_to_antigravity "${skill}"
            sync_to_gemini "${skill}"
            sync_to_cursor "${skill}"
            sync_to_codex "${skill}"
            sync_to_copilot "${skill}"
            ;;
        antigravity) sync_to_antigravity "${skill}" ;;
        gemini)  sync_to_gemini "${skill}" ;;
        cursor)  sync_to_cursor "${skill}" ;;
        codex)   sync_to_codex "${skill}" ;;
        copilot) sync_to_copilot "${skill}" ;;
    esac
}

main() {
    log "🚀 sync-skill (target=${TARGET}, dry-run=${DRY_RUN}, force=${FORCE})"

    local skills
    skills="$(list_skills_to_sync)"
    local count
    count="$(echo "${skills}" | wc -l | tr -d ' ')"

    log "📋 待同步 ${count} 个 skill"

    while IFS= read -r skill; do
        [[ -n "${skill}" ]] || continue
        log ""
        log "── ${skill} ──"
        sync_one_skill "${skill}"
    done <<< "${skills}"

    log ""
    log "✅ 完成"

    if [[ "${TARGET}" == "codex" || "${TARGET}" == "all" ]]; then
        if [[ "${DRY_RUN}" -eq 0 ]]; then
            log "🔎 运行 Codex 后置校验..."
            if command -v rg >/dev/null 2>&1; then
                log "  - 检查遗漏的特定平台字符串:"
                rg "superpowers|\.claude/skills|^version:|^paths:" "${CODEX_DIR}" || log "    ✓ 未发现残留"
            else
                log "  - 检查遗漏的特定平台字符串 (grep):"
                grep -rE "superpowers|\.claude/skills|^version:|^paths:" "${CODEX_DIR}" || log "    ✓ 未发现残留"
            fi
            log "  - Git 空白符检查:"
            git diff --check -- "${CODEX_DIR}"
        fi
    fi
}

main
