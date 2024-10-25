return {
  {
    "ribru17/bamboo.nvim",
    lazy = false,
    name = "bamboo",
    config = function()
      require("bamboo").setup({
        style = "vulgaris",
      })
    end,
  },
}
