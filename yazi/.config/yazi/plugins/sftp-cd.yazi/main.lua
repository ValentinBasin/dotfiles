--- Interactive "cd" that is aware of remote filesystems.
---
--- In a remote tab (e.g. sftp://host//home/user) the input is pre-filled
--- with "sftp://host//", so an absolute remote path can be typed right
--- away. In a local tab it falls back to the built-in "cd --interactive".

local get_cwd = ya.sync(function() return tostring(cx.active.current.cwd) end)

return {
	entry = function()
		-- "scheme://domain/" of a remote URL; nil for a local path.
		local root = get_cwd():match("^(%a[%w+.-]*://[^/]*/)")
		if not root then
			return ya.emit("cd", { interactive = true })
		end

		local value, event = ya.input {
			title = "Change directory:",
			value = root .. "/",
			pos = { "top-center", y = 2, w = 50 },
		}
		if event == 1 and value ~= "" then
			ya.emit("cd", { value })
		end
	end,
}
