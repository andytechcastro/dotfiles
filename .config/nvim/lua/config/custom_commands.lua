-- Reload vim config
vim.api.nvim_create_user_command('ReloadConfig', 'source $MYVIMRC', {})

-- OpenCode Commands
vim.api.nvim_create_user_command('GraphifyUpdate', function() require('config.opencode').graphify_update() end, {})
vim.api.nvim_create_user_command('HexCheck', function() require('config.opencode').hex_check() end, {})
vim.api.nvim_create_user_command('OpenCodeBuild', function() require('config.opencode').opencode_build() end, {})

-- Install essential Mason tools (synced with mason-tools.lua ensure_installed)
vim.api.nvim_create_user_command('MasonInstallEssentials', function()
  local tools = {
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
  }
  
  local cmd = "MasonInstall " .. table.concat(tools, " ")
  vim.cmd(cmd)
  vim.notify("Installing essential Mason tools...")
end, { desc = "Install essential Mason tools" })
