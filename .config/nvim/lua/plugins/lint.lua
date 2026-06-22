return {
  "mfussenegger/nvim-lint",
  dependencies = {
    "rshkarin/mason-nvim-lint",
  },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    
    lint.linters_by_ft = {
      go = { "golangcilint" },
      terraform = { "tflint" },
      dockerfile = { "hadolint" },
      yaml = { "yamllint" },
      json = { "jsonlint" },
      markdown = { "markdownlint" },
      bash = { "shellcheck" },
      sh = { "shellcheck" },
      lua = { "selene" },
    }
    
    -- Autocommand para linting
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })
    
    -- Keymap para lint manual
    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Trigger linting" })
    
    -- Integración con Mason
    require("mason-nvim-lint").setup({
      automatic_installation = true,
    })
  end,
}
