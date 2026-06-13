@echo off
chcp 65001
title Java项目启动
rem Description: 使用 Javaw 启动项目没有命令行窗口，多jdk环境指定 jdk 运行

:: ====================== 配置区 ======================
set "JAR_PATH=xxxx.jar"
set "JAVA_OPTS=-Xms256m -Xmx512m"
set "JAVA_ACTIVE=dev"
set "JAVA_LIBS=../../release/api/libs"
set "LOG_PATH=app.log"
:: ====================================================

echo 正在启动 Java 项目...
echo JAR路径: %JAR_PATH%

if not exist "%JAR_PATH%" (
    echo 错误：未找到 jar 文件！
    pause
    exit /b 1
)

:: 1. 指定 JDK 路径
set "JAVA_HOME=D:\Java\jdk1.8.0_301"

:: 2. 把当前 JDK 的 bin 放到 PATH 最前面
set "PATH=%JAVA_HOME%\bin;%PATH%"

:: 3. 验证
java -version
javac -version


start "JavaApp" javaw %JAVA_OPTS% -Dloader.path=%JAVA_LIBS% -jar "%JAR_PATH%" --spring.profiles.active="%JAVA_ACTIVE%" >> "%LOG_PATH%" 2>&1

echo 启动成功！
pause

