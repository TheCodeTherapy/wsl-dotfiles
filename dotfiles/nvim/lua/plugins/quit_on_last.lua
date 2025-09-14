-- lua/plugins/quit-on-snacks-picker.lua
return {
  "nvim-lua/plenary.nvim", -- dummy dep so Lazy loads this
  lazy = false,
  init = function()
    local function only_one_normal_window()
      local count = 0
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "" then
          count = count + 1
        end
      end
      return count == 1
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinClosed" }, {
      group = vim.api.nvim_create_augroup("QuitOnSnacksPicker", { clear = true }),
      callback = function()
        vim.schedule(function()
          if vim.bo.filetype == "snacks_picker_list" and only_one_normal_window() then
            vim.cmd("qa")
          end
        end)
      end,
    })
  end,
}
