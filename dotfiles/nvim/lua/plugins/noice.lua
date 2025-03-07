return {
  "folke/noice.nvim",
  opts = {
    presets = {
      lsp_doc_border = true,
    },
    views = {
      hover = {
        win_options = {
          winhighlight = {
            Normal = "NoicePopup",
            FloatBorder = "NoicePopup",
            CursorLine = "NoicePopup",
            PmenuMatch = "NoicePopup",
          },
        },
      },
    },
  },
}
