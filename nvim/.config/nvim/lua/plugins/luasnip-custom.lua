return {
  "L3MON4D3/LuaSnip",
  config = function(_, opts)
    -- Run standard setup LuaSnip by LazyVim
    require("luasnip").setup(opts)
    -- Include snippets lua/directoru
    require("luasnip.loaders.from_lua").load({ paths = "./lua/snippets" })
  end,
}
