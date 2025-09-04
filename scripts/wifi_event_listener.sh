#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONITOR="$SCRIPT_DIR/monitor_wifi.sh"
BASE_DIR="$HOME/Library/NetworkScripts"
LOG_FILE="$BASE_DIR/monitor_wifi.log"
CONFIG_FILE="$BASE_DIR/user_config.conf"

mkdir -p "$BASE_DIR"

# 启动即尝试跑一次（若未首配则提示）
if [ -f "$CONFIG_FILE" ]; then
  "$MONITOR" >> "$LOG_FILE" 2>&1 || true
else
  echo "⚠️ 未检测到配置文件（首次需手动运行 $MONITOR 完成 IP 设置），监听已启动。" | tee -a "$LOG_FILE"
fi

/usr/sbin/scutil <<'EOF' | while IFS= read -r line; do
if printf "%s" "$line" | grep -q "changed"; then
  "$MONITOR" >> "$HOME/Library/NetworkScripts/monitor_wifi.log" 2>&1 || true
fi
done
open
d.init
d.add State:/Network/Global/IPv4
d.watch
EOF