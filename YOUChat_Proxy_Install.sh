#!/bin/bash
# --- Configuration ---
REPO_URL="https://github.com/YIWANG-sketch/YOUChat_Proxy.git"
REPO_NAME="YOUChat_Proxy"
CONFIG_FILE="config.mjs"
CONFIG_EXAMPLE_FILE="config.example.mjs"
SESSION_NAME="youchat_proxy"
LOG_FILE="/tmp/youchat_proxy_install_$(date +%s).log"

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Functions ---
# Logging function with color support
log() {
    local color="$1"
    local message="$2"
    if [[ -z "$message" ]]; then
        message="$color"
        color="$GREEN"
    fi
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${color}${message}${NC}"
}

# Error handling function
handle_error() {
    log "$RED" "错误: $1"
    exit 1
}

# Check for required dependencies
check_dependencies() {
    local deps=("git" "node" "google-chrome" "wget" "curl" "sudo" "python3" "screen")
    local missing_deps=()
    
    # 特别检查 xvfb
    if ! dpkg -l | grep -q "xvfb"; then
        missing_deps+=("xvfb")
    fi
    
    # 检查其他依赖
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

# Install necessary dependencies using apt
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
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt install -y nodejs || handle_error "Node.js安装失败"
            npm config set registry https://registry.npmmirror.com
        fi
    } >> "$LOG_FILE" 2>&1 || handle_error "安装过程失败，详情请查看 $LOG_FILE"
    log "组件安装完成."
}

# Set up the configuration file
setup_config() {
    log "配置 $REPO_NAME..."
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ ! -f "$CONFIG_EXAMPLE_FILE" ]; then
            handle_error "未找到配置文件模板"
        fi
        cp "$CONFIG_EXAMPLE_FILE" "$CONFIG_FILE"
        log "$GREEN" "已创建配置文件: $CONFIG_FILE"
    else
        log "$YELLOW" "配置文件已存在: $CONFIG_FILE"
    fi
    if ! grep -q "COOKIE=" "$CONFIG_FILE"; then
        log "$YELLOW" "警告: 配置文件中未设置Cookie"
    fi
    sed -i 's/export USE_MANUAL_LOGIN=true/export USE_MANUAL_LOGIN=false/' start.sh
    log "$GREEN" "已禁用手动登录模式."
}

# Manage the screen session
manage_screen_session() {
    if screen -ls | grep -q "$SESSION_NAME"; then
        log "正在关闭已存在的 $SESSION_NAME 会话..."
        screen -S "$SESSION_NAME" -X quit
        sleep 2
    fi
    log "启动新的screen会话..."
    screen -dmS "$SESSION_NAME" bash start.sh || handle_error "启动screen会话失败"
    log "$GREEN" "已在后台启动 $SESSION_NAME 会话."
}

# --- Main Script ---
main() {
    # Check for root privileges
    if [ "$EUID" -ne 0 ]; then
        handle_error "请以root权限运行此脚本"
    fi

    # Exit on error
    set -e

    # Check and install dependencies
    if ! check_dependencies; then
        install_dependencies
    fi

    # Clone or enter the repository
    if [ ! -d "$REPO_NAME" ]; then
        log "克隆 $REPO_NAME 仓库..."
        git clone "$REPO_URL" || handle_error "克隆仓库失败"
        cd "$REPO_NAME" || handle_error "进入 $REPO_NAME 目录失败"
        setup_config
    else
        cd "$REPO_NAME" || handle_error "进入 $REPO_NAME 目录失败"
        log "$YELLOW" "已存在 $REPO_NAME 目录, 跳过克隆."
        # Consider pulling updates if the repo already exists:
        # log "正在更新 $REPO_NAME 仓库..."
        # git pull origin master
    fi

    # Check if inside YOUChat_Proxy directory
    if [ "$(basename "$PWD")" != "$REPO_NAME" ]; then
        handle_error "当前目录不是 $REPO_NAME, 请进入 $REPO_NAME 目录后重新运行"
    fi

    # Manage screen session only if not already running
    if ! screen -ls | grep -q "$SESSION_NAME"; then
        manage_screen_session
    fi

    clear
    log "$GREEN" "运行环境安装完成！"
    echo "
使用说明：
1. 使用 'screen -r $SESSION_NAME' 查看运行状态
2. 请在 $REPO_NAME/$CONFIG_FILE 中填入Cookie
3. 其它设置请在 $REPO_NAME/start.sh 中修改
4. 首次运行安装完成后重新运行此脚本启动程序
"
}

# --- Run the main function ---
main
