#!/bin/bash

ACTIVE_LIST=$(nmcli -t -f TYPE,NAME connection show --active | grep '^vpn:' | cut -d: -f2)

MENU_ITEMS=""
ALL_VPNS=$(nmcli -t -f TYPE,NAME connection show | grep '^vpn:' | cut -d: -f2)

while IFS= read -r vpn_name; do
  if echo "$ACTIVE_LIST" | grep -q "^$vpn_name$"; then
    MENU_ITEMS+="✅ Disconnect: $vpn_name\n"
  else
    MENU_ITEMS+="Connect: $vpn_name\n"
  fi
done <<<"$ALL_VPNS"

CHOICE=$(echo -e "$MENU_ITEMS" | sed '/^$/d' | wofi --dmenu --prompt "VPN Manager" --width 400 --height 300)

if [ -z "$CHOICE" ]; then
  exit 0
fi

VPN_NAME=$(echo "$CHOICE" | cut -d: -f2 | xargs)
ACTION=$(echo "$CHOICE" | awk '{print $1}') # "Connect:" или "✅"

if [ "$ACTION" == "✅" ]; then
  notify-send "VPN" "Disconnecting $VPN_NAME..."
  nmcli connection down "$VPN_NAME"
else
  notify-send "VPN" "Requesting connection to $VPN_NAME..."
  nmcli connection up "$VPN_NAME"
  if [ $? -eq 0 ]; then
    notify-send "VPN" "Successfully connected to $VPN_NAME"
  else
    notify-send -u critical "VPN" "Connection failed"
  fi
fi
# else
#   notify-send "VPN" "Connecting to $VPN_NAME..."
#   kitty --title "VPN Auth" sh -c "nmcli connection up '$VPN_NAME' --ask; sleep 1"
# fi
