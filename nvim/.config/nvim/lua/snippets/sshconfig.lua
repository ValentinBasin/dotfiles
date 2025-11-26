local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local events = require("luasnip.util.events")

return {
  s({
    trig = "host",
    dscr = "Add new SSH host block",
  }, {
    t({ "", "Host " }),
    i(1, "my-server"),
    t({ "", "\tHostName " }),
    i(2, "1.2.3.4"),
    t({ "", "\tUser " }),
    i(3, "root"),
    t({ "", "\tIdentityFile ~/.ssh/" }),
    i(4, "id_ed25519"),
    t({ "", "" }),
    i(0),
  }, {
    callbacks = {
      [-1] = {
        [events.pre_expand] = function()
          local r = vim.api.nvim_win_get_cursor(0)[1] - 1
          local line = vim.api.nvim_buf_get_lines(0, r, r + 1, false)[1]
          local indent = string.match(line, "^%s*")
          if indent and #indent > 0 then
            vim.api.nvim_buf_set_text(0, r, 0, r, #indent, {})
          end
        end,
      },
    },
  }),
}
