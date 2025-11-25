return {
  "linux-cultist/venv-selector.nvim",
  dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
  opts = {
    name = "venv",
    auto_refresh = true,
  },
  keys = {
    { ",v", "<cmd>VenvSelect<cr>" },
  },
  require("venv-selector").setup({
    poetry_path = "/Users/basin/Library/Caches/pypoetry/virtualenvs",
  }),
}
