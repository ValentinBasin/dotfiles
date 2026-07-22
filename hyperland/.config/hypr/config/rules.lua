local app_workspaces = {
	["^(com.mitchellh.ghostty)$"] = "1",
	["^(kitty)$"] = "1",
	["^(google-chrome)$"] = "2",
	["^(firefox)$"] = "3",
	["^(obsidian)$"] = "9",
	["^(org.telegram.desktop)$"] = "10",
	["^(Bitwarden)$"] = "special:magic",
	["^(org.keepassxc.KeePassXC)$"] = "special:magic",
}

for class_regex, ws in pairs(app_workspaces) do
	hl.window_rule({
		match = {
			class = class_regex,
		},
		workspace = ws,
	})
end

-- ==========================================
-- GOOGLE MEET COMPANION / POP-OUT
-- ==========================================
local meet_w = 400
local meet_h = 400
local meet_pad = 20

local meet_move_pos = string.format("monitor_w-%d monitor_h-%d", meet_w + meet_pad, meet_h + meet_pad)

hl.window_rule({
	match = {
		class = "^(google-chrome)$",
		title = "^(Meet - .*)$",
		initial_title = "^(Meet - .*)$",
	},
	float = true,
	size = string.format("%d %d", meet_w, meet_h),
	move = meet_move_pos,
	pin = true,
	no_initial_focus = true,
	tag = "+meet",
})

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})
