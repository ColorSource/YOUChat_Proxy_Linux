#!/bin/bash

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

handle_error() {
    log "错误: $1"
    exit 1
}

check_dependencies() {
    local deps=("git" "node" "google-chrome")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "检测到缺少以下组件: ${missing_deps[*]}"
        return 1
    fi
    return 0
}

install_dependencies() {
    log "开始安装必要组件..."
    
    local log_file="/tmp/install_$(date +%s).log"
    
    {
        apt update
        apt install -y wget curl sudo git python3 xvfb screen
        
        if ! command -v google-chrome &> /dev/null; then
            wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            apt install -y ./google-chrome-stable_current_amd64.deb || handle_error "Chrome安装失败"
            rm google-chrome-stable_current_amd64.deb
        fi
        
        if ! command -v node &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt install -y nodejs || handle_error "Node.js安装失败"
            npm config set registry https://registry.npmmirror.com
        fi
    } >> "$log_file" 2>&1 || handle_error "安装过程失败，详情请查看 $log_file"
}

setup_config() {
    log "配置YOUChat_Proxy..."
    
    if [ ! -f "config.mjs" ]; then
        if [ ! -f "config.example.mjs" ]; then
            handle_error "未找到配置文件模板"
        fi
        cp config.example.mjs config.mjs
    fi
    
    if ! grep -q "COOKIE=" config.mjs; then
        log "警告: 配置文件中未设置Cookie"
    fi
	
	sed -i 's/export USE_MANUAL_LOGIN=true/export USE_MANUAL_LOGIN=false/' start.sh
}

manage_screen_session() {
    local session_name="youchat_proxy"
    
    if screen -ls | grep -q "$session_name"; then
        log "正在关闭已存在的$session_name会话..."
        screen -S "$session_name" -X quit
        sleep 2
    fi
    
    log "启动新的screen会话..."
    screen -dmS "$session_name" bash start.sh || handle_error "启动screen会话失败"
}

main() {
    if [ "$EUID" -ne 0 ]; then 
        handle_error "请以root权限运行此脚本"
    fi
    
    set -e
    
    if ! check_dependencies; then
        install_dependencies
    fi
    
    if [ ! -d "YOUChat_Proxy" ]; then
        log "克隆YOUChat_Proxy仓库..."
        git clone https://github.com/YIWANG-sketch/YOUChat_Proxy.git || handle_error "克隆仓库失败"
        cd YOUChat_Proxy/
        setup_config
    else
        cd YOUChat_Proxy/
    fi
    
    manage_screen_session
    
    clear
    log "运行环境安装完成！"
    echo "
使用说明：
1. 使用 'screen -r youchat_proxy' 查看运行状态
2. 请在 YOUChat_Proxy/config.mjs 中填入Cookie
3. 其它设置请在 YOUChat_Proxy/start.sh 中修改
4. 首次运行安装完成后重新运行此脚本启动程序
"
}

main
