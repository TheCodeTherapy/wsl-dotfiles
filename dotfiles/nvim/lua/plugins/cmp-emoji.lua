return {
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- table.insert(opts.sources, { name = "emoji" })
      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "noselect",
      }
      opts.experimental = {
        ghost_text = false,
      }
      opts.window = {
        completion = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:NormalFloat",
        }),
        documentation = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:NormalFloat",
        }),
      }
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- I could replace the expand_or_jumpable() calls
            -- by expand_or_locally_jumpable() to only jump
            -- inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-Tab>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.abort()
          end
        end, { "i", "s" }),
      })
    end,
  },
}
