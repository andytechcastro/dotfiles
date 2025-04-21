vim.g.mapleader = " "
-- TogleTerm
vim.keymap.set("n", "<leader>t", ':ToggleTerm<CR>', {}) -- ToggleTerm
-- LazyGit
vim.keymap.set("n", "<leader>g", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})

-- Movements
vim.keymap.set('n', '<C-Right>', '<c-w>l', {noremap = true, silent = true})
vim.keymap.set('n', '<C-Left>', '<c-w>h', {noremap = true, silent = true})
vim.keymap.set('n', '<C-Up>', '<c-w>k', {noremap = true, silent = true})
vim.keymap.set('n', '<C-Down>', '<c-w>j', {noremap = true, silent = true})

vim.keymap.set('', '<C-l>', '<c-w>l', {noremap = true, silent = true})
vim.keymap.set('', '<C-h>', '<c-w>h', {noremap = true, silent = true})
vim.keymap.set('', '<C-k>', '<c-w>k', {noremap = true, silent = true})
vim.keymap.set('', '<C-j>', '<c-w>j', {noremap = true, silent = true})

-- Ranger
vim.keymap.set('','<S-Tab>', ':Ranger<CR>',{})
vim.keymap.set('','<S-t>', ':RangerNewTab<CR>',{})

-- Tagbar
vim.keymap.set('','<F8>', ':TagbarToggle<CR>',{})

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>ft', ':TodoTelescope<CR>', { desc = 'Telescope todo comments' })

-- UndoTree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Session Manager
vim.keymap.set("n", "<leader>sm", ':SessionManager<CR>', {})

vim.keymap.set('n', '<C-p>', ":lua require'telescope'.extensions.project.project{}<CR>", {noremap = true, silent = true})

-- BarBar
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Move to previous/next
vim.keymap.set('n', '<A-,>', '<Cmd>BufferPrevious<CR>', opts)
vim.keymap.set('n', '<A-.>', '<Cmd>BufferNext<CR>', opts)

-- Re-order to previous/next
vim.keymap.set('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', opts)
vim.keymap.set('n', '<A->>', '<Cmd>BufferMoveNext<CR>', opts)

-- Goto buffer in position...
vim.keymap.set('n', '<A-1>', '<Cmd>BufferGoto 1<CR>', opts)
vim.keymap.set('n', '<A-2>', '<Cmd>BufferGoto 2<CR>', opts)
vim.keymap.set('n', '<A-3>', '<Cmd>BufferGoto 3<CR>', opts)
vim.keymap.set('n', '<A-4>', '<Cmd>BufferGoto 4<CR>', opts)
vim.keymap.set('n', '<A-5>', '<Cmd>BufferGoto 5<CR>', opts)
vim.keymap.set('n', '<A-6>', '<Cmd>BufferGoto 6<CR>', opts)
vim.keymap.set('n', '<A-7>', '<Cmd>BufferGoto 7<CR>', opts)
vim.keymap.set('n', '<A-8>', '<Cmd>BufferGoto 8<CR>', opts)
vim.keymap.set('n', '<A-9>', '<Cmd>BufferGoto 9<CR>', opts)
vim.keymap.set('n', '<A-0>', '<Cmd>BufferLast<CR>', opts)

-- Pin/unpin buffer
vim.keymap.set('n', '<A-p>', '<Cmd>BufferPin<CR>', opts)

-- Goto pinned/unpinned buffer
--                 :BufferGotoPinned
--                 :BufferGotoUnpinned

-- Close buffer
vim.keymap.set('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)

-- Wipeout buffer
--                 :BufferWipeout

-- Close commands
--                 :BufferCloseAllButCurrent
--                 :BufferCloseAllButPinned
--                 :BufferCloseAllButCurrentOrPinned
--                 :BufferCloseBuffersLeft
--                 :BufferCloseBuffersRight

-- Magic buffer-picking mode
vim.keymap.set('n', '<leader>bpp',   '<Cmd>BufferPick<CR>', opts)
vim.keymap.set('n', '<leader>bpd', '<Cmd>BufferPickDelete<CR>', opts)

-- Sort automatically by...
vim.keymap.set('n', '<leader>bb', '<Cmd>BufferOrderByBufferNumber<CR>', opts)
vim.keymap.set('n', '<leader>bn', '<Cmd>BufferOrderByName<CR>', opts)
vim.keymap.set('n', '<leader>bd', '<Cmd>BufferOrderByDirectory<CR>', opts)
vim.keymap.set('n', '<leader>bl', '<Cmd>BufferOrderByLanguage<CR>', opts)
vim.keymap.set('n', '<leader>bw', '<Cmd>BufferOrderByWindowNumber<CR>', opts)

-- Other:
-- :BarbarEnable - enables barbar (enabled by default)
-- :BarbarDisable - very bad command, should never be used
--
--
--
-- GoDebug
vim.keymap.set('n', '<F5>', ":GoDebug -t<CR>")
vim.keymap.set('n', '<leader>d', ":GoDebug -b<CR>")

-- nvimtree

vim.keymap.set('n','<TAB>', ':NvimTreeToggle<CR>')

-- TODO Comment
vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })
