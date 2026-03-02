#!/bin/bash

# ====================================================
# 方案二：主控端（NAS）测速汇总脚本 (排版终极修复版)
# ====================================================

CONFIG_FILE="$(dirname "$0")/speedtest.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "--- 首次运行，请配置基础信息 ---"
    read -p "请输入 Telegram Bot Token: " INPUT_TOKEN
    read -p "请输入 Telegram Chat ID: " INPUT_ID
    read -p "请输入待测速的服务器 IP: " INPUT_IPS
    cat <<EOF > "$CONFIG_FILE"
TG_TOKEN="$INPUT_TOKEN"
TG_CHATID="$INPUT_ID"
SERVERS=($INPUT_IPS)
EOF
fi

source "$CONFIG_FILE"

REPORT="🚀 *千兆版定时测速报表*%0A------------------%0A"

for IP in "${SERVERS[@]}"
do
    echo "正在测试 $IP ..."
    RESULT=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP "speedtest --accept-license --accept-gdpr" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 【暴力修复逻辑】
        # 1. grep 找到行
        # 2. sed 's/.*://' 去掉冒号前的内容
        # 3. sed 's/(.*//' 去掉左括号后的所有内容
        # 4. xargs 去掉前后多余空格
        PING=$(echo "$RESULT" | grep "Latency" | sed 's/.*://; s/(.*//' | xargs)
        DOWN=$(echo "$RESULT" | grep "Download" | sed 's/.*://; s/(.*//' | xargs)
        UP=$(echo "$RESULT" | grep "Upload" | sed 's/.*://; s/(.*//' | xargs)
        
        REPORT="${REPORT}📍 *主机:* $IP%0A🏓 *延迟:* $PING%0A⬇️ *下载:* $DOWN%0A⬆️ *上传:* $UP%0A------------------%0A"
    else
        REPORT="${REPORT}📍 *主机:* $IP%0A❌ *状态:* 无法连接或测速失败%0A------------------%0A"
    fi
done

curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHATID}" \
    -d "parse_mode=Markdown" \
    -d "text=${REPORT}"

echo "✅ 报表已推送到 TG"
