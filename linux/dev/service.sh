#!/bin/bash
#=============================================================================
#  Mall 微服务管理脚本
#  用法:
#    ./service.sh start   <服务名>   启动指定服务
#    ./service.sh stop    <服务名>   停止指定服务
#    ./service.sh restart <服务名>   重启指定服务
#    ./service.sh status  [服务名]   查看服务状态(不传则查看全部)
#    ./service.sh start-all          启动全部服务
#    ./service.sh stop-all           停止全部服务
#    ./service.sh restart-all        重启全部服务
#    ./service.sh list               列出所有服务
#
#  示例:
#    ./service.sh start mall-gateway
#    ./service.sh stop mall-order
#    ./service.sh restart mall-auth-server
#    ./service.sh status
#=============================================================================

#------------ 配置区 ------------
# 脚本所在目录(即 jar 所在目录)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="${BASE_DIR}/pids"
LOG_DIR="${BASE_DIR}/logs"

# JVM 参数, 按需修改
JVM_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

# 排除的 jar (公共库, 不可启动)
EXCLUDE_JARS=("mall-commons-1.0-SNAPSHOT.jar")

# 启动间隔(秒), 避免同时启动造成资源争抢
START_INTERVAL=3

#------------ 工具函数 ------------

# 初始化目录
init_dirs() {
    mkdir -p "${PID_DIR}" "${LOG_DIR}"
}

