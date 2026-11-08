#!/usr/bin/env bash
set -euo pipefail

#Requires: NetworkManager and rofi

ROFI_THEME="$HOME/.config/rofi/networkmenu.rasi" 
ROFI_CMD=(rofi -dmenu -i -markup-rows -no-custom -hover-select -theme-str 'inputbar {enabled: false; }')
ROFI_PASS_CMD=(rofi -dmenu -password -no-custom i -hover-select \
  -p "" \
  -theme "$ROFI_THEME")

if [[ -n "$ROFI_THEME" ]]; then
  ROFI_CMD+=( -theme "$ROFI_THEME" )
fi

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Wi-Fi" "$1"
  else
    echo "$1" >&2
  fi
}
#Pick the wifi interface 
WIFI_DEV="$(nmcli -t -f DEVICE,TYPE dev status | awk -F: '$2=="wifi"{print $1; exit}')"
if [[ -z "${WIFI_DEV:-}" ]]; then
  notify "No Wi-Fi device found."
  exit 1
fi

#Ensure wifi is enabled
WIFI_STATE="$(nmcli -t -f WIFI g)"
if [[ "$WIFI_STATE" != "enabled" ]]; then
  notify "Wi-Fi is disabled. Enabling…"
  nmcli r wifi on || true
fi

#Current SSID (if connected)
CURRENT_SSID="$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes"{print $2; exit}')"
if [[ -z "${CURRENT_SSID:-}" ]]; then
  CURRENT_SSID="Not connected"
fi

#Current IP address
IP_ADDR="$(nmcli -g IP4.ADDRESS dev show "$WIFI_DEV" | head -n1 | cut -d/ -f1)"
#fallback
if [[ -z "$IP_ADDR" ]]; then
  IP_ADDR="No IP"
fi

HEADER=$'<b>'"${CURRENT_SSID}"$'</b>\n<span size="smaller" alpha="70%">'"${IP_ADDR}"$'</span>'

mapfile -t LINES < <(
  nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list --rescan auto ifname "$WIFI_DEV" \
  | awk -F: 'NF>=3 && $1!="" {print $1 "\t" $2 "\t" $3}' \
  | awk '!seen[$1]++' \
  | sort -t$'\t' -k3,3nr
)

if (( ${#LINES[@]} == 0 )); then
  notify "No networks found."
  exit 0
fi

MENU_ITEMS=()
SSID_ITEMS=()
SEC_ITEMS=()

for line in "${LINES[@]}"; do
  ssid="${line%%$'\t'*}"
  rest="${line#*$'\t'}"
  sec="${rest%%$'\t'*}"
  sig="${rest#*$'\t'}"

  if [[ -z "$sec" || "$sec" == "--" ]]; then
    icon='<span rise="2000"></span>'  
    sec_label="Open"
  else
    icon='<span rise="2000"></span>'  
    sec_label="Secured"
  fi

  MENU_ITEMS+=( "${icon}  ${ssid}  <span alpha=\"70%\">(${sec_label}, ${sig}%)</span>" )
  SSID_ITEMS+=( "$ssid" )
  SEC_ITEMS+=( "$sec" )
done

CHOICE_IDX="$(
  printf '%s\n' "${MENU_ITEMS[@]}" \
  | rofi -dmenu -i -markup-rows -no-custom \
      -p "$HEADER" \
      -theme "$ROFI_THEME" \
      -theme-str 'inputbar { enabled: false; }' \
      -hover-select \
      -format 'i'
)"

[[ -z "${CHOICE_IDX:-}" ]] && exit 0

SSID_RAW="${SSID_ITEMS[$CHOICE_IDX]}"
SECURITY_RAW="${SEC_ITEMS[$CHOICE_IDX]}"


#If user selected the current SSID, ask to disconnect
if [[ "$CURRENT_SSID" != "(not connected)" && "$SSID_RAW" == "$CURRENT_SSID" ]]; then
  CONF="$(printf "Disconnect\nCancel\n" | rofi -dmenu  \
	  -p "$CURRENT_SSID" \
	  -theme "$ROFI_THEME" \
	  -theme-str 'inputbar {enabled: false; }' \
	  -hover-select)"
  [[ "$CONF" == "Disconnect" ]] || exit 0
  nmcli dev disconnect "$WIFI_DEV"
  notify-send "Wi-Fi" "Disconnected from $CURRENT_SSID"
  exit 0
fi

#Figure out if chosen SSID is secured
SECURITY="$(nmcli -t -f SSID,SECURITY dev wifi list ifname "$WIFI_DEV" | awk -F: -v s="$SSID_RAW" '$1==s{print $2; exit}')"

if [[ -z "${SECURITY_RAW:-}" || "$SECURITY_RAW" == "--" ]]; then
  notify "Connecting to open network: $ssid"
  nmcli dev wifi connect "$SSID_RAW" ifname "$WIFI_DEV" && notify "Connected to $SSID_RAW" || notify "Failed to connect to $SSID_RAW"
  exit 0
fi

#Prompt for password
ROFI_THEME_ARGS=()
if [[ -n "${ROFI_THEME:-}" ]]; then
  ROFI_THEME_ARGS=(-theme "$ROFI_THEME")
fi

PASS="$(
  rofi -dmenu -password \
    -p "$SSID_RAW's Password:" \
    "${ROFI_THEME_ARGS[@]}" \
    -theme-str 'inputbar { children: [  entry ]; }'
    <<< ""
)"

#Get rid of whitespace
PASS="$(printf '%s' "$PASS" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [[ -z "${PASS:-}" ]]; then
  #notify "Incorrect Password or Error."
  exit 0
fi

#Delete an old profile for this SSID if it exist first (fixes connection issues sometimes)
if nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="802-11-wireless"{print $1}' | grep -Fxq "$SSID_RAW"; then
  nmcli connection delete id "$SSID_RAW" >/dev/null 2>&1 || true
fi

notify "Connecting to: $SSID_RAW"
if nmcli dev wifi connect "$SSID_RAW" password "$PASS" ifname "$WIFI_DEV"; then
  notify "Connected to $SSID_RAW"
else
  notify "Failed to connect to $SSID_RAW"
  exit 1
fi

