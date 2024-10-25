local capabilities = require("cmp_nvim_lsp").default_capabilities()

local servers = {
  "emmet_ls",
  "clangd",
  "jdtls",
  "gopls",
  "jsonls",
  "html",
  "tsserver",
  "rust_analyzer",
  "cmake",
  "bashls",
  "lua_ls",
}

local border = {
  { "┌", "FloatBorder" },
  { "─", "FloatBorder" },
  { "┐", "FloatBorder" },
  { "│", "FloatBorder" },
  { "┘", "FloatBorder" },
  { "─", "FloatBorder" },
  { "└", "FloatBorder" },
  { "│", "FloatBorder" },
}

local lspconfig = require("lspconfig")
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup({
    handlers = {
      ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
      ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
        close_events = { "CursorMoved", "InsertCharPre" },
        focusable = false,
        offset_x = 0,
        offset_y = -5, -- Adjust this to move the signature help window up or down
      }),
    },
    -- border = border,
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      if client.server_capabilities["documentSymbolProvider"] then
        require("nvim-navic").attach(client, bufnr)
      end
    end,
  })
end

-- Add the search and replace functionality
local M = {}

M.search_and_replace = function()
  local word = vim.fn.expand("<cword>")

  require("telescope.builtin").grep_string({
    search = word,
    word_match = "-w",
    use_regex = false,
    search_dirs = { vim.fn.getcwd() },
    prompt_title = "Search and Replace",
  })

  vim.api.nvim_command("copen")
  vim.api.nvim_command("setlocal modifiable")
  vim.api.nvim_command("cdo s/\\<" .. word .. "\\>/\\=" .. 'input("Replace with: ")' .. "/g | update")
end

return M
