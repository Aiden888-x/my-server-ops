#!/bin/bash

# ====================================================
# 方案二：受控端（流量机）环境初始化
# ====================================================

echo "--- 正在初始化测速受控端 ---"

# 1. 安装测速工具
sudo apt-get update && sudo apt-get install -y speedtest-cli

# 2. 配置 SSH 免密登录 (允许 NAS 访问)
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "------------------------------------------------"
echo "请输入你的 NAS SSH 公钥 (id_rsa.pub 的内容):"
read -p "> " NAS_PUB_KEY

if [ -z "$NAS_PUB_KEY" ]; then
    echo "❌ 错误：未输入公钥，免密登录将无法生效！"
else
    echo "$NAS_PUB_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "✅ NAS 公钥已授权。"
fi

echo "------------------------------------------------"
echo "✅ 受控端初始化完成！"
