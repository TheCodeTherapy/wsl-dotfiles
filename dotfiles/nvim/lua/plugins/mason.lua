return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "stylua",
      "shellcheck",
      "shfmt",
      "flake8",
      "goimports",
      "gofumpt",
      "gomodifytags",
      "impl",
      "delve",
    },
  },
}
