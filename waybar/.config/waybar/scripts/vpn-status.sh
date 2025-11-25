#!/bin/bash

ACTIVE_VPNS=$(nmcli -t -f TYPE,NAME connection show --active | grep '^vpn:' | cut -d: -f2)

if [ -n "$ACTIVE_VPNS" ]; then
  FORMATTED_LIST=$(echo "$ACTIVE_VPNS" | sed 's/^/🔒 /' | paste -sd ' ' -)

  TOOLTIP="Connected to:\n$ACTIVE_VPNS"

  echo "{\"text\": \"$FORMATTED_LIST\", \"tooltip\": \"$TOOLTIP\", \"class\": \"connected\"}"
else
  echo "{\"text\": \" No VPN\", \"tooltip\": \"Disconnected\", \"class\": \"disconnected\"}"
fi
