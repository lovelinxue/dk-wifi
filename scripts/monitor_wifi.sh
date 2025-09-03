
#!/bin/bash
set -e

# ── 自动识别 Wi-Fi 网卡设备 & 网络服务名 ──
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2; exit}')
if [ -z "$WIFI_DEVICE" ]; then
  echo "❌ 未找到 Wi-Fi 网卡，请确认已启用 Wi-Fi。"
  exit 1
fi

# 从“网络服务顺序”中，反查对应 device 的服务名（通常是 Wi-Fi，但保证更稳）
WIFI_SERVICE=$(networksetup -listnetworkserviceorder | \
  awk -v dev="$WIFI_DEVICE" '
    /^\([0-9]+\) /{svc=$0; sub(/^\([0-9]+\) /,"",svc)}
    $0 ~ "Device: "dev {print svc; exit}
  ')
if [ -z "$WIFI_SERVICE" ]; then
  # 回退：大多数系统服务名就是 Wi-Fi
  WIFI_SERVICE="Wi-Fi"
fi

TARGET_WIFI="Daikin_Staff"
BASE_DIR="$HOME/Library/NetworkScripts"
CONFIG_FILE="$BASE_DIR/user_config.conf"
LOG_FILE="$BASE_DIR/monitor_wifi.log"

mkdir -p "$BASE_DIR"

# —— 固定网络参数（按你的要求） ——
SUBNET="255.255.255.0"
ROUTER="172.31.79.253"
DNS_SERVERS="192.168.192.245 10.192.255.2"
SEARCH_DOMAIN="daikin.net.cn"

# —— 获取当前 SSID ——
RAW_SSID="$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null || true)"
if [[ "$RAW_SSID" == "You are not associated with an AirPort network."* ]]; then
  SSID=""
else
  SSID="${RAW_SSID#Current Wi-Fi Network: }"
fi

# —— 首次运行：需要交互输入 IP（但若从后台监听调用且无 TTY，就提示并退出） ——
if [ ! -f "$CONFIG_FILE" ]; then
  if [ -t 0 ]; then
    echo "请输入你的内网IP地址：不是192开头的"
    read -r USER_IP

    # 简单校验：不是 192.*，且是 IPv4 形态
    while true; do
      if [[ ! "$USER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "格式不正确，请重新输入（例如 172.*.*.*）："
        read -r USER_IP
        continue
      fi
      if [[ "$USER_IP" =~ ^192\. ]]; then
        echo "不能以 192 开头，请重新输入："
        read -r USER_IP
        continue
      fi
      break
    done

    echo "IP=$USER_IP" > "$CONFIG_FILE"
    echo "✅ 已保存配置：$CONFIG_FILE"
  else
    echo "⚠️ 检测到首次运行且缺少配置，请手动执行一次：$BASE_DIR/monitor_wifi.sh" | tee -a "$LOG_FILE"
    exit 0
  fi
fi

# 读取配置
# shellcheck disable=SC1090
source "$CONFIG_FILE"

# —— 按 SSID 切换网络配置 ——
{
  if [ "$SSID" = "$TARGET_WIFI" ]; then
    echo "✅ 连接到 $TARGET_WIFI，应用静态网络配置：IP=$IP, MASK=$SUBNET, GW=$ROUTER"
    networksetup -setmanual "$WIFI_SERVICE" "$IP" "$SUBNET" "$ROUTER"
    networksetup -setdnsservers "$WIFI_SERVICE" $DNS_SERVERS
    networksetup -setsearchdomains "$WIFI_SERVICE" "$SEARCH_DOMAIN"
  else
    echo "ℹ️ 当前 SSID='$SSID'（非 $TARGET_WIFI），恢复 DHCP 并清空 DNS/搜索域"
    networksetup -setdhcp "$WIFI_SERVICE"
    networksetup -setdnsservers "$WIFI_SERVICE" empty
    networksetup -setsearchdomains "$WIFI_SERVICE" empty
  fi
} | tee -a "$LOG_FILE"
