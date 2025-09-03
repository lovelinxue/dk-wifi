#!/bin/bash
set -e

BASE_DIR="$HOME/Library/NetworkScripts"
MONITOR="$BASE_DIR/monitor_wifi.sh"
LOG_FILE="$BASE_DIR/monitor_wifi.log"
CONFIG_FILE="$BASE_DIR/user_config.conf"

mkdir -p "$BASE_DIR"

# 如已完成首次配置，启动时先执行一次
if [ -f "$CONFIG_FILE" ]; then
  "$MONITOR" >> "$LOG_FILE" 2>&1 || true
else
  echo "⚠️ 未检测到配置文件（首次需手动运行 $MONITOR 完成 IP 设置），监听已启动。" | tee -a "$LOG_FILE"
fi

# 监听系统网络状态（全局 IPv4 状态变化即可反映 Wi-Fi 切换/断连）
/usr/sbin/scutil <<'EOF' | while IFS= read -r line; do
if printf "%s" "$line" | grep -q "changed"; then
  "$HOME/Library/NetworkScripts/monitor_wifi.sh" >> "$HOME/Library/NetworkScripts/monitor_wifi.log" 2>&1 || true
fi
done
open
d.init
d.add State:/Network/Global/IPv4
d.watch
EOF
