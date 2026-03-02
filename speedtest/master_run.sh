#!/bin/bash

# ====================================================
# 方案二：主控端（NAS）测速汇总脚本
# ====================================================

# --- 基础配置 ---
TG_TOKEN="8502034368:AAENUL-JUvj2k_XX0FcH_rvV9yVlGjEUhcw"
TG_CHATID="-5084029270"

# --- 待测速的服务器 IP 列表 (空格隔开) ---
SERVERS=("你的服务器IP1" "你的服务器IP2")

REPORT="🚀 *定时测速汇总报表*%%0A------------------%%0A"

for IP in "${SERVERS[@]}"
do
    echo "正在测试 $IP ..."
    # 远程执行测速并获取结果
    # 使用 timeout 防止某台机器挂了导致整个脚本卡死
    RESULT=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$IP "speedtest-cli --simple" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        PING=$(echo "$RESULT" | grep "Ping" | awk '{print $2, $3}')
        DOWN=$(echo "$RESULT" | grep "Download" | awk '{print $2, $3}')
        UP=$(echo "$RESULT" | grep "Upload" | awk '{print $2, $3}')
        REPORT="${REPORT}📍 *主机:* $IP%%0A🏓 *延迟:* $PING%%0A⬇️ *下载:* $DOWN%%0A⬆️ *上传:* $UP%%0A------------------%%0A"
    else
        REPORT="${REPORT}📍 *主机:* $IP%%0A❌ *状态:* 无法连接或测速失败%%0A------------------%%0A"
    fi
done

# 发送 TG 消息
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHATID}" \
    -d "parse_mode=Markdown" \
    -d "text=${REPORT}"

echo "✅ 报表已推送到 TG"
