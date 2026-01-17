#!/bin/bash

# Count of the conected monitors
MONITORS=$(hyprctl monitors | grep "Monitor" | wc -l)

if [ "$1" == "close" ]; then
  if [ $MONITORS -gt 1 ]; then
    hyprctl keyword monitor "eDP-1, disable"
  else
    :
  fi
elif [ "$1" == "open" ]; then
  if [ $MONITORS -gt 1 ]; then
    hyprctl keyword monitor "eDP-1, 1920x1080, 3840x0, 1.25"
  else
    hyprctl keyword monitor "eDP-1, 1920x1080, 0x0, 1.25"
  fi
fi
