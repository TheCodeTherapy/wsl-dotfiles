local keymap = vim.keymap
local opts = { noremap = true, silent = true }
---@diagnostic disable-next-line: unused-local
local surround_chars = "[\"'(){}%[%]]"

-- utils -----------------------------------------------------------------------
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

-- unified picker dispatcher (lazyvim -> snacks -> fzf-lua -> fallback)
local function dispatch_pick(kind, o)
  o = o or {}

  -- 1) routes to default configured picker (snacks/fzf/telescope)
  local ok_lazy, LazyVim = pcall(require, "lazyvim.util")
  if ok_lazy and LazyVim and LazyVim.pick then
    local fn = LazyVim.pick(kind, o)
    if type(fn) == "function" then
      return fn()
    end
  end

  -- 2) snacks picker
  local ok_snacks, Snacks = pcall(require, "snacks")
  if ok_snacks and Snacks and Snacks.picker then
    if kind == "files" then
      return Snacks.picker.files(o)
    elseif kind == "commands" then
      return Snacks.picker.commands(o)
    elseif kind == "live_grep" or kind == "grep" then
      -- o.default / o.search are supported as seed text in our shim
      return Snacks.picker.grep(o)
    elseif kind == "diagnostics" or kind == "diagnostics_workspace" then
      return Snacks.picker.diagnostics(o)
    elseif kind == "lines" then
      return Snacks.picker.lines(o)
    elseif kind == "grep_string" then
      -- emulate grep_string using grep seeded with default/search
      return Snacks.picker.grep(o)
    end
  end

  -- 3) fzf-lua
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    if kind == "files" then
      return fzf.files()
    elseif kind == "commands" then
      return fzf.commands()
    elseif kind == "live_grep" or kind == "grep" then
      local q = o.default or o.search
      return fzf.live_grep({ query = q })
    elseif kind == "diagnostics" or kind == "diagnostics_workspace" then
      return fzf.diagnostics_workspace()
    elseif kind == "lines" then
      return fzf.blines({ query = o.default })
    elseif kind == "grep_string" then
      local q = o.default or o.search
      if q and #q > 0 then
        return fzf.grep({ search = q })
      else
        return fzf.grep()
      end
    end
  end

  -- 4) minimal built-ins fallback
  if kind == "lines" and o.default then
    vim.cmd(("normal! /\\V%s\\<CR>"):format(vim.fn.escape(o.default, "\\/")))
  else
    vim.notify("No picker available for: " .. tostring(kind), vim.log.levels.WARN)
  end
end

local function cword()
  return vim.fn.expand("<cword>")
end

-- diagnostics helpers ---------------------------------------------------------
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
  local extension_to_markdown = { ts = "typescript", js = "javascript", py = "python" }
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

local function toggle_snacks_explorer()
  local ok, Snacks = pcall(require, "snacks")
  if ok and Snacks and Snacks.explorer then
    Snacks.explorer() -- this is the toggle/open behavior
  else
    vim.notify("Snacks.explorer not available", vim.log.levels.WARN)
  end
end

-- mappings --------------------------------------------------------------------
keymap.set("n", "<leader>ccm", create_and_preview_diagnostics, opts)
keymap.set("n", "<leader>cca", copy_file_and_diagnostics_to_clipboard, opts)
keymap.set("n", "<leader>cc", copy_diagnostics_to_clipboard, opts)

keymap.set("n", "<leader>#", "#N", opts)
keymap.set("t", "<S-Space>", "<Space>", opts)

keymap.set("i", "<S-Del>", "<Space><Esc>vwhdi", opts)
keymap.set("n", "<S-Del>", "a<Space><Esc>vwhdi", opts)

-- Move lines around
keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)
keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)
keymap.set("n", "<A-Up>", ":m .-2<CR>==", opts)
keymap.set("n", "<A-Down>", ":m .+1<CR>==", opts)
keymap.set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", opts)
keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", opts)

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

-- VSCode-like ---------------------------------------------------------------

-- Save
keymap.set("i", "<C-s>", "<Esc>:w<CR>a", opts)

-- Explorer toggle (keep Neo-tree if you use it)
-- Explorer toggle (Snacks Explorer in LazyVim 14+)
keymap.set("n", "<C-b>", toggle_snacks_explorer, opts)
keymap.set("i", "<C-b>", function()
  vim.cmd("stopinsert")
  toggle_snacks_explorer()
end, opts)

-- Select with shift + arrows/home/end
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

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Cut/copy/paste
keymap.set("v", "<C-x>", '"+d', opts)
keymap.set("v", "<C-c>", '"+y', opts)
keymap.set("n", "<C-v>", '"+p', opts)
keymap.set("i", "<C-v>", "<C-r>+", opts)
keymap.set("v", "<C-v>", '"_d"+P', opts)

-- Visual block
keymap.set("n", "<A-v>", "<Cmd>execute 'normal! <C-v>'<CR>", opts)

-- Close current buffer (VSCode-like tab close)
keymap.set("n", "<C-w>", ":BufferLinePickClose<CR>", opts)

-- Picker replacements (no Telescope) -----------------------------------------

-- Ctrl+P — find files
keymap.set("n", "<C-p>", function()
  dispatch_pick("files")
end, merge_tables(opts, { desc = "Find files" }))

-- Ctrl+Shift+P — command palette
keymap.set("n", "<C-S-p>", function()
  dispatch_pick("commands")
end, merge_tables(opts, { desc = "Command palette" }))

-- Ctrl+Shift+F — project-wide search (live grep)
keymap.set("n", "<C-S-f>", function()
  dispatch_pick("live_grep")
end, merge_tables(opts, { desc = "Search in project (live grep)" }))

-- LSP helpers
keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)

-- F12 — diagnostics (workspace)
keymap.set("n", "<F12>", function()
  dispatch_pick("diagnostics_workspace")
end, merge_tables(opts, { desc = "Diagnostics (workspace)" }))

keymap.set("n", "<A-CR>", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

-- Ctrl+f — search in current buffer (seeded with <cword>)
keymap.set("n", "<C-f>", function()
  dispatch_pick("lines", { default = cword() })
end, merge_tables(opts, { desc = "Search in current buffer" }))

keymap.set("i", "<C-f>", function()
  local w = cword()
  vim.cmd("stopinsert")
  dispatch_pick("lines", { default = w })
end, merge_tables(opts, { desc = "Search in current buffer" }))

-- Ctrl+g — project live grep seeded with <cword>
keymap.set("n", "<C-g>", function()
  dispatch_pick("live_grep", { default = cword() })
end, merge_tables(opts, { desc = "Search word in project" }))

keymap.set("i", "<C-g>", function()
  local w = cword()
  vim.cmd("stopinsert")
  dispatch_pick("live_grep", { default = w })
end, merge_tables(opts, { desc = "Search word in project" }))

keymap.set("n", "<leader>qr", function()
  vim.cmd("cquit 69")
end, merge_tables(opts, { desc = "Quit all and exit with 69" }))
