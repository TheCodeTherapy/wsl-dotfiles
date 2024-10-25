return {
  "RRethy/vim-illuminate",
  config = function()
    require("illuminate").configure({
      -- Custom configuration options
      delay = 100,
      filetypes_denylist = { "NvimTree" },
      under_cursor = false,
    })
  end,
}
