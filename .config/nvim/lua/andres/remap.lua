vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Movements
vim.api.nvim_set_keymap('n', '<C-Right>', '<c-w>l', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-Left>', '<c-w>h', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-Up>', '<c-w>k', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-Down>', '<c-w>j', {noremap = true, silent = true})

vim.api.nvim_set_keymap('', '<C-l>', '<c-w>l', {noremap = true, silent = true})
vim.api.nvim_set_keymap('', '<C-h>', '<c-w>h', {noremap = true, silent = true})
vim.api.nvim_set_keymap('', '<C-k>', '<c-w>k', {noremap = true, silent = true})
vim.api.nvim_set_keymap('', '<C-j>', '<c-w>j', {noremap = true, silent = true})

-- Ranger
vim.api.nvim_set_keymap('','<S-Tab>', ':Ranger<CR>',{})
vim.api.nvim_set_keymap('','<S-t>', ':RangerNewTab<CR>',{})

-- Tagbar
vim.api.nvim_set_keymap('','<F8>', ':TagbarToggle<CR>',{})
