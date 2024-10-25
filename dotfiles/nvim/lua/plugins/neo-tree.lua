return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      window = {
        width = 30,
        mappings = {
          ["L"] = "open_nofocus",
        },
      },
      commands = {
        open_nofocus = function(state)
          require("neo-tree.sources.filesystem.commands").open(state)
          vim.schedule(function()
            vim.cmd([[Neotree focus]])
          end)
        end,
      },
    },
    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    auto_close = true,
    close_if_last_window = true,
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
  end,
}
