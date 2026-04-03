#!/usr/bin/env python3
"""
Claude Code 综合补丁脚本

补丁项:
  1. ToolSearch 域名限制解除 — 允许 ToolSearch 访问任意域名
  2. Chrome 订阅检查绕过    — /chrome 命令不再要求 claude.ai 订阅
  3. Context Warning 禁用   — 禁用 context window 接近上限时的警告（不影响 auto-compact）
  4. Auth conflict 警告抑制  — 因 Patch 2 导致的误触发 OBK 警告
  5. Read/Search 折叠禁用   — 禁止 Read/Search 工具结果折叠

支持:
  macOS / Windows / Linux
  bun 官方二进制 / npm / pnpm / Homebrew / VS Code·Cursor 扩展

用法:
  python patch-claude.py              # 交互式
  python patch-claude.py --auto       # 自动补丁所有
  python patch-claude.py --restore    # 从备份恢复
  python patch-claude.py --status     # 仅查看状态
"""

import sys
import os
import re
import shutil
import platform
import subprocess
from pathlib import Path
from dataclasses import dataclass
from typing import Callable

# ── 补丁定义 ──────────────────────────────────────────────────────────


@dataclass
class PatchDef:
    name: str
    description: str
    target_re: re.Pattern[bytes]
    patched_re: re.Pattern[bytes]
    build_replacement: Callable[[re.Match[bytes]], bytes]
    default_enabled: bool = True


def _pad_to(prefix: bytes, suffix: bytes, length: int) -> bytes:
    padding = length - len(prefix) - len(suffix)
    if padding < 0:
        raise ValueError(f"patch template too long for match length {length}")
    return prefix + b" " * padding + suffix


# --- Patch 1: ToolSearch domain bypass ---

_TS_TARGET = re.compile(
    rb'return\["api\.anthropic\.com"\]\.includes\('
    rb'([A-Za-z_$][A-Za-z0-9_$]*)\)\}catch\{return!1\}'
)
_TS_PATCHED = re.compile(rb'return!0/\* *\*/\}catch\{return!0\}')

PATCH_TOOLSEARCH = PatchDef(
    name="toolsearch",
    description="ToolSearch 域名限制解除（由 /patch toolsearch 管理）",
    target_re=_TS_TARGET,
    patched_re=_TS_PATCHED,
    build_replacement=lambda m: m.group(0),  # 仅状态检测，不做替换
    default_enabled=False,
)

# --- Patch 2: Chrome subscription bypass ---

_ID = rb'[A-Za-z_$][A-Za-z0-9_$]*'

_CH_TARGET = re.compile(
    rb'function (' + _ID + rb')\(\)\{if\(!' + _ID + rb'\(\)\)return!1;return '
    + _ID + rb'\(' + _ID + rb'\(\)\?\.scopes\)\}'
    rb'|'
    rb'apiKey:' + _ID + rb'\(\)\?null:'
)
_CH_PATCHED = re.compile(
    rb'function ' + _ID + rb'\(\)\{return!0 +\}'
    rb'|'
    rb'apiKey:!1 +\?null:'
)

def _ch_replace(m: re.Match[bytes]) -> bytes:
    original = m.group(0)
    if original.startswith(b'function '):
        fn_name = m.group(1)
        return _pad_to(b"function " + fn_name + b"(){return!0", b"}", len(original))
    prefix = b'apiKey:'
    suffix = b'?null:'
    call = original[len(prefix):-len(suffix)]
    padded = b'!1' + b' ' * (len(call) - 2)
    return prefix + padded + suffix

PATCH_CHROME = PatchDef(
    name="chrome",
    description="Chrome 订阅检查绕过 (/chrome)",
    target_re=_CH_TARGET,
    patched_re=_CH_PATCHED,
    build_replacement=_ch_replace,
)

# --- Patch 3: Context warning disable ---

_CW_TARGET = re.compile(
    rb'isAboveWarningThreshold:(' + _ID + rb'),isAboveErrorThreshold:' + _ID
    + rb'\}=' + _ID + rb',(' + _ID + rb')=' + _ID + rb'\(\);if\(!\1\|\|\2\)return null'
)
_CW_PATCHED = re.compile(
    rb'isAboveWarningThreshold:' + _ID + rb',isAboveErrorThreshold:' + _ID
    + rb'\}=' + _ID + rb',' + _ID + rb'=' + _ID + rb'\(\);if\(!0\|\|' + _ID + rb'\)return null'
)

