-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

vim.cmd([[
  autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight NormalFloat guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight SignColumn guibg=NONE ctermbg=NONE
]])

vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalFloat guibg=NONE ctermbg=NONE
  highlight SignColumn guibg=NONE ctermbg=NONE
]])

-- function CenterCursor()
--   local pos = vim.api.nvim_win_get_cursor(0) -- Get the current cursor position
--   vim.cmd("normal! zz") -- Center the cursor
--   vim.api.nvim_win_set_cursor(0, pos) -- Restore the exact cursor position
-- end
--
-- vim.api.nvim_create_autocmd("CursorMoved", {
--   callback = CenterCursor,
-- })
