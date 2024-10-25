return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    name = "cyberdream",
    config = function()
      require("bamboo").setup({
        theme = {
          variant = "default",
        },
      })
    end,
  },
}