def _cw_replace(m: re.Match[bytes]) -> bytes:
    warn_var = m.group(1)
    dismiss_var = m.group(2)
    return m.group(0).replace(
        b"if(!" + warn_var + b"||" + dismiss_var + b")",
        b"if(!0||" + dismiss_var + b")",
        1,
    )

PATCH_CONTEXT_WARNING = PatchDef(
    name="context_warning",
    description="Context Warning 禁用",
    target_re=_CW_TARGET,
    patched_re=_CW_PATCHED,
    build_replacement=_cw_replace,
)

# --- Patch 4: Auth conflict warning suppress ---

_AW_TARGET = re.compile(
    rb'isActive:\(\)=>\{let (' + _ID + rb')=' + _ID + rb'\(\);return '
    + _ID + rb'\(\)&&\(\1\.source==="ANTHROPIC_AUTH_TOKEN"\|\|\1\.source==="apiKeyHelper"\)\}'
)
_AW_PATCHED = re.compile(
    rb'isActive:\(\)=>\{return!1 +\}'
)

PATCH_AUTH_WARNING = PatchDef(
    name="auth_warning",
    description="Auth conflict 警告抑制",
    target_re=_AW_TARGET,
    patched_re=_AW_PATCHED,
    build_replacement=lambda m: _pad_to(
        b"isActive:()=>{return!1", b"}", len(m.group(0))
    ),
)

# --- Patch 5: Collapse Read/Search disable ---

_CRS_TARGET = re.compile(
    rb'isCollapsible:(' + _ID + rb')\.isSearch\|\|\1\.isRead\|\|!1'
    rb'|'
    rb'isCollapsible:' + _ID + rb'\|\|\(' + _ID + rb'\(\)\?' + _ID + rb'===' + _ID + rb':!1\)'
)
_CRS_PATCHED = re.compile(
    rb'isCollapsible:!1/\* *\*/'
)

PATCH_COLLAPSE_RS = PatchDef(
    name="collapse_read_search",
    description="Read/Search 折叠禁用",
    target_re=_CRS_TARGET,
    patched_re=_CRS_PATCHED,
    build_replacement=lambda m: _pad_to(
        b"isCollapsible:!1/*", b"*/", len(m.group(0))
    ),
)

# --- Patch 6: 1h prompt cache ---
# 将缓存判断函数（检查 allowlist + 付费状态）替换为直接返回 true
# 此补丁仅做状态检测，实际应用由 /patch cache（JS 脚本）管理

# target_re / patched_re 仅用于状态检测
_1H_TARGET = re.compile(rb'tengu_prompt_cache_1h_config')
_1H_PATCHED = re.compile(rb'/\*__1h_cache_patched__\*/')

PATCH_1H_CACHE = PatchDef(
    name="1h_cache",
    description="1h Prompt Cache 启用（由 /patch cache 管理）",
    target_re=_1H_TARGET,
    patched_re=_1H_PATCHED,
    build_replacement=lambda m: m.group(0),  # 仅状态检测，不做替换
    default_enabled=False,
)

# 可应用的补丁（由本脚本管理）
ALL_PATCHES = [PATCH_CHROME, PATCH_CONTEXT_WARNING, PATCH_AUTH_WARNING, PATCH_COLLAPSE_RS]

# 仅状态检测的补丁（由独立工具管理）
STATUS_ONLY_PATCHES = [PATCH_TOOLSEARCH, PATCH_1H_CACHE]

# 全部补丁（用于 --status 展示）
ALL_WITH_STATUS = ALL_PATCHES + STATUS_ONLY_PATCHES

BACKUP_SUFFIX = ".claude-patch-bak"

# ── 补丁引擎 ──────────────────────────────────────────────────────────


def get_patch_status(data: bytes, patch: PatchDef) -> str:
    if patch.target_re.search(data):
        return "unpatched"
    if patch.patched_re.search(data):
        return "patched"
    return "unknown"


