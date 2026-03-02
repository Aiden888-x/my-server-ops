#!/bin/bash

# ====================================================
# 方案二：主控端（NAS）测速汇总脚本 (终极正式版)
# ====================================================

# 1. 本地配置文件路径 (仅存放在你的 NAS 上，不上传 GitHub)
CONFIG_FILE="$(dirname "$0")/speedtest.conf"

# 2. 如果本地没有配置文件，则进入交互式配置
if [ ! -f "$CONFIG_FILE" ]; then
    echo "--- 首次运行，请配置基础信息 (信息将保存在本地 speedtest.conf) ---"
    read -p "请输入 Telegram Bot Token: " INPUT_TOKEN
    read -p "请输入 Telegram Chat ID: " INPUT_ID
    read -p "请输入待测速的服务器 IP (多个用空格隔开): " INPUT_IPS
    
    # 将配置写入本地隐藏文件
    cat <<EOF > "$CONFIG_FILE"
TG_TOKEN="$INPUT_TOKEN"
TG_CHATID="$INPUT_ID"
SERVERS=($INPUT_IPS)
EOF
    echo "✅ 配置已保存到 $CONFIG_FILE"
fi

# 3. 加载本地配置
source "$CONFIG_FILE"

# 4. 开始执行测速逻辑
REPORT="🚀 *千兆版定时测速报表*%0A------------------%0A"

for IP in "${SERVERS[@]}"
do
    echo "正在测试 $IP (官方千兆版) ..."
    # 远程执行，添加协议自动接受，增加超时判定
    RESULT=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP "speedtest --accept-license --accept-gdpr" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 【精准提取逻辑】过滤掉冒号后的空格，只取前两个词（数字+单位），彻底剔除括号内容
        PING=$(echo "$RESULT" | grep "Latency" | head -n1 | awk -F': ' '{print $2}' | awk '{print $1, $2}')
        DOWN=$(echo "$RESULT" | grep "Download" | awk -F': ' '{print $2}' | awk '{print $1, $2}')
        UP=$(echo "$RESULT" | grep "Upload" | awk -F': ' '{print $2}' | awk '{print $1, $2}')
        
        REPORT="${REPORT}📍 *主机:* $IP%0A🏓 *延迟:* $PING%0A⬇️ *下载:* $DOWN%0A⬆️ *上传:* $UP%0A------------------%0A"
    else
        REPORT="${REPORT}📍 *主机:* $IP%0A❌ *状态:* 无法连接或测速失败%0A------------------%0A"
    fi
done

# 5. 发送 TG 消息
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHATID}" \
    -d "parse_mode=Markdown" \
    -d "text=${REPORT}"

echo "✅ 报表已推送到 TG，请检查群组消息。"
