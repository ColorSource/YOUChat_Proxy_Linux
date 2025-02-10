#!/bin/bash
REPO_URL="https://github.com/YIWANG-sketch/YOUChat_Proxy.git"
REPO_NAME="YOUChat_Proxy"
CONFIG_FILE="config.mjs"
CONFIG_EXAMPLE_FILE="config.example.mjs"
SESSION_NAME="youchat_proxy"
LOG_FILE="/tmp/youchat_proxy_install_$(date +%s).log"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
log() {
    local color="$1"
    local message="$2"
    if [[ -z "$message" ]]; then
        message="$color"
        color="$GREEN"
    fi
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${color}${message}${NC}"
}
handle_error() {
    log "$RED" "错误: $1"
    exit 1
}
check_dependencies() {
    local deps=("git" "node" "google-chrome" "wget" "curl" "sudo" "python3" "screen")
    local missing_deps=()
    if ! dpkg -l | grep -q "xvfb"; then
        missing_deps+=("xvfb")
    fi
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "$YELLOW" "检测到缺少以下组件: ${missing_deps[*]}"
        return 1
    fi
    log "所有依赖已安装."
    return 0
}
install_dependencies() {
    log "正在安装必要组件..."
    {
        apt update
        apt install -y git wget curl sudo python3 xvfb xauth x11-xkb-utils screen
        if ! command -v google-chrome &> /dev/null; then
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
            apt install -y /tmp/google-chrome-stable_current_amd64.deb || handle_error "Chrome安装失败"
            rm /tmp/google-chrome-stable_current_amd64.deb
        fi
        if ! command -v node &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
            apt install -y nodejs || handle_error "Node.js安装失败"
            npm config set registry https://registry.npmmirror.com
        fi
    } >> "$LOG_FILE" 2>&1 || handle_error "安装过程失败，详情请查看 $LOG_FILE"
    log "组件安装完成."
}
setup_config() {
    log "配置 $REPO_NAME..."
    [ ! -f "$CONFIG_EXAMPLE_FILE" ] && handle_error "未找到配置文件模板"
    [ ! -f "$CONFIG_FILE" ] && cp "$CONFIG_EXAMPLE_FILE" "$CONFIG_FILE"
    # if ! grep -q "COOKIE=" "$CONFIG_FILE"; then
    #     log "$YELLOW" "警告: 配置文件中未设置Cookie"
    # fi
    sed -i 's/export USE_MANUAL_LOGIN=true/export USE_MANUAL_LOGIN=false/' start.sh
    log "$GREEN" "已禁用手动登录模式."
}
manage_screen_session() {
    set +e
    screen -S "$SESSION_NAME" -X stuff "^C" &>/dev/null
    sleep 1
    {
        screen -S "$SESSION_NAME" -X kill 2>/dev/null
        screen -XS "$SESSION_NAME" quit 2>/dev/null
        pkill -f "$SESSION_NAME" 2>/dev/null
    } >> "$LOG_FILE"
    local attempt=0
    while screen -ls | grep -q "$SESSION_NAME" && [ $attempt -lt 3 ]; do
        screen -XS "$SESSION_NAME" kill 2>/dev/null
        sleep 1
        ((attempt++))
    done
    set -e
    log "创建新会话..."
    if ! screen -dmS "$SESSION_NAME" bash start.sh; then
        handle_error "启动screen会话失败"
    fi
    sleep 2
    if ! screen -ls | grep -q "$SESSION_NAME"; then
        handle_error "会话启动后无法检测到"
    fi
    log "$GREEN" "会话管理完成 → PID $(pgrep -f "$SESSION_NAME")"
}
main() {
    [[ "$EUID" -ne 0 ]] && handle_error "请以root权限运行此脚本"
    set -eo pipefail
    check_dependencies || install_dependencies
    if [ ! -d "$REPO_NAME" ]; then
        git clone "$REPO_URL" || handle_error "克隆仓库失败"
        cd "$REPO_NAME" || handle_error "进入目录失败"
        setup_config
    else
        cd "$REPO_NAME" || handle_error "进入目录失败"
        log "$YELLOW" "已存在仓库目录，跳过克隆"
    fi
    [ "$(basename "$PWD")" != "$REPO_NAME" ] && handle_error "当前目录错误"
    manage_screen_session
    clear
    log "$GREEN" "运行环境安装完成！"
    echo -e "
使用说明：
\033[1;34m1.\033[0m 实时监控：\033[36mscreen -r $SESSION_NAME\033[0m
\033[1;34m2.\033[0m 配置路径：$PWD/$CONFIG_FILE
\033[1;34m3.\033[0m 重启服务：直接重新运行本脚本
\033[1;34m4.\033[0m 终止服务：kill \$(pgrep -f $SESSION_NAME)
"
}
main
