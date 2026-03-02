#!/bin/bash

# ====================================================
# 方案二：主控端（NAS）测速汇总脚本 (安全配置版)
# ====================================================

# 本地配置文件路径 (存放在 NAS 上，不上传 GitHub)
CONFIG_FILE="$(dirname "$0")/speedtest.conf"

# 1. 检查本地配置文件是否存在，不存在则提示输入
if [ ! -f "$CONFIG_FILE" ]; then
    echo "--- 首次运行，请配置基础信息 (信息将保存在本地 speedtest.conf) ---"
    read -p "请输入 Telegram Bot Token: " INPUT_TOKEN
    read -p "请输入 Telegram Chat ID: " INPUT_ID
    read -p "请输入待测速的服务器 IP (多个用空格隔开): " INPUT_IPS
    
    # 将配置写入本地文件
    cat <<EOF > "$CONFIG_FILE"
TG_TOKEN="$INPUT_TOKEN"
TG_CHATID="$INPUT_ID"
SERVERS=($INPUT_IPS)
EOF
    echo "✅ 配置已保存到 $CONFIG_FILE"
fi

# 2. 加载本地配置
source "$CONFIG_FILE"

# 3. 开始执行测速逻辑
REPORT="🚀 *定时测速汇总报表*%0A------------------%0A"

for IP in "${SERVERS[@]}"
do
    echo "正在测试 $IP ..."
    RESULT=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$IP "speedtest-cli --simple" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        PING=$(echo "$RESULT" | grep "Ping" | awk '{print $2, $3}')
        DOWN=$(echo "$RESULT" | grep "Download" | awk '{print $2, $3}')
        UP=$(echo "$RESULT" | grep "Upload" | awk '{print $2, $3}')
        REPORT="${REPORT}📍 *主机:* $IP%0A🏓 *延迟:* $PING%0A⬇️ *下载:* $DOWN%0A⬆️ *上传:* $UP%0A------------------%0A"
    else
        REPORT="${REPORT}📍 *主机:* $IP%0A❌ *状态:* 无法连接或测速失败%0A------------------%0A"
    fi
done

# 4. 发送 TG 消息
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHATID}" \
    -d "parse_mode=Markdown" \
    -d "text=${REPORT}"

echo "✅ 任务完成。"
