#!/bin/bash
# Description: 脚本用途
# Usage: ./setup.sh [args]

JAR_NAME=`ls *.jar | head -n 1`

echo $JAR_NAME

# 备份目录
FOLDER_NAME="./backups";
# 当前时间
CURR_TIME=`date +"%Y-%m-%d%H:%M:%S"`;
# 提示方法
tips(){
  echo "
  tips: spring自动化部署脚本
  start   -- 启动
  stop    -- 停止
  restart -- 重启
  status  -- 状态";
  exit 1;
}

#检查程序是否在运行
exist(){
  pid=`ps -ef | grep $JAR_NAME | grep -v grep | awk '{print $2}' `
  # pid 是否为空 不为空返回 1 为空返回0
  if [ -z "${pid}" ]; then
   return 0
  else
    return 1
  fi
}

# 启动
start(){
  exist;
  if [ $? -eq "1" ]; then
    echo  ">>> 正在运行中PID：${pid} <<<";
  else
   nohup java -Dloader.path=./libs  -jar $JAR_NAME --spring.profiles.active=test  >oooo.log 2>&1 &
         
    echo ">>> $JAR_NAME 启动成功进程PID：$! <<<"
  fi;
}

# 停止
stop(){
  exist;
  if [ $? -eq "1" ]; then
    echo ">>> 开始结束进程 $pid …… <<<";
    kill9;
  else
    echo ">>> $JAR_NAME 未启动……$! <<<";
  fi
}

# 强制结束进程
kill9(){
  kill -9 $pid;
  sleep 2
  exist;
  if [ $? -eq "0" ]; then
   echo ">>> $JAR_NAME 已停止运行 <<<";
  fi
  create;#创建备份
  copyFile;
}
# 备份文件
copyFile(){
  cp -p $JAR_NAME ./$FOLDER_NAME/$CURR_TIME$JAR_NAME
  sleep 2
  echo ">>> $JAR_NAME 数据备份完成 <<<";
  rm -rf $JAR_NAME
}

# 重启
restart(){
  exist;
  if [ $? -eq "0" ]; then
  	
     echo  ">>> $JAR_NAME 未启动 <<<";
  else
    echo  ">>> $JAR_NAME 开始重启 <<<";
    kill -9 $pid;
    sleep 2
    start;
    echo  ">>> $JAR_NAME 重启成功 <<<";.
  fi
}

# 状态
status(){
  exist;
  if [ $? -eq "1" ]; then
    echo ">>> 正在运行中PID： $pid …… <<<";
  else
    echo ">>> $JAR_NAME 未启动……$! <<<";
  fi
}

# 文件夹不存在创建
create(){
  if [ ! -e $FOLDER_NAME ]; then
    mkdir ./$FOLDER_NAME
  fi
}


# 根据输入参数，选择执行对应方法，不输入则执行使用说明
case "$1" in
    "start")
    start
      ;;
      "stop")
    stop
      ;;
      "restart")
    restart
      ;;
      "status")
    status
      ;; *)
    tips
      ;;
esac
exit 0
