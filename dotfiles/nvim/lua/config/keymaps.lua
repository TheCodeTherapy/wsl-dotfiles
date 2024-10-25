-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

require("thecodetherapy.goto")

local keymap = vim.keymap
local opts = { noremap = true, silent = true }
local surround_chars = "[\"'(){}%[%]]"

local function jump_right_on_surroundings()
  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
  local line_num, col = cursor_pos[1], cursor_pos[2] + 1
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  for l = line_num, total_lines do
    local line_text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1]
    local start_index = l == line_num and col or 1
    local found_at_line_end = false
    for i = start_index, #line_text do
      if string.match(line_text:sub(i, i), surround_chars) then
        if i == #line_text then
          found_at_line_end = true
          break
        else
          vim.api.nvim_win_set_cursor(winnr, { l, i })
          return
        end
      end
    end

    if found_at_line_end then
      if l < total_lines then
        line_num = l + 1
        col = 1
      else
        return
      end
    else
      if l < total_lines then
        line_num = l + 1
        col = 1
      end
    end
  end
end

local function jump_left_on_surroundings()
  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
  local line_num, col = cursor_pos[1], cursor_pos[2]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_num, false)

  for ln = #lines, 1, -1 do
    local line_text = lines[ln]
    local end_col = ln == line_num and col or #line_text
    for i = end_col, 1, -1 do
      local char = line_text:sub(i, i)
      if string.match(char, surround_chars) then
        vim.api.nvim_win_set_cursor(winnr, { ln, i - 2 })
        return
      end
    end
  end
end

local function copy_diagnostics_to_clipboard()
  local diagnostics = vim.diagnostic.get(0)
  local lines = {}
  for _, diag in ipairs(diagnostics) do
    table.insert(lines, diag.message)
  end
  local text = table.concat(lines, "\n")
  vim.fn.setreg("+", text)
  print("Diagnostics copied to clipboard!")
end

local function copy_file_and_diagnostics_to_clipboard()
  local file_path = vim.fn.expand("%")
  local relative_file_path = vim.fn.fnamemodify(file_path, ":~:.")
  local file_extension = vim.fn.fnamemodify(file_path, ":e")
  local markdown_code_block_identifier = file_extension
  local extension_to_markdown = {
    ts = "typescript",
    js = "javascript",
    py = "python",
  }
  if extension_to_markdown[file_extension] then
    markdown_code_block_identifier = extension_to_markdown[file_extension]
  end
  local file_content = table.concat(vim.fn.readfile(file_path), "\n")
  local diagnostics = vim.diagnostic.get(0)
  local diagnostic_lines = {}
  for _, diag in ipairs(diagnostics) do
    local line_content = vim.fn.getline(diag.lnum + 1)
    table.insert(
      diagnostic_lines,
      string.format("\n\n>- Line %d: `%s`\n>- Diagnostic: %s\n", diag.lnum + 1, line_content, diag.message)
    )
  end
  local diagnostics_text = table.concat(diagnostic_lines, "\n\n")
  local clipboard_text = string.format(
    "File: %s\n\n```%s\n%s\n```\n\nDiagnostics:\n%s",
    relative_file_path,
    markdown_code_block_identifier,
    file_content,
    diagnostics_text
  )
  vim.fn.setreg("+", clipboard_text)
  print("File and diagnostics copied to clipboard!")
end

local function create_and_preview_diagnostics()
  copy_file_and_diagnostics_to_clipboard()
  local diagnostics_file_path = vim.fn.getcwd() .. "/diagnostics.md"
  vim.cmd("e " .. diagnostics_file_path)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  vim.cmd("write")
  vim.cmd("MarkdownPreview")
end

keymap.set("n", "<leader>ccm", create_and_preview_diagnostics, opts)
keymap.set("n", "<leader>cca", copy_file_and_diagnostics_to_clipboard, opts)
keymap.set("n", "<leader>cc", copy_diagnostics_to_clipboard, opts)

keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
keymap.set("n", "dw", "vb_d")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Move lines around
keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)
keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)

-- New tab
keymap.set("n", "te", "tabedit", opts)
-- keymap.set("n", "<tab>", ":tabnext<Return>", opts)
-- keymap.set("n", "<s-tab>", ":tabprev", opts)

