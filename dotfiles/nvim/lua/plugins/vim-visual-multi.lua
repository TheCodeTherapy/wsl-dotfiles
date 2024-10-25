return {
  "mg979/vim-visual-multi",
  init = function()
    -- I'm not sure why I need to defer this to the next available
    -- opportunity after startup
    vim.defer_fn(function()
      vim.cmd("VMTheme paper")
    end, 0)
    vim.g.VM_maps = {
      ["Find Under"] = "<C-d>",
    }
    vim.api.nvim_command("hi VM_Mono guibg=Grey60 guifg=Black gui=NONE")
  end,
}