# 获取所有可管理的服务名(不含 .jar 后缀)
list_services() {
    local jars=()
    for f in "${BASE_DIR}"/*.jar; do
        [ -f "$f" ] || continue
        local basename
        basename="$(basename "$f")"
        # 检查是否在排除列表
        local skip=false
        for ex in "${EXCLUDE_JARS[@]}"; do
            if [ "$basename" = "$ex" ]; then
                skip=true
                break
            fi
        done
        $skip && continue
        jars+=("${basename%.jar}")
    done
    printf '%s\n' "${jars[@]}" | sort
}

# 获取服务 jar 完整路径
get_jar_path() {
    local name="$1"
    echo "${BASE_DIR}/${name}.jar"
}

# 获取服务 PID 文件路径
get_pid_file() {
    local name="$1"
    echo "${PID_DIR}/${name}.pid"
}

# 获取服务日志文件路径
get_log_file() {
    local name="$1"
    echo "${LOG_DIR}/${name}.log"
}

# 读取 PID, 返回 0 表示服务运行中, 1 表示未运行
read_pid() {
    local name="$1"
    local pid_file
    pid_file="$(get_pid_file "$name")"

    if [ -f "$pid_file" ]; then
        local pid
        pid="$(cat "$pid_file")"
        if kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        else
            # 进程已死, 清理残留 pid 文件
            rm -f "$pid_file"
        fi
    fi
    return 1
}

# 校验服务名是否合法
validate_service() {
    local name="$1"
    local jar_path
    jar_path="$(get_jar_path "$name")"
    if [ ! -f "$jar_path" ]; then
        echo "错误: 找不到服务 ${name} (jar 文件不存在: ${jar_path})"
        return 1
    fi
    return 0
}

#------------ 核心操作 ------------

do_start() {
    local name="$1"
    validate_service "$name" || return 1

    local pid
    if pid="$(read_pid "$name")"; then
        echo "服务 ${name} 已在运行 (PID: ${pid})"
        return 0
    fi

    local jar_path
    jar_path="$(get_jar_path "$name")"
    local pid_file
    pid_file="$(get_pid_file "$name")"
    local log_file
    log_file="$(get_log_file "$name")"

    echo "正在启动服务 ${name} ..."
    nohup java ${JVM_OPTS} -jar "${jar_path}" \
        --spring.profiles.active=prod \
        > "${log_file}" 2>&1 &

    local new_pid=$!
    echo "$new_pid" > "$pid_file"

    # 等待片刻, 检查进程是否仍存活
    sleep 2
    if kill -0 "$new_pid" 2>/dev/null; then
        echo "服务 ${name} 启动成功 (PID: ${new_pid})"
        echo "日志文件: ${log_file}"
        return 0
    else
        echo "错误: 服务 ${name} 启动后立即退出, 请检查日志: ${log_file}"
        rm -f "$pid_file"
        return 1
    fi
}

do_stop() {
    local name="$1"
    validate_service "$name" || return 1

    local pid
    if ! pid="$(read_pid "$name")"; then
        echo "服务 ${name} 未运行"
        return 0
    fi

    echo "正在停止服务 ${name} (PID: ${pid}) ..."
    kill "$pid"

    # 优雅等待, 最多 30 秒
    local waited=0
    while [ $waited -lt 30 ]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$(get_pid_file "$name")"
            echo "服务 ${name} 已停止"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    # 超时后强制终止
    echo "服务 ${name} 优雅关闭超时, 强制终止 ..."
    kill -9 "$pid" 2>/dev/null
    rm -f "$(get_pid_file "$name")"
    echo "服务 ${name} 已强制停止"
    return 0
}

do_restart() {
    local name="$1"
    do_stop "$name"
    sleep 1
    do_start "$name"
}

do_status() {
    local name="$1"

    if [ -n "$name" ]; then
        # 查看单个服务
        validate_service "$name" || return 1
        local pid
        if pid="$(read_pid "$name")"; then
            echo "服务 ${name} 运行中 (PID: ${pid})"
        else
            echo "服务 ${name} 未运行"
        fi
    else
        # 查看全部服务
        printf "%-30s %-10s %s\n" "服务名" "状态" "PID"
        printf "%-30s %-10s %s\n" "------" "----" "---"
        while IFS= read -r svc; do
            local pid
            if pid="$(read_pid "$svc")"; then
                printf "%-30s %-10s %s\n" "$svc" "运行中" "$pid"
            else
                printf "%-30s %-10s %s\n" "$svc" "未运行" "-"
            fi
        done < <(list_services)
    fi
}

do_start_all() {
    echo "========== 启动全部服务 =========="
    local failed=0
    while IFS= read -r svc; do
        do_start "$svc" || failed=$((failed + 1))
        sleep "${START_INTERVAL}"
    done < <(list_services)
    echo "========== 启动完成 (失败: ${failed}) =========="
}

do_stop_all() {
    echo "========== 停止全部服务 =========="
    local failed=0
    while IFS= read -r svc; do
        do_stop "$svc" || failed=$((failed + 1))
    done < <(list_services)
    echo "========== 停止完成 (失败: ${failed}) =========="
}

do_restart_all() {
    do_stop_all
    sleep 2
    do_start_all
}

do_list() {
    echo "可管理的服务列表:"
    while IFS= read -r svc; do
        echo "  - ${svc}"
    done < <(list_services)
}

#------------ 主入口 ------------

init_dirs

case "${1}" in
    start)
        [ -z "${2}" ] && { echo "用法: $0 start <服务名>"; exit 1; }
        do_start "${2}"
        ;;
    stop)
        [ -z "${2}" ] && { echo "用法: $0 stop <服务名>"; exit 1; }
        do_stop "${2}"
        ;;
    restart)
        [ -z "${2}" ] && { echo "用法: $0 restart <服务名>"; exit 1; }
        do_restart "${2}"
        ;;
    status)
        do_status "${2:-}"
        ;;
    start-all)
        do_start_all
        ;;
    stop-all)
        do_stop_all
        ;;
    restart-all)
        do_restart_all
        ;;
    list)
        do_list
        ;;
    *)
        echo "Mall 微服务管理脚本"
        echo ""
        echo "用法: $0 {start|stop|restart|status|start-all|stop-all|restart-all|list} [服务名]"
        echo ""
        echo "命令:"
        echo "  start   <服务名>   启动指定服务"
        echo "  stop    <服务名>   停止指定服务"
        echo "  restart <服务名>   重启指定服务"
        echo "  status  [服务名]   查看服务状态(不传则查看全部)"
        echo "  start-all          启动全部服务"
        echo "  stop-all           停止全部服务"
        echo "  restart-all        重启全部服务"
        echo "  list               列出所有服务"
        echo ""
        echo "示例:"
        echo "  $0 start mall-gateway"
        echo "  $0 stop mall-order"
        echo "  $0 status"
        exit 1
        ;;
esac