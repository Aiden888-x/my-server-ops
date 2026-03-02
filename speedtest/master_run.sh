#!/bin/bash

# ====================================================
# 方案二：主控端（NAS）测速汇总脚本 (正则精准抓取版)
# ====================================================

# 1. 本地配置文件路径
CONFIG_FILE="$(dirname "$0")/speedtest.conf"

# 2. 首次运行交互配置
if [ ! -f "$CONFIG_FILE" ]; then
    echo "--- 首次运行，请配置基础信息 ---"
    read -p "请输入 Telegram Bot Token: " INPUT_TOKEN
    read -p "请输入 Telegram Chat ID: " INPUT_ID
    read -p "请输入待测速的服务器 IP (多个用空格隔开): " INPUT_IPS
    
    cat <<EOF > "$CONFIG_FILE"
TG_TOKEN="$INPUT_TOKEN"
TG_CHATID="$INPUT_ID"
SERVERS=($INPUT_IPS)
EOF
    echo "✅ 配置已保存到 $CONFIG_FILE"
fi

source "$CONFIG_FILE"

REPORT="🚀 *千兆版定时测速报表*%0A------------------%0A"

for IP in "${SERVERS[@]}"
do
    echo "正在测试 $IP ..."
    # 远程执行测速
    RESULT=$(ssh -o ConnectTimeout=15 -o StrictHostKeyChecking=no root@$IP "speedtest --accept-license --accept-gdpr" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 【正则抓取逻辑】
        # grep -oE "[0-9.]+ [a-zA-Z/]+" 会匹配类似 "100.00 Mbps" 或 "5.5 ms" 的格式
        # head -n1 确保只取第一组数据（即网速），避开后面的流量消耗统计
        PING=$(echo "$RESULT" | grep "Latency" | grep -oE "[0-9.]+ [a-zA-Z]+" | head -n1)
        DOWN=$(echo "$RESULT" | grep "Download" | grep -oE "[0-9.]+ [a-zA-Z/]+" | head -n1)
        UP=$(echo "$RESULT" | grep "Upload" | grep -oE "[0-9.]+ [a-zA-Z/]+" | head -n1)
        
        REPORT="${REPORT}📍 *主机:* $IP%0A🏓 *延迟:* $PING%0A⬇️ *下载:* $DOWN%0A⬆️ *上传:* $UP%0A------------------%0A"
    else
        REPORT="${REPORT}📍 *主机:* $IP%0A❌ *状态:* 无法连接或测速失败%0A------------------%0A"
    fi
done

# 3. 发送 TG 消息
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHATID}" \
    -d "parse_mode=Markdown" \
    -d "text=${REPORT}"

echo "✅ 报表已推送到 TG"
