local v = require("config.vars")

local autostart_cmds = {
	v.scripts .. "random_wallpaper.sh",
	"waybar",
	"kanshi",
	"swaync",
	"nm-applet --indicator",
	"blueman-applet",
	"hp-systray",
	"dropbox",
	"hypridle",
	"bash -c 'sleep 5 && syncthingtray'",
	"wl-paste --type text --watch cliphist store",
	"wl-paste --type image --watch cliphist store",
	"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
	"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
	"systemctl --user start hyprland-session.target",
	-- "bash -c 'sleep 2 && killall -9 xdg-desktop-portal-hyprland xdg-desktop-portal; systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal'",
}

hl.on("hyprland.start", function()
	for _, cmd in ipairs(autostart_cmds) do
		hl.exec_cmd(cmd)
	end
end)
