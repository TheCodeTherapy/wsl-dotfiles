return {
  "folke/noice.nvim",
  opts = {
    presets = {
      lsp_doc_border = true,
    },
    lsp = {
      hover = {
        enabled = true,
        silent = false,
      },
      signature = {
        opts = {
          size = {
            height = 4,
          },
        },
      },
      documentation = {
        view = "hover",
        opts = {
          lang = "markdown",
          replace = true,
          render = "plain",
          format = { "{message}" },
          win_options = { concealcursor = "n", conceallevel = 3 },
        },
      },
    },
  },
}
