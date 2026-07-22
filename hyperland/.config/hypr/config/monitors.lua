hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

local ext_monitors = {
	-- Home
	["AOC 27G15N AH15428Z01155"] = "1920x1080@60.00, 0x0, 1",

	-- Speedata (Primary, position 0x0)
	["Dell Inc. DELL S2421HGF JWJY973"] = "1920x1080@60.00, 0x0, 1",
	["Dell Inc. DELL S2421HGF 4TKY973"] = "1920x1080@60.00, 0x0, 1",
	["Dell Inc. DELL S2421HGF 35MY973"] = "1920x1080@60.00, 0x0, 1",
	["Dell Inc. DELL P2419H 4X7CR64"] = "1920x1080@60.00, 0x0, 1",
	["Dell Inc. DELL S2722DC J6KQGD3"] = "2560x1440@59.95, 0x0, 1", -- DevOps 1

	-- Speedata (Secondary, position 1920x0 or 2560x0)
	["Dell Inc. DELL S2421HGF 6CLY973"] = "1920x1080@60.00, 1920x0, 1",
	["Dell Inc. DELL S2421HGF 7DKY973"] = "1920x1080@60.00, 1920x0, 1",
	["Dell Inc. DELL S2421HGF JGKY973"] = "1920x1080@60.00, 1920x0, 1",
	["Dell Inc. DELL S2421HGF 6PKY973"] = "1920x1080@60.00, 1920x0, 1",
	["Dell Inc. DELL S2721QS 57GDM43"] = "1920x1080@60.00, 2560x0, 1", -- DevOps 2

	-- Sequans (Primary, position 0x0)
	["Dell Inc. DELL U2415 7MT0167P0LPS"] = "1920x1080@60.00, 0x0, 1",
	["Dell Inc. DELL U2520D BRYV823"] = "2560x1440@59.95, 0x0, 1",

	-- Sequans (Secondary)
	["Dell Inc. DELL U2415 XKV0P05N0IGU"] = "1920x1080@60.00, 1920x0, 1",
	["Dell Inc. DELL U2520D CS8K923"] = "1920x1080@60.00, 2560x0, 1",
}

for desc, config in pairs(ext_monitors) do
	local rule = string.format("desc:%s, %s", desc, config)
	-- os.execute("hyprctl keyword monitor '" .. rule .. "'")
end
