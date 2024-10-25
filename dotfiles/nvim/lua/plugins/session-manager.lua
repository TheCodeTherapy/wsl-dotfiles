if true then
  return {}
end

return {
  "Shatur/neovim-session-manager",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    local Path = require("plenary.path")
    require("session_manager").setup({
      sessions_dir = Path:new(vim.fn.stdpath("data"), "sessions"), -- Directory where sessions will be saved
      path_replacer = "__", -- Symbol used to replace path separator when saving session files
      colon_replacer = "++", -- Symbol used to replace colon symbol in filenames
      autoload_mode = require("session_manager.config").AutoloadMode.CurrentDir, -- Automatically load session based on the current directory
      autosave_last_session = true, -- Automatically save session when exiting Neovim
    })

    -- Keybinding to save the session and exit with code 1 for reloading
    vim.api.nvim_set_keymap(
      "n",
      "<leader>rr",
      "<cmd>lua require('session_manager').save_current_session()<CR><cmd>lua os.exit(1)<CR>",
      { noremap = true, silent = true }
    )
  end,
}
