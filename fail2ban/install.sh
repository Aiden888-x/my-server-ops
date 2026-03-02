#!/bin/bash

# ====================================================
# 方案一：Fail2ban 极致安全加固脚本
# 功能：错一次封10年 + TG 实时告警
# ====================================================

# 1. 交互式获取配置参数
echo "--- 正在开始配置 Fail2ban 安全脚本 ---"
read -p "请输入你的 Telegram Bot Token: " TG_TOKEN
read -p "请输入你的 Telegram Chat ID: " TG_CHATID
read -p "请输入需要加白的 IP (建议输入你现在的电脑 IP，多个用空格隔开): " WHITELIST_IPS

# 2. 安装 Fail2ban (适配 Debian/Ubuntu)
sudo apt-get update && sudo apt-get install -y fail2ban curl

# 3. 创建 TG 告警动作脚本
# 当有 IP 被封禁时，调用此配置发送 TG 消息
cat <<EOF | sudo tee /etc/fail2ban/action.d/telegram-notify.conf
[Definition]
actionban = curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \\
            -d "chat_id=${TG_CHATID}" \\
            -d "parse_mode=Markdown" \\
            -d "text=🚨 *SSH 暴力破解拦截*%0A*主机:* \$(hostname)%0A*封禁IP:* <ip>%0A*时长:* 10年%0A*状态:* 已执行防火墙永久封禁"
actionunban = 
EOF

# 4. 编写 Fail2ban 核心配置文件
# bantime = 315360000 秒 (约10年)
# maxretry = 1 (错一次就封)
cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 ${WHITELIST_IPS}
bantime  = 315360000
findtime = 600
maxretry = 1

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
action  = %(action_mwl)s
          telegram-notify
EOF

# 5. 重启服务
sudo systemctl restart fail2ban

echo "----------------------------------------"
echo "✅ 部署完成！"
echo "- 规则：只要 SSH 密码错 1 次，直接封禁 10 年。"
echo "- 告警：已关联你的 Telegram Bot。"
echo "----------------------------------------"
