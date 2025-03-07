local center_cursor_enabled = false
local center_cursor_group = "CenterCursorGroup"

local function toggle_center_cursor()
  if center_cursor_enabled then
    vim.api.nvim_del_augroup_by_name(center_cursor_group)
    vim.notify("Center Cursor: OFF", vim.log.levels.INFO)
  else
    vim.api.nvim_create_augroup(center_cursor_group, { clear = true })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = center_cursor_group,
      callback = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd("normal! zz")
        vim.api.nvim_win_set_cursor(0, pos)
      end,
    })
    vim.notify("Center Cursor: ON", vim.log.levels.INFO)
  end
  center_cursor_enabled = not center_cursor_enabled
end

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts_extend = { "spec" },
  opts = {
    preset = "helix",
    defaults = {},
    spec = {
      {
        mode = { "n", "v" },
        { "<leader><tab>", group = "tabs" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>dp", group = "profiler" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
        { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "gs", group = "surround" },
        { "z", group = "fold" },
        {
          "<leader>b",
          group = "buffer",
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
        {
          "<leader>w",
          group = "windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        {
          "<leader>ux",
          function()
            toggle_center_cursor()
          end,
          desc = function()
            return center_cursor_enabled and "  Disable Center Cursor" or "  Enable Center Cursor"
          end,
        },
        -- better descriptions
        { "gx", desc = "Open with system app" },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps (which-key)",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end,
      desc = "Window Hydra Mode (which-key)",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    if not vim.tbl_isempty(opts.defaults) then
      LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
      wk.register(opts.defaults)
    end
  end,
}
