@echo off
setlocal enabledelayedexpansion

REM 同步 .claude 和 .gemini 配置到用户根目录

set "HOME_DIR=%USERPROFILE%"

REM 获取项目根目录（tools 上一级）
set "SCRIPT_DIR=%~dp0.."
for %%i in ("%SCRIPT_DIR%") do set "SCRIPT_DIR=%%~fi"

echo === 配置同步工具 ===
echo 源目录: %SCRIPT_DIR%
echo 目标目录: %HOME_DIR%
echo.

REM --- Claude Code ---
if exist "%SCRIPT_DIR%\.claude" (
    echo [Claude Code] 开始同步

    if not exist "%HOME_DIR%\.claude" mkdir "%HOME_DIR%\.claude"

    if exist "%HOME_DIR%\.claude\rules" rmdir /s /q "%HOME_DIR%\.claude\rules"
    if exist "%HOME_DIR%\.claude\skills" rmdir /s /q "%HOME_DIR%\.claude\skills"
    if exist "%HOME_DIR%\.claude\commands" rmdir /s /q "%HOME_DIR%\.claude\commands"
    if exist "%HOME_DIR%\.claude\templates" rmdir /s /q "%HOME_DIR%\.claude\templates"
    if exist "%HOME_DIR%\.claude\tasks" rmdir /s /q "%HOME_DIR%\.claude\tasks"

    echo   已清理旧配置目录

    if exist "%SCRIPT_DIR%\.claude\rules" xcopy /y /e /i /q "%SCRIPT_DIR%\.claude\rules" "%HOME_DIR%\.claude\rules"
    if exist "%SCRIPT_DIR%\.claude\skills" xcopy /y /e /i /q "%SCRIPT_DIR%\.claude\skills" "%HOME_DIR%\.claude\skills"
    if exist "%SCRIPT_DIR%\.claude\commands" xcopy /y /e /i /q "%SCRIPT_DIR%\.claude\commands" "%HOME_DIR%\.claude\commands"
    if exist "%SCRIPT_DIR%\.claude\templates" xcopy /y /e /i /q "%SCRIPT_DIR%\.claude\templates" "%HOME_DIR%\.claude\templates"
    if exist "%SCRIPT_DIR%\.claude\tasks" xcopy /y /e /i /q "%SCRIPT_DIR%\.claude\tasks" "%HOME_DIR%\.claude\tasks"

    if exist "%SCRIPT_DIR%\.claude\CLAUDE.md" copy /y "%SCRIPT_DIR%\.claude\CLAUDE.md" "%HOME_DIR%\.claude\" >nul

    echo   [√] rules/ skills/ commands/ templates/ tasks/ CLAUDE.md
) else (
    echo [Claude Code] 源目录不存在，跳过
)

echo.

REM --- Gemini CLI ---
if exist "%SCRIPT_DIR%\.gemini" (
    echo [Gemini CLI] 开始同步

    if not exist "%HOME_DIR%\.gemini" mkdir "%HOME_DIR%\.gemini"

    if exist "%HOME_DIR%\.gemini\commands" rmdir /s /q "%HOME_DIR%\.gemini\commands"
    if exist "%HOME_DIR%\.gemini\skills" rmdir /s /q "%HOME_DIR%\.gemini\skills"
    if exist "%HOME_DIR%\.gemini\rules" rmdir /s /q "%HOME_DIR%\.gemini\rules"

    echo   已清理旧配置目录

    if exist "%SCRIPT_DIR%\.gemini\commands" xcopy /y /e /i /q "%SCRIPT_DIR%\.gemini\commands" "%HOME_DIR%\.gemini\commands"
    if exist "%SCRIPT_DIR%\.gemini\skills" xcopy /y /e /i /q "%SCRIPT_DIR%\.gemini\skills" "%HOME_DIR%\.gemini\skills"
    if exist "%SCRIPT_DIR%\.gemini\rules" xcopy /y /e /i /q "%SCRIPT_DIR%\.gemini\rules" "%HOME_DIR%\.gemini\rules"

    if exist "%SCRIPT_DIR%\.gemini\GEMINI.md" copy /y "%SCRIPT_DIR%\.gemini\GEMINI.md" "%HOME_DIR%\.gemini\" >nul
    if exist "%SCRIPT_DIR%\.gemini\settings.json" copy /y "%SCRIPT_DIR%\.gemini\settings.json" "%HOME_DIR%\.gemini\" >nul

    echo   [√] commands/ skills/ rules/ GEMINI.md settings.json

    REM --- MCP 扩展检测 ---
    set "EXT_JSON=%SCRIPT_DIR%\.gemini\extensions.json"
    if exist "!EXT_JSON!" (
        echo.
        echo [Gemini CLI] 正在检测推荐扩展...

        REM 获取已安装扩展列表
        set "INSTALLED_EXTS="
        for /f "delims=" %%a in ('gemini extensions list 2^>nul') do (
            set "INSTALLED_EXTS=!INSTALLED_EXTS! %%a"
        )

        REM 使用 python3 解析 JSON 检查缺失
        set "HAS_MISSING=0"
        for /f "tokens=1,2,3 delims=|" %%a in ('python -c "import json,sys;data=json.load(open(sys.argv[1]));installed=sys.argv[2];[print(e['id']+'|'+e['name']+'|'+e['url']) for e in data.get('recommendations',[]) if e['id'] not in installed]" "!EXT_JSON!" "!INSTALLED_EXTS!" 2^>nul') do (
            if "!HAS_MISSING!"=="0" (
                echo 检测到以下推荐扩展尚未安装：
                set "HAS_MISSING=1"
            )
            echo   - %%b ^(%%a^)
        )

        if "!HAS_MISSING!"=="1" (
            echo.
            set /p "confirm=是否现在安装上述缺失的扩展？[Y/n] "
            if /i "!confirm!"=="" set "confirm=Y"
            if /i "!confirm!"=="Y" (
                for /f "tokens=1,2,3 delims=|" %%a in ('python -c "import json,sys;data=json.load(open(sys.argv[1]));installed=sys.argv[2];[print(e['id']+'|'+e['name']+'|'+e['url']) for e in data.get('recommendations',[]) if e['id'] not in installed]" "!EXT_JSON!" "!INSTALLED_EXTS!" 2^>nul') do (
                    echo 正在安装 %%b...
                    gemini extensions install "%%c"
                )
                echo [√] 扩展安装完成
            ) else (
                echo 已跳过扩展安装。你可以之后手动安装。
            )
        ) else (
            echo [√] 所有推荐扩展已安装
        )
    )
) else (
    echo [Gemini CLI] 源目录不存在，跳过
)

echo.
echo === 同步完成 ===
pause
