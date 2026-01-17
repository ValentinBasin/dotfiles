#!/bin/bash

if grep -q "open" /proc/acpi/button/lid/*/state; then

  MONITORS=$(hyprctl monitors all | grep "Monitor" | wc -l)

  if [ $MONITORS -gt 1 ]; then
    hyprctl keyword monitor "eDP-1, 1920x1080, 3840x0, 1.25"
  else
    hyprctl keyword monitor "eDP-1, 1920x1080, 0x0, 1.25"
  fi

else
  :
fi
