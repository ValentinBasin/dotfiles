function sss() {
  local color_cat="\033[34m"
  local color_rst="\033[0m"

  local selection=$(grep -r "^Host " ~/.ssh/conf.d/ 2>/dev/null | grep -v "\*" |
    sed -E 's/.*conf\.d\/([^:]+):Host[[:space:]]+(.*)/\1 \2/' |
    awk -v c="$color_cat" -v r="$color_rst" '{printf c "[%-8s]" r " %s\n", $1, $2}' |
    fzf --ansi \
      --height=40% \
      --layout=reverse \
      --border \
      --prompt="SSH > " \
      --preview-window=right:40% \
      --preview 'command ssh -G {-1} 2>/dev/null | grep -E -i "^(hostname|user|port|identityfile)"')

  local host=$(echo "$selection" | awk '{print $NF}')

  if [ -n "$host" ]; then
    if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
      echo -ne "\033]0;SSH: $host\007"
    fi

    echo "Connecting to $host..."
    ssh "$host"
  fi
}
