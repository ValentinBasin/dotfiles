#!/bin/bash

# Проверяем количество подключенных мониторов (исключая eDP-1, если он выключен)
# Grep ищем слово "Monitor", считаем количество строк
MONITORS=$(hyprctl monitors | grep "Monitor" | wc -l)

if [ "$1" == "close" ]; then
  # Если крышка закрыта
  if [ $MONITORS -gt 1 ]; then
    # И есть внешние мониторы -> выключаем eDP-1
    hyprctl keyword monitor "eDP-1, disable"
    kanshictl reload
  else
    # Если внешних нет -> ничего не делаем (пусть systemd усыпляет ноут)
    :
  fi
elif [ "$1" == "open" ]; then
  # Если крышка открыта -> всегда включаем eDP-1 обратно
  # ВАЖНО: Укажите здесь тот же scale, что и в kanshi (1.25)
  hyprctl keyword monitor "eDP-1, 1920x1080, 3840x0, 1.25"

  # Заставляем kanshi перечитать конфигурацию, чтобы он раскидал мониторы правильно
  kanshictl reload
fi
