return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                library = {
                  vim.fn.expand("~/.config/hypr/types"),
                },
              },
              diagnostics = {
                globals = { "hl" },
              },
            },
          },
        },
      },
    },
  },
}
