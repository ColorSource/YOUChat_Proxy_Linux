#!/bin/bash

# 检查是否已存在screen会话并关闭
if screen -ls | grep -q "youchat_proxy"; then
    echo "检测到已存在的youchat_proxy会话，正在关闭..."
    screen -S youchat_proxy -X quit
    sleep 2
fi

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请以root权限运行此脚本"
    exit 1
fi

# 设置错误时退出
set -e

# 检查是否已安装必要组件
if ! command -v git &> /dev/null || ! command -v node &> /dev/null || ! command -v google-chrome &> /dev/null; then
    echo "检测到缺少必要组件，开始安装..."
    # 更新系统并安装基础包
    apt update
    apt install -y wget curl sudo git python3 xvfb screen

    # 下载并安装Chrome
    echo "正在下载并安装Chrome..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb

    # 安装Node.js
    echo "正在安装Node.js环境..."
    apt install -y nodejs npm
    npm config set registry https://registry.npmmirror.com
    npm install -g n
    apt remove -y nodejs npm
    apt autoremove -y
    n latest
fi

# 检查YOUChat_Proxy目录是否存在
if [ ! -d "YOUChat_Proxy" ]; then
    echo "正在克隆YOUChat_Proxy..."
    git clone https://github.com/YIWANG-sketch/YOUChat_Proxy.git
    cd YOUChat_Proxy/
    
    # 重命名配置文件
    echo "正在初始化配置文件..."
    mv config.example.mjs config.mjs
    
    # 修改start.sh中的设置
    echo "修改配置设置..."
    sed -i 's/export USE_MANUAL_LOGIN=true/export USE_MANUAL_LOGIN=false/' start.sh
    sed -i 's/export UPLOAD_FILE_FORMAT=docx/export UPLOAD_FILE_FORMAT=txt/' start.sh
else
    cd YOUChat_Proxy/
fi

# 创建新的screen会话并启动服务
echo "正在启动服务..."
screen -dmS youchat_proxy bash start.sh

# 清空屏幕
clear

echo "使用 'screen -r youchat_proxy' 命令查看运行状态"
echo "只支持Cookie登录 请在YOUChat_Proxy/config.mjs中填入自己的Cookie"
echo "其它设置请在YOUChat_Proxy/start.sh中修改"
echo "确保config.mjs和start.sh都修改为自己的配置后再次运行本脚本"
