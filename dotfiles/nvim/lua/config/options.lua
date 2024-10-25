-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.winbar = "%=%m %f"

vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

vim.cmd([[
  hi illuminatedWord guibg=#424270 gui=none
  hi illuminatedCurWord guibg=#424270 gui=none
  let g:go_highlight_operators = 1
  let g:go_highlight_functions = 1
  let g:go_highlight_function_calls = 1
  let g:go_highlight_build_constraints = 1
  let g:go_highlight_generate_tags = 1
  highlight goFunctionCall guifg=#88C0D0
  highlight goFormatSpecifier guifg=#FFAA8B
  highlight goEscapeOctal guifg=#EBCB8B
  highlight goEscapeC guifg=#EBCB8B
  highlight goEscapeX guifg=#EBCB8B
  highlight goEscapeU guifg=#EBCB8B
  highlight goEscapeBigU guifg=#EBCB8B
  highlight goEscapeError guifg=#EBCB8B
]])

vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = "rounded",
    source = true,
    update_in_insert = "true",
  },
})
