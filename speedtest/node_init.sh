#!/bin/bash

# ====================================================
# 方案二：受控端（流量机）环境初始化 - 官方千兆版
# ====================================================

echo "--- 正在安装官方 Speedtest 千兆版客户端 ---"

# 1. 移除旧的 Python 版工具
sudo apt-get remove -y speedtest-cli || true

# 2. 安装官方仓库并安装原生 speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install -y speedtest

# 3. 配置 SSH 免密登录 (保持原逻辑)
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "------------------------------------------------"
echo "请输入你的 NAS SSH 公钥 (id_rsa.pub 的内容):"
read -p "> " NAS_PUB_KEY

if [ -z "$NAS_PUB_KEY" ]; then
    echo "⚠️ 未输入新公钥，将保留现有授权。"
else
    # 避免重复添加
    grep -q "$NAS_PUB_KEY" ~/.ssh/authorized_keys || echo "$NAS_PUB_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "✅ NAS 公钥已授权。"
fi

echo "------------------------------------------------"
echo "✅ 千兆受控端准备就绪！"
