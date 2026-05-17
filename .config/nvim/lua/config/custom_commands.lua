-- Reload vim config
vim.api.nvim_create_user_command('ReloadConfig', 'source $MYVIMRC', {})

-- OpenCode Commands
vim.api.nvim_create_user_command('GraphifyUpdate', function() require('config.opencode').graphify_update() end, {})
vim.api.nvim_create_user_command('HexCheck', function() require('config.opencode').hex_check() end, {})
vim.api.nvim_create_user_command('OpenCodeBuild', function() require('config.opencode').opencode_build() end, {})