def apply_single_patch(data: bytes, patch: PatchDef) -> tuple[bytes, int]:
    count = 0
    def replacer(m: re.Match[bytes]) -> bytes:
        nonlocal count
        replacement = patch.build_replacement(m)
        if len(replacement) != len(m.group(0)):
            raise ValueError(
                f"[{patch.name}] replacement length mismatch: "
                f"{len(replacement)} != {len(m.group(0))}"
            )
        count += 1
        return replacement
    return patch.target_re.sub(replacer, data), count


def get_all_statuses(data: bytes, patches: list[PatchDef] | None = None) -> dict[str, str]:
    targets = patches if patches is not None else ALL_PATCHES
    return {p.name: get_patch_status(data, p) for p in targets}


def apply_all_patches(data: bytes, patches: list[PatchDef] | None = None) -> tuple[bytes, dict[str, int]]:
    targets = patches if patches is not None else ALL_PATCHES
    results: dict[str, int] = {}
    for patch in targets:
        data, count = apply_single_patch(data, patch)
        results[patch.name] = count
    return data, results

# ── 平台 & 工具 ──────────────────────────────────────────────────────

SYSTEM = platform.system()
IS_WINDOWS = (
    SYSTEM == "Windows"
    or "MSYS" in os.environ.get("MSYSTEM", "")
    or "MINGW" in platform.platform()
)


def home() -> Path:
    return Path.home()


def run_cmd(cmd: list[str], fallback: str = "") -> str:
    if not shutil.which(cmd[0]):
        return fallback
    try:
        r = subprocess.run(
            cmd, capture_output=True, text=True, timeout=5, shell=IS_WINDOWS
        )
        return r.stdout.strip() if r.returncode == 0 else fallback
    except Exception:
        return fallback


def resolve_patch_target(path: Path) -> Path:
    try:
        return path.resolve(strict=True)
    except OSError:
        return path