-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- Morse surroundings
keymap.set({ "n", "i", "v" }, ",,,", jump_left_on_surroundings, opts)
keymap.set({ "n", "i", "v" }, ",,", jump_right_on_surroundings, opts)

-- Move around
keymap.set("n", "<leader><Left>", "<C-w>h")
keymap.set("n", "<leader><Right>", "<C-w>l")
keymap.set("n", "<leader><Up>", "<C-w>k")
keymap.set("n", "<leader><Down>", "<C-w>j")
keymap.set("n", "<A-Right>", ":BufferLineCycleNext<CR>", opts)
keymap.set("n", "<A-Left>", ":BufferLineCyclePrev<CR>", opts)
keymap.set("n", "<S-A-Right>", ":BufferLineMoveNext<CR>", opts)
keymap.set("n", "<S-A-Left>", ":BufferLineMovePrev<CR>", opts)

-- Resize
keymap.set("n", "<C-w><Left>", "<C-w><")
keymap.set("n", "<C-w><Right>", "<C-w>>")

-- Disable default macro record
keymap.set("n", "q", "<Nop>", opts)

-- Normie emulation ==========================================================
keymap.set("n", "<S-End>", "v$")
keymap.set("v", "<S-End>", "g_", opts)
keymap.set("i", "<S-End>", "<Esc>v$", opts)

keymap.set("n", "<S-Home>", "v0")
keymap.set("v", "<S-Home>", "0", opts)
keymap.set("i", "<S-Home>", "<Esc>v0", opts)

keymap.set("v", "<C-c>", '"+y', opts)
keymap.set("n", "<C-v>", '"+p', opts)
keymap.set("i", "<C-v>", "<C-r>+", { noremap = true })

-- moving lines up and down with Alt + keys in normal mode or insert mode
keymap.set("n", "<A-Up>", ":m .-2<CR>==", opts)
keymap.set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", opts)
keymap.set("n", "<A-Down>", ":m .+1<CR>==", opts)
keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", opts)

-- making shift + down and shift + up select lines
keymap.set("n", "<S-Down>", "v<Down>", opts)
keymap.set("v", "<S-Down>", "j", opts)
keymap.set("n", "<S-Up>", "v<Up>", opts)
keymap.set("v", "<S-Up>", "k", opts)

-- tab or shift+tab on normal mode to indent right or left the current line
keymap.set("n", "<Tab>", ">>")
keymap.set("n", "<S-Tab>", "<<")
-- on insert mode, tab or shift+tab will indent right or left the current line
keymap.set("i", "<Tab>", "<C-t>")
keymap.set("i", "<S-Tab>", "<C-d>")
-- on visual mode, tab or shift+tab will indent right or left the selected lines
keymap.set("v", "<Tab>", ">gv")
keymap.set("v", "<S-Tab>", "<gv")

-- on visual mode, Ctrl + f should search the word under the cursor in the current buffer
vim.keymap.set("n", "<C-f>", function()
  require("telescope.builtin").grep_string({
    search = vim.fn.expand("<cword>"),
    use_regex = false,
  })
end, opts)
-- on insert mode, Ctrl + f should search the word under the cursor in the current buffer
vim.keymap.set("i", "<C-f>", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("stopinsert")
  require("telescope.builtin").grep_string({
    search = word,
    use_regex = false,
  })
end, opts)

-- On normal mode, Ctrl + g searches the word under the cursor in the entire project
vim.keymap.set("n", "<C-g>", function()
  require("telescope.builtin").live_grep({
    default_text = vim.fn.expand("<cword>"),
  })
end, opts)

-- On insert mode, Ctrl + g searches the word under the cursor in the entire project
vim.keymap.set("i", "<C-g>", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("stopinsert")
  require("telescope.builtin").live_grep({
    default_text = word,
  })
end, opts)
-- ===========================================================================

vim.api.nvim_set_keymap("n", "gg", "<cmd>lua require('thecodetherapy.goto').go_to_implementation()<CR>", opts)

-- this bindkey is not set in plugins/session-manager.lua
vim.api.nvim_set_keymap("n", "<leader>rr", "<cmd>lua os.exit(1)<CR>", opts)

-- sets up <leader>n to trigger <leader>snt in normal mode
keymap.set("n", "<leader>n", ":NoicePick<CR>", opts)
keymap.set("n", "<leader>p", ":Telescope neovim-project discover<CR>", opts)
