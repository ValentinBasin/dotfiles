#!/bin/sh
# Этот shebang тут для редакторов кода, чтобы они включали подсветку.
# При source он игнорируется.

s() {
  # Объявляем переменные локально, чтобы не засорять глобальное окружение
  local selection host

  # Логика та же, синтаксис строгий
  # Используем printf вместо echo внутри awk для надежности
  selection=$(awk -v RS="" '
    {
       if (match($0, /Host[[:space:]]+([^[:space:]]+)/)) {
           # RSTART и RLENGTH - стандартные переменные awk для match
           # Но substr работает надежнее в разных версиях awk
           
           # Простой парсинг без сложных массивов awk, чтобы работать даже на старых mawk/gawk
           host_name=$2; 

           if (host_name == "*") next;

           icon=" ";
           # Ищем строку с иконкой
           if ($0 ~ /#[[:space:]]*Icon:/) {
               # Выдергиваем иконку (грубо, но надежно через sed для portable-решения)
               # Передаем строку в pipe внутри awk (специфично, лучше сделаем проще)
           }
           
           # Упростим: если Bash/Zsh - логика должна быть максимально простой.
           # Давайте вернемся к grep/sed пайплайну, он самый универсальный.
       }
    }' 2>/dev/null)

  # Вернемся к варианту на grep/sed, так как awk implementation (gawk vs mawk vs nawk)
  # может отличаться на разных unix-системах сильнее, чем bash/zsh.

  # ПОЛНОСТЬЮ УНИВЕРСАЛЬНЫЙ ВАРИАНТ (BASH + ZSH + ЛЮБОЙ AWK):

  selection=$(grep -r "^Host " ~/.ssh/config ~/.ssh/conf.d/ 2>/dev/null | grep -v "\*" |
    sed -E 's/.*:Host[[:space:]]+(.*)/\1/' | sort -u |
    fzf --height=40% --layout=reverse --border --prompt="SSH > " \
      --preview 'ssh -G {} | grep -E -i "^(hostname|user|port|identityfile)"')

  if [ -n "$selection" ]; then
    # Проверка на наличие функции установки заголовка
    # printf работает везде одинаково
    printf "\033]0;SSH: %s\007" "$selection"

    echo "Connecting to $selection..."
    ssh "$selection"
  fi
}
