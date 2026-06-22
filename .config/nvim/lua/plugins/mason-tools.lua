return {
  {
    "williamboman/mason.nvim",
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
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- LSPs
          "gopls", "rust-analyzer", "lua-language-server",
          "terraform-ls", "dockerls", "yamlls", "bashls",
          "helm-ls", "buf", "html-lsp", "css-lsp",
          "sqlls", "templ", "json-lsp", "lemminx",
          
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
