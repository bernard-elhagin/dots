#!/usr/bin/env bash
set -u

if [[ "${1:-}" == updates ]]; then
    if [[ -r "$HOME/.config/waybar/scripts/checkupdates.sh" ]]; then
        bash "$HOME/.config/waybar/scripts/checkupdates.sh" 2>/dev/null || true
    else
        printf '{"text":""}\n'
    fi
    exit 0
fi

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
cpu_idle=$((idle + iowait))

memory="$(awk '/MemTotal/ {total=$2} /MemAvailable/ {available=$2} END {if (total) printf "%d", (total-available)*100/total; else print "--"}' /proc/meminfo)"

temperature="--"
for temp_file in /sys/class/hwmon/hwmon4/temp1_input /sys/class/thermal/thermal_zone0/temp; do
    if [[ -r "$temp_file" ]]; then
        temperature="$(awk '{printf "%.0f°C", $1/1000}' "$temp_file")"
        break
    fi
done

brightness=""
if command -v brightnessctl >/dev/null 2>&1; then
    brightness="$(brightnessctl -m 2>/dev/null | awk -F, 'NR==1 {gsub(/%/, "", $4); print $4}')"
fi

network="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" {sub(/^[^:]*:/, ""); print; exit}')"
if [[ -z "$network" ]]; then
    network="$(nmcli -t -f TYPE,STATE dev status 2>/dev/null | awk -F: '$1 == "ethernet" && $2 == "connected" {print "ETH"; exit}')"
fi
network="${network:-OFF}"

bluetooth="off"
if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
    bluetooth="on"
fi

vpn="off"
if nmcli -t -f TYPE,STATE con show --active 2>/dev/null | grep -q '^vpn:activated$'; then
    vpn="on"
fi

jq -cn \
    --arg network "$network" \
    --arg bluetooth "$bluetooth" \
    --arg vpn "$vpn" \
    --arg memory "$memory" \
    --arg temperature "$temperature" \
    --arg brightness "$brightness" \
    --argjson cpuTotal "$cpu_total" \
    --argjson cpuIdle "$cpu_idle" \
    '{network:$network, bluetooth:$bluetooth, vpn:$vpn, memory:$memory, temperature:$temperature, brightness:$brightness, cpuTotal:$cpuTotal, cpuIdle:$cpuIdle}'
