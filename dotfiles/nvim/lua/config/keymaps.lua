local keymap = vim.keymap
local opts = { noremap = true, silent = true }
---@diagnostic disable-next-line: unused-local
local surround_chars = "[\"'(){}%[%]]"

local function merge_tables(t1, t2)
  local result = {}
  for k, v in pairs(t1) do
    result[k] = v
  end
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
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

local function change_project_root()
  vim.ui.input({ prompt = "Enter new project root: ", completion = "dir" }, function(new_root)
    if new_root and new_root ~= "" then
      new_root = vim.fn.fnamemodify(new_root, ":p") -- Get absolute path
      if vim.fn.isdirectory(new_root) == 1 then
        -- Try closing all buffers (without force), gracefully handle cancellation
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            ---@diagnostic disable-next-line: unused-local
            local ok, _err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
            if not ok then
              print("Buffer closing canceled. Stopping project switch.")
              return -- **Gracefully exit if user cancels**
            end
          end
        end

        -- Close Neo-tree if it is open
        if pcall(require, "neo-tree.command") then
          require("neo-tree.command").execute({ action = "close" })
        end

        -- Change Neovim working directory
        vim.cmd("cd " .. new_root)

        -- Re-open Neo-tree with the new root
        if pcall(require, "neo-tree.command") then
          require("neo-tree.command").execute({ action = "focus", dir = new_root })
        end

        -- Unfocus Neo-tree and return to the main window
        vim.cmd("wincmd p")

        vim.cmd("Alpha")

        -- Notify user
        print("Project root changed to: " .. new_root)
      else
        print("Invalid directory: " .. new_root)
      end
    end
  end)
end

vim.keymap.set(
  "n",
  "<leader>jp",
  change_project_root,
  { noremap = true, silent = true, desc = "Jump to new project root" }
)

keymap.set("n", "<leader>#", "#N", opts)
keymap.set("t", "<S-Space>", "<Space>", opts)

keymap.set("i", "<S-Del>", "<Space><Esc>vwhdi", opts)
keymap.set("n", "<S-Del>", "a<Space><Esc>vwhdi", opts)

-- Move lines around
keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)
keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)

-- New tab
keymap.set("n", "te", "tabedit", opts)

-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

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

-- VSCode like keybindings ---------------------------------------------------
-- Save with Ctrl + s getting back to insert mode
keymap.set("i", "<C-s>", "<Esc>:w<CR>a", opts)
keymap.set("n", "<C-b>", ":Neotree toggle<CR>", opts)
keymap.set("i", "<C-b>", "<Esc>:Neotree toggle<CR>", opts)

-- select stuff with shift + keys
keymap.set("n", "<S-End>", "v$h")
keymap.set("v", "<S-End>", "g_", opts)
keymap.set("i", "<S-End>", "<Esc>v$h", opts)
keymap.set("n", "<S-Home>", "v0")
keymap.set("v", "<S-Home>", "0", opts)
keymap.set("i", "<S-Home>", "<Esc>v0", opts)
keymap.set("i", "<S-Right>", "<Esc>vl", opts)
keymap.set("v", "<S-Right>", "l", opts)
keymap.set("i", "<S-Left>", "<Esc>vh", opts)
keymap.set("v", "<S-Left>", "h", opts)
keymap.set("n", "<S-Down>", "v<Down>", opts)
keymap.set("v", "<S-Down>", "j", opts)
keymap.set("n", "<S-Up>", "v<Up>", opts)
keymap.set("v", "<S-Up>", "k", opts)

-- select all with Ctrl + a
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Cut, copy and paste
keymap.set("v", "<C-x>", '"+d', opts)
keymap.set("v", "<C-c>", '"+y', opts)
keymap.set("n", "<C-v>", '"+p', opts)
keymap.set("i", "<C-v>", "<C-r>+", opts)
keymap.set("v", "<C-v>", '"_d"+P', opts)

-- Visual block with Alt + v
keymap.set("n", "<A-v>", "<Cmd>execute 'normal! <C-v>'<CR>", opts)

-- Close current buffer (equivalent to closing a tab in VSCode)
keymap.set("n", "<C-w>", ":BufferLinePickClose<CR>", opts)

-- `Ctrl+P` to find files (same as VSCode's Quick Open)
keymap.set("n", "<C-p>", ":Telescope find_files<CR>", opts)

-- `Ctrl+Shift+P` for Neovim's command palette (like VSCode)
keymap.set("n", "<C-S-p>", ":Telescope commands<CR>", opts)

-- `Ctrl+Shift+F` for searching in project (VSCode's global search)
keymap.set("n", "<C-S-f>", ":Telescope live_grep<CR>", opts)

-- moving lines up and down with Alt + keys in normal mode or insert mode
keymap.set("n", "<A-Up>", ":m .-2<CR>==", opts)
keymap.set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", opts)
keymap.set("n", "<A-Down>", ":m .+1<CR>==", opts)
keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", opts)

-- tab or shift+tab on normal mode to indent right or left the current line
keymap.set("n", "<Tab>", ">>")
keymap.set("n", "<S-Tab>", "<<")

-- on visual mode, tab or shift+tab will indent right or left the selected lines
keymap.set("v", "<Tab>", ">gv")
keymap.set("v", "<S-Tab>", "<gv")

keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)

keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
keymap.set("n", "<F12>", ":Telescope diagnostics<CR>", opts)
keymap.set("n", "<A-CR>", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
-- ---------------------------------------------------------------------------

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

-- Back to start
vim.keymap.set("n", "<leader>qA", function()
  vim.cmd("bufdo bwipeout")
  vim.cmd("Alpha")
end, merge_tables(opts, { desc = "Close all buffers and return to dashboard" }))
