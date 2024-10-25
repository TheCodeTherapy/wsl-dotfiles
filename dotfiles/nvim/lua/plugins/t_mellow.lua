return {
  {
    "mellow-theme/mellow.nvim",
    lazy = false,
    name = "mellow",
    config = function()
      vim.g.mellow_italic_functions = true
      vim.g.mellow_bold_functions = true
    end,
  },
}