def resign_if_needed(path: Path) -> tuple[bool, str]:
    if SYSTEM != "Darwin":
        return True, ""
    result = subprocess.run(
        ["codesign", "--force", "--sign", "-", str(path)],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        return True, "已完成 macOS ad-hoc 重签名。"
    message = (result.stderr or result.stdout).strip() or "codesign 执行失败"
    return False, message


# ── 安装探测 ──────────────────────────────────────────────────────────


class Installation:
    def __init__(self, kind: str, target: Path, description: str):
        self.kind = kind
        self.source = target
        self.target = resolve_patch_target(target)
        self.description = description
        self.backup = self.target.parent / (self.target.name + BACKUP_SUFFIX)

    def __repr__(self):
        return f"[{self.kind}] {self.description}\n       文件: {self.target}"


def _find_patch_target_in_pkg(pkg_dir: Path) -> Path | None:
    cli_js = pkg_dir / "cli.js"
    if cli_js.is_file() and b"api.anthropic.com" in cli_js.read_bytes():
        return cli_js
    for js_file in sorted(pkg_dir.rglob("*.js")):
        if js_file.stat().st_size < 1000:
            continue
        try:
            if b"api.anthropic.com" in js_file.read_bytes():
                return js_file
        except OSError:
            continue
    return None

def find_bun_installations() -> list[Installation]:
    results = []
    candidates: list[Path] = []
    if IS_WINDOWS:
        candidates.append(home() / ".local" / "bin" / "claude.exe")
    else:
        candidates.append(home() / ".claude" / "local" / "claude")
        candidates.append(home() / ".local" / "bin" / "claude")
    for p in candidates:
        if p.is_file():
            results.append(Installation("bun", p, f"Bun 官方安装 ({p})"))
    return results


def find_npm_installations() -> list[Installation]:
    results = []
    npm_root = run_cmd(["npm", "root", "-g"])
    if npm_root:
        pkg_dir = Path(npm_root) / "@anthropic-ai" / "claude-code"
        if pkg_dir.is_dir():
            target = _find_patch_target_in_pkg(pkg_dir)
            if target:
                results.append(Installation("npm", target, f"npm 全局安装 ({target})"))
    else:
        results.extend(_find_npm_fallback())
    return results


def _find_npm_fallback() -> list[Installation]:
    h = home()
    search_dirs: list[tuple[Path, str]] = []
    if IS_WINDOWS:
        appdata = Path(os.environ.get("APPDATA", ""))
        if appdata.name:
            search_dirs.append((appdata / "npm" / "node_modules", "npm 默认全局"))
        nvm_home = os.environ.get("NVM_HOME", str(appdata / "nvm") if appdata.name else "")
        if nvm_home:
            nvm_path = Path(nvm_home)
            if nvm_path.is_dir():
                for d in nvm_path.iterdir():
                    nm = d / "node_modules"
                    if d.is_dir() and nm.is_dir():
                        search_dirs.append((nm, f"nvm ({d.name})"))
        fnm_dir = Path(os.environ.get("FNM_DIR", str(h / ".fnm")))
        nv = fnm_dir / "node-versions"
        if nv.is_dir():
            for d in nv.iterdir():
                nm = d / "installation" / "node_modules"
                if nm.is_dir():
                    search_dirs.append((nm, f"fnm ({d.name})"))
    else:
        nvm_dir = Path(os.environ.get("NVM_DIR", str(h / ".nvm")))
        versions = nvm_dir / "versions" / "node"
        if versions.is_dir():
            for d in versions.iterdir():
                nm = d / "lib" / "node_modules"
                if nm.is_dir():
                    search_dirs.append((nm, f"nvm ({d.name})"))
        fnm_dir = Path(os.environ.get("FNM_DIR", str(h / ".fnm")))
        nv = fnm_dir / "node-versions"
        if nv.is_dir():
            for d in nv.iterdir():
                nm = d / "installation" / "lib" / "node_modules"
                if nm.is_dir():
                    search_dirs.append((nm, f"fnm ({d.name})"))
        for p in [Path("/usr/local/lib/node_modules"), Path("/usr/lib/node_modules")]:
            if p.is_dir():
                search_dirs.append((p, "系统 npm"))

    volta_home = Path(os.environ.get("VOLTA_HOME", str(h / ".volta")))
    volta_node = volta_home / "tools" / "image" / "node"
    if volta_node.is_dir():
        for d in volta_node.iterdir():
            nm = (d / "node_modules") if IS_WINDOWS else (d / "lib" / "node_modules")
            if nm.is_dir():
                search_dirs.append((nm, f"volta ({d.name})"))

    results: list[Installation] = []
    seen: set[str] = set()
    for nm_dir, desc in search_dirs:
        pkg_dir = nm_dir / "@anthropic-ai" / "claude-code"
        if pkg_dir.is_dir():
            target = _find_patch_target_in_pkg(pkg_dir)
            if target:
                key = str(target.resolve())
                if key not in seen:
                    seen.add(key)
                    results.append(Installation("npm", target, f"npm ({desc}) ({target})"))
    return results

def find_pnpm_installations() -> list[Installation]:
    results = []
    pnpm_root = run_cmd(["pnpm", "root", "-g"])
    if not pnpm_root:
        return results
    pkg_dir = Path(pnpm_root) / "@anthropic-ai" / "claude-code"
    if pkg_dir.is_dir():
        target = _find_patch_target_in_pkg(pkg_dir)
        if target:
            results.append(Installation("pnpm", target.resolve(), f"pnpm 全局安装 ({target.resolve()})"))
            return results
    pnpm_dir = Path(pnpm_root).parent / ".pnpm"
    if pnpm_dir.is_dir():
        for pkg in pnpm_dir.rglob("@anthropic-ai/claude-code"):
            if pkg.is_dir():
                target = _find_patch_target_in_pkg(pkg)
                if target:
                    results.append(Installation("pnpm", target, f"pnpm 全局安装 ({target})"))
                    break
    return results


def find_brew_installations() -> list[Installation]:
    if IS_WINDOWS:
        return []
    results = []
    seen: set[str] = set()
    brew_prefix = run_cmd(["brew", "--prefix"])
    prefixes: list[Path] = []
    if brew_prefix:
        prefixes.append(Path(brew_prefix))
    for fallback in [Path("/opt/homebrew"), Path("/usr/local")]:
        if fallback not in prefixes and fallback.is_dir():
            prefixes.append(fallback)
    for prefix in prefixes:
        caskroom = prefix / "Caskroom" / "claude-code"
        if not caskroom.is_dir():
            continue
        for version_dir in sorted(caskroom.iterdir(), reverse=True):
            if not version_dir.is_dir() or version_dir.name.startswith("."):
                continue
            binary = version_dir / "claude"
            if binary.is_file() and binary.stat().st_size > 10 * 1024 * 1024:
                key = str(binary.resolve())
                if key not in seen:
                    seen.add(key)
                    results.append(Installation("brew", binary, f"Homebrew cask ({version_dir.name})"))
    return results


def find_vscode_installations() -> list[Installation]:
    results = []
    search_bases = [
        ("vscode", "VS Code", home() / ".vscode" / "extensions"),
        ("vscode", "VS Code Insiders", home() / ".vscode-insiders" / "extensions"),
        ("cursor", "Cursor", home() / ".cursor" / "extensions"),
    ]
    for kind, label, base in search_bases:
        if not base.is_dir():
            continue
        ext_dirs = sorted(base.glob("anthropic.claude-code-*"), reverse=True)
        if not ext_dirs:
            continue
        ext_dir = ext_dirs[0]
        for name in ["claude.exe", "claude"] if IS_WINDOWS else ["claude"]:
            for p in ext_dir.rglob(name):
                if p.is_file() and not p.name.endswith(".bak") and p.stat().st_size > 10 * 1024 * 1024:
                    results.append(Installation(kind, p, f"{label} 捆绑二进制 ({ext_dir.name})"))
    return results


def find_all_installations() -> list[Installation]:
    all_inst: list[Installation] = []
    all_inst.extend(find_brew_installations())
    all_inst.extend(find_bun_installations())
    all_inst.extend(find_npm_installations())
    all_inst.extend(find_pnpm_installations())
    all_inst.extend(find_vscode_installations())
    seen: set[str] = set()
    deduped: list[Installation] = []
    for inst in all_inst:
        key = str(inst.target)
        if key not in seen:
            seen.add(key)
            deduped.append(inst)
    return deduped

# ── 补丁操作 ──────────────────────────────────────────────────────────

STATUS_SYMBOL = {"unpatched": "○", "patched": "●", "unknown": "?"}
STATUS_LABEL = {"unpatched": "未补丁", "patched": "已补丁", "unknown": "不兼容"}

# ANSI colors
_C_RESET = "\033[0m"
_C_BOLD = "\033[1m"
_C_GREEN = "\033[32m"
_C_YELLOW = "\033[33m"
_C_RED = "\033[31m"
_C_CYAN = "\033[36m"
_C_DIM = "\033[2m"

STATUS_COLOR = {"unpatched": _C_YELLOW, "patched": _C_GREEN, "unknown": _C_RED}


def _write_via_rename(target: Path, data: bytes) -> bool:
    tmp_path = target.with_suffix(target.suffix + ".tmp")
    old_path = target.with_suffix(target.suffix + ".old")
    for p in (tmp_path, old_path):
        try:
            p.unlink(missing_ok=True)
        except OSError:
            pass
    tmp_path.write_bytes(data)
    try:
        target.rename(old_path)
    except OSError:
        tmp_path.unlink(missing_ok=True)
        print(f"  ✗ 无法重命名 {target.name}，请关闭 claude 后重试。")
        return False
    tmp_path.rename(target)
    try:
        old_path.unlink(missing_ok=True)
    except OSError:
        pass
    return True


def apply_patch(inst: Installation, patches: list[PatchDef] | None = None) -> bool:
    targets = patches if patches is not None else ALL_PATCHES
    data = inst.target.read_bytes()
    statuses = get_all_statuses(data, targets)

    has_unpatched = any(s == "unpatched" for s in statuses.values())
    all_patched = all(s == "patched" for s in statuses.values())

    if all_patched:
        print("  ✓ 所有补丁已应用，跳过。")
        return True

    if not has_unpatched:
        unknown = [p.description for p in targets if statuses[p.name] == "unknown"]
        if unknown:
            print("  ✗ 以下补丁目标未找到（版本不兼容）:")
            for desc in unknown:
                print(f"    - {desc}")
        return False

    patched_data, counts = apply_all_patches(data, targets)
    total = sum(counts.values())

    if total == 0:
        print("  ✗ 未找到任何可补丁的目标。")
        return False

    if not inst.backup.is_file():
        shutil.copy2(inst.target, inst.backup)
        print(f"  已备份到 {inst.backup}")

    try:
        inst.target.write_bytes(patched_data)
    except PermissionError:
        print("  文件被占用，使用重命名方式替换...")
        if not _write_via_rename(inst.target, patched_data):
            return False

    ok, message = resign_if_needed(inst.target)
    if not ok:
        print(f"  ✗ 补丁已写入，但重签名失败: {message}")
        return False
    if message:
        print(f"  {message}")

    for patch in targets:
        c = counts[patch.name]
        status = statuses[patch.name]
        if c > 0:
            print(f"  ✓ {patch.description}: 替换 {c} 处")
        elif status == "patched":
            print(f"  - {patch.description}: 已是最新")
        else:
            print(f"  ✗ {patch.description}: 未找到目标")

    return True


def restore_backup(inst: Installation) -> bool:
    if not inst.backup.is_file():
        print(f"  ✗ 未找到备份文件 {inst.backup}")
        return False
    backup_data = inst.backup.read_bytes()
    try:
        inst.target.write_bytes(backup_data)
    except PermissionError:
        print("  文件被占用，使用重命名方式替换...")
        if not _write_via_rename(inst.target, backup_data):
            return False

    ok, message = resign_if_needed(inst.target)
    if not ok:
        print(f"  ✗ 已恢复，但重签名失败: {message}")
        return False
    if message:
        print(f"  {message}")

    print("  ✓ 已从备份恢复。")
    return True


def print_status(inst: Installation, patches: list[PatchDef] | None = None):
    targets = patches if patches is not None else ALL_WITH_STATUS
    data = inst.target.read_bytes()
    statuses = get_all_statuses(data, targets)
    has_backup = "有备份" if inst.backup.is_file() else "无备份"
    print(f"  {inst} | {has_backup}")
    for patch in targets:
        s = statuses[patch.name]
        color = STATUS_COLOR[s]
        print(f"    {color}{STATUS_SYMBOL[s]}{_C_RESET} {patch.description}: {STATUS_LABEL[s]}")
    print()

# ── 交互式 TUI ───────────────────────────────────────────────────────

_PATCH_LETTERS = "abcdefghijklmnopqrstuvwxyz"


def _clear_screen():
    print("\033[2J\033[H", end="", flush=True)


def _read_char() -> str:
    if IS_WINDOWS:
        import msvcrt
        return msvcrt.getwch()
    import tty
    import termios
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    return ch


def _draw_tui(installations, enabled, mode, inst_data):
    action = "补丁" if mode == "patch" else "恢复"
    max_letter = _PATCH_LETTERS[len(ALL_PATCHES) - 1]

    print(f"{_C_BOLD}{'=' * 60}")
    print("  Claude Code 综合补丁工具")
    print(f"{'=' * 60}{_C_RESET}")
    print(f"  系统: {SYSTEM} | Python {platform.python_version()}")
    print()

    print(f"补丁项 ({_C_CYAN}a-{max_letter} 切换{_C_RESET}):")
    for i, patch in enumerate(ALL_PATCHES):
        letter = _PATCH_LETTERS[i]
        mark = f"{_C_GREEN}x{_C_RESET}" if enabled[i] else " "
        desc = f"{_C_DIM}{patch.description}{_C_RESET}" if (not patch.default_enabled and not enabled[i]) else patch.description
        print(f"  {letter}. [{mark}] {desc}")
    print()

    print(
        f"  {_C_GREEN}●{_C_RESET} 已补丁  "
        f"{_C_YELLOW}○{_C_RESET} 未补丁  "
        f"{_C_RED}?{_C_RESET} 不兼容"
    )
    print()

    n = len(installations)
    print(f"检测到 {n} 个安装：")
    print()
    for i, inst in enumerate(installations, 1):
        data = inst_data[i - 1]
        has_backup = "有备份" if inst.backup.is_file() else "无备份"
        indicators: list[str] = []
        for j, patch in enumerate(ALL_PATCHES):
            letter = _PATCH_LETTERS[j]
            s = get_patch_status(data, patch)
            symbol = STATUS_SYMBOL[s]
            visible_text = f"{symbol} {letter}"
            padding = " " * (5 - len(visible_text))
            color = STATUS_COLOR[s] if enabled[j] else _C_DIM
            indicators.append(f"{color}{visible_text}{_C_RESET}{padding}")
        status_line = "".join(indicators)
        print(f"  {i}. [{inst.kind:6s}] {status_line}| {has_backup}")
        print(f"     {_C_DIM}{inst.target}{_C_RESET}")
        print()

    if n > 1:
        print(f"  0. 全部{action}")
        print()

    num_range = f"1-{n}" if n > 1 else "1"
    zero_hint = " | 0 全部" if n > 1 else ""
    print(
        f"{_C_CYAN}按 a-{max_letter} 切换补丁项 | "
        f"{num_range} {action}指定目标{zero_hint} | q 退出{_C_RESET}",
        flush=True,
    )


def interactive_tui(installations, mode="patch"):
    enabled = [p.default_enabled for p in ALL_PATCHES]
    inst_data = [inst.target.read_bytes() for inst in installations]

    _clear_screen()
    _draw_tui(installations, enabled, mode, inst_data)

    while True:
        try:
            ch = _read_char()
        except (EOFError, KeyboardInterrupt):
            print("\n已取消。")
            return

        choice = ch.lower()
        if choice in ("\x03", "\x1b"):
            print("\n已取消。")
            return
        if choice == "q":
            print("\n已取消。")
            return

        if choice in _PATCH_LETTERS:
            idx = _PATCH_LETTERS.index(choice)
            if idx < len(ALL_PATCHES):
                enabled[idx] = not enabled[idx]
                _clear_screen()
                _draw_tui(installations, enabled, mode, inst_data)
                continue

        if choice.isdigit():
            num = int(choice)
            n = len(installations)
            if num == 0 and n > 1:
                target_indices = list(range(n))
            elif 1 <= num <= n:
                target_indices = [num - 1]
            else:
                continue

            selected = [p for p, e in zip(ALL_PATCHES, enabled) if e]
            if not selected:
                print(f"\n{_C_RED}未选择任何补丁项。{_C_RESET}")
                continue

            for idx in target_indices:
                inst = installations[idx]
                print(f"\n→ 处理: {inst}")
                if mode == "patch":
                    apply_patch(inst, selected)
                else:
                    restore_backup(inst)

            print(f"\n{_C_GREEN}完成。重启 claude 生效。{_C_RESET}")
            return

# ── 入口 ──────────────────────────────────────────────────────────────


def auto_mode(installations, mode="patch", patches=None):
    if patches is None:
        patches = [p for p in ALL_PATCHES if p.default_enabled]
    for inst in installations:
        print(f"\n→ 处理: {inst}")
        if mode == "patch":
            apply_patch(inst, patches)
        else:
            restore_backup(inst)
    print("\n完成。重启 claude 生效。")


def main():
    mode = "patch"
    auto = False
    status_only = False
    for arg in sys.argv[1:]:
        if arg == "--restore":
            mode = "restore"
        elif arg == "--auto":
            auto = True
        elif arg == "--status":
            status_only = True

    is_interactive = not auto and not status_only

    def _print_header():
        print(f"{_C_BOLD}{'=' * 60}")
        print("  Claude Code 综合补丁工具")
        print(f"{'=' * 60}{_C_RESET}")
        print(f"  系统: {SYSTEM} | Python {platform.python_version()}")
        print()

    if is_interactive:
        _clear_screen()
        _print_header()
        print("正在扫描 Claude Code 安装...", flush=True)
    else:
        _print_header()
        print("正在扫描 Claude Code 安装...")

    installations = find_all_installations()

    if not installations:
        print(f"\n{_C_RED}未检测到任何 Claude Code 安装。{_C_RESET}")
        print("支持: bun / npm -g / pnpm / Homebrew / VS Code·Cursor")
        sys.exit(1)

    if status_only:
        print(f"\n检测到 {len(installations)} 个安装：\n")
        for inst in installations:
            print_status(inst)
        return

    if auto:
        auto_mode(installations, mode)
    else:
        interactive_tui(installations, mode)


if __name__ == "__main__":
    main()
