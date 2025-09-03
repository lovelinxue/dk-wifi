\- `wifi_event_listener.sh` 使用 `scutil` 实时监听网络状态变化（近乎即时），触发

\- `monitor_wifi.sh` 会判断当前 SSID：是 `Daikin_Staff` → 设置静态网络；否则 → 恢复 DHCP 并清理 DNS/搜索域

\- 首次需要你**手动运行一次** `monitor_wifi.sh` 输入内网 IP（**不是 192 开头**）