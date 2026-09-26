-- Reload vim config (lua, not :source $MYVIMRC)
vim.api.nvim_create_user_command('ReloadConfig', function()
  -- Drop cached config.* modules (keep config.lazy: lazy.setup must not run twice)
  for name in pairs(package.loaded) do
    if name:match('^config%.') and name ~= 'config.lazy' then
      package.loaded[name] = nil
    end
  end
  require('config.set')
  require('config.remap')
  require('config.custom_commands')
  vim.notify('Config reloaded', vim.log.levels.INFO)
end, { desc = 'Reload lua config (set, remap, custom_commands)' })

-- OpenCode Commands
vim.api.nvim_create_user_command('GraphifyUpdate', function() require('config.opencode').graphify_update() end, {})
vim.api.nvim_create_user_command('HexCheck', function() require('config.opencode').hex_check() end, {})
vim.api.nvim_create_user_command('OpenCodeBuild', function() require('config.opencode').opencode_build() end, {})

-- Install essential Mason tools (synced with mason-tools.lua ensure_installed)
vim.api.nvim_create_user_command('MasonInstallEssentials', function()
  local tools = {
    -- LSPs (canonical Mason registry package names, NOT lspconfig ids)
    "gopls", "rust-analyzer", "lua-language-server",
    "terraform-ls", "dockerfile-language-server", "yaml-language-server",
    "bash-language-server", "helm-ls", "buf", "html-lsp", "css-lsp",
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
