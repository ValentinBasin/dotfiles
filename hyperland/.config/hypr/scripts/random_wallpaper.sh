#!/bin/bash

DIR="$HOME/Pictures/Wallpapers"
if ! pgrep -x "hyprpaper" >/dev/null; then
  hyprpaper &
  sleep 1
fi
RANDOM_IMG=$(find "$DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1)
if [ -z "$RANDOM_IMG" ]; then
  echo "No wallpapers found in $DIR"
  exit 1
fi
hyprctl hyprpaper preload "$RANDOM_IMG"
hyprctl hyprpaper wallpaper ",$RANDOM_IMG"
hyprctl hyprpaper unload all
