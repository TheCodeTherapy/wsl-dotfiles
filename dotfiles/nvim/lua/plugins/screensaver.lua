do
  return {}
end

return {
  "nvim-lua/plenary.nvim",
  config = function()
    require("config.screensaver").setup()
  end,
}
