#!/usr/bin/env bash
set -euo pipefail

THEME="$HOME/.config/rofi/vpn.rasi"

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -a "VPN" -u normal "$1" "${2:-}"
}

vpn_is_really_up() {
  local name="$1"
  local state ip4 ip6

  state="$(nmcli -g GENERAL.STATE con show "$name" 2>/dev/null || true)"
  [[ "$state" == "activated" ]] || return 1

  ip4="$(nmcli -g IP4.ADDRESS con show "$name" 2>/dev/null || true)"
  ip6="$(nmcli -g IP6.ADDRESS con show "$name" 2>/dev/null || true)"

  [[ -n "${ip4}${ip6}" ]]
}

wait_for_vpn() {
  local name="$1"
  local timeout="${2:-8}"
  local i

  for ((i=0; i<timeout; i++)); do
    if vpn_is_really_up "$name"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

mapfile -t VPN_LIST < <(nmcli -t -f NAME,TYPE con show | awk -F: '$2=="vpn"{print $1}')

ACTIVE_VPN="$(
  nmcli -t -f NAME,TYPE,STATE con show --active 2>/dev/null \
  | awk -F: '$2=="vpn" && $3=="activated"{print $1}' \
  | head -n1 || true
)"

HEADER="󰌷 Active VPN: ${ACTIVE_VPN:-None}"

MENU=""
if [[ -n "${ACTIVE_VPN:-}" ]]; then
  MENU+="✖ Disconnect active VPN\n"
fi

if ((${#VPN_LIST[@]})); then
  for vpn in "${VPN_LIST[@]}"; do
    if [[ "$vpn" == "$ACTIVE_VPN" ]]; then
      MENU+=" $vpn (Connected)\n"
    else
      MENU+=" $vpn\n"
    fi
  done
else
  MENU+="(No VPN connections found in NetworkManager)\n"
fi

CHOICE="$(printf "%b" "$MENU" | rofi -dmenu -theme "$THEME" -p "$HEADER" -hover-select)"
[[ -z "${CHOICE:-}" ]] && exit 0

case "$CHOICE" in
  "✖ Disconnect active VPN")
    if [[ -n "${ACTIVE_VPN:-}" ]]; then
      if nmcli -w 10 con down "$ACTIVE_VPN"; then
        notify "VPN disconnected" "$ACTIVE_VPN"
      else
        notify "VPN disconnect failed" "$ACTIVE_VPN"
      fi
    fi
    ;;
  \ *)
    VPN_NAME="${CHOICE#* }"
    VPN_NAME="${VPN_NAME% (Connected)}"   # strip suffix if present

   if nmcli -w 20 con up id "$VPN_NAME"; then
  # give NM a moment and verify it's actually activated
  sleep 1
  state="$(nmcli -g GENERAL.STATE con show id "$VPN_NAME" 2>/dev/null || true)"
  if [[ "$state" == "activated" ]]; then
    notify "VPN connected" "$VPN_NAME"
  else
    nmcli -w 10 con down id "$VPN_NAME" >/dev/null 2>&1 || true
    notify "VPN connect failed" "$VPN_NAME"
  fi
else
  notify "VPN connect failed" "$VPN_NAME"
fi

    ;;
  *)
    ;;
esac

