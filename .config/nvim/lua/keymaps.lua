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

-- coc keymaps
vim.keymap.set("i", "<C-Space>", "coc#pum#visible() ? coc#pum#stop() : coc#refresh()", { expr = true, noremap = true, silent = true })
vim.keymap.set("i", "<Tab>", "coc#pum#visible() ? coc#pum#next(1) : '<Tab>'", { expr = true, noremap = true, silent = true })
vim.keymap.set("i", "<S-Tab>", "coc#pum#visible() ? coc#pum#prev(1) : '<C-h>'", { expr = true, noremap = true, silent = true })
vim.keymap.set("i", "<CR>", "coc#pum#visible() ? coc#pum#confirm() : '<C-g>u<CR>'", { expr = true, noremap = true, silent = true })

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
