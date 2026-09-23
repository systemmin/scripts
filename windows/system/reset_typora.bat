@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

@REM 重置 Typora 试用

echo APPDATA 路径：%APPDATA%

del %APPDATA%\Typora\history.data

echo 删除 history.data

del %APPDATA%\Typora\profile.data

echo 删除 profile.data

echo done ....

pause

exit /b 0

