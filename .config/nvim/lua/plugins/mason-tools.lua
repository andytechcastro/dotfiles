return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {
      ui = {
        check_outdated_packages_on_open = true,
        border = "none",
        width = 0.8,
        height = 0.9,
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    }
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- LSP servers are ensured in lsp.lua (mason-lspconfig).
          -- Exception: lemminx (XML) is not in lsp.lua's list; kept here,
          -- mason-lspconfig 2.x automatic_enable will start it once installed.
          "lemminx",

          -- Linters
          "golangci-lint", "shellcheck", "hadolint",
          "yamllint", "jsonlint", "markdownlint", "tflint",
          "selene", "vale-ls",

          -- Formatters
          "gofumpt", "golines", "goimports", "stylua",
          "shfmt", "yamlfmt", "prettier", "sqlfmt",
          "xmlformatter",

          -- DAPs
          "delve", "codelldb",

          -- Go tools
          "gomodifytags", "gotests", "json-to-struct",
        },
        auto_update = true,
        run_on_start = true,
      })
    end,
  },
}
