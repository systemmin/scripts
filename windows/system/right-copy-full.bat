@echo off
chcp 65001 >nul
setlocal

:: 添加/删除“复制文件路径”右键菜单（当前用户，无需管理员权限）
:: 用法：双击运行，选择 1 添加；选择 2 删除。

title 右键菜单 - 复制文件路径

echo.
echo ==========================================
echo   右键菜单：复制文件路径
echo ==========================================
echo.
echo 1. 添加右键菜单
echo 2. 删除右键菜单
echo 0. 退出
echo.
set /p choice=请选择 [1/2/0]:

if "%choice%"=="1" goto add
if "%choice%"=="2" goto remove
if "%choice%"=="0" goto end
echo 输入无效。
goto pause_end

:add
:: 文件、文件夹、磁盘根目录：复制被右键点击对象的完整路径
reg add "HKCU\Software\Classes\AllFilesystemObjects\shell\CopyFullPath" /ve /d "复制文件路径" /f >nul
reg add "HKCU\Software\Classes\AllFilesystemObjects\shell\CopyFullPath" /v "Icon" /d "imageres.dll,-5302" /f >nul
reg add "HKCU\Software\Classes\AllFilesystemObjects\shell\CopyFullPath\command" /ve /d "cmd.exe /c <nul set /p=\"%%1\"|clip" /f >nul

reg add "HKCU\Software\Classes\Drive\shell\CopyFullPath" /ve /d "复制文件路径" /f >nul
reg add "HKCU\Software\Classes\Drive\shell\CopyFullPath" /v "Icon" /d "imageres.dll,-5302" /f >nul
reg add "HKCU\Software\Classes\Drive\shell\CopyFullPath\command" /ve /d "cmd.exe /c <nul set /p=\"%%1\"|clip" /f >nul

:: 文件夹空白处右键：复制当前文件夹路径
reg add "HKCU\Software\Classes\Directory\Background\shell\CopyFullPath" /ve /d "复制当前文件夹路径" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\CopyFullPath" /v "Icon" /d "imageres.dll,-5302" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\CopyFullPath\command" /ve /d "cmd.exe /c <nul set /p=\"%%V\"|clip" /f >nul

echo.
echo 已添加完成。请在文件/文件夹上右键选择“复制文件路径”。
echo 如果菜单没有立即出现，请重启资源管理器或注销后再试。
goto pause_end

:remove
reg delete "HKCU\Software\Classes\AllFilesystemObjects\shell\CopyFullPath" /f >nul 2>nul
reg delete "HKCU\Software\Classes\Drive\shell\CopyFullPath" /f >nul 2>nul
reg delete "HKCU\Software\Classes\Directory\Background\shell\CopyFullPath" /f >nul 2>nul

echo.
echo 已删除右键菜单。
goto pause_end

:pause_end
echo.
pause

:end
endlocal
