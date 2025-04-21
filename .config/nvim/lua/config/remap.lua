-- Map Leader
vim.g.mapleader = " "


-- TogleTerm
vim.keymap.set("n", "<leader>t", ':ToggleTerm<CR>', { desc = "Terminal" }) -- ToggleTerm


-- LazyGit
vim.keymap.set("n", "<leader>g", "<cmd>lua LazyGitToggle()<CR>", {desc = "Git", noremap = true, silent = true})


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


-- UndoTree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Undo" })


-- Session Manager
vim.keymap.set("n", "<leader>sm", ':SessionManager<CR>', { desc="Session Manager" })


-- Project with Telescope
vim.keymap.set('n', '<C-p>', ":lua require'telescope'.extensions.project.project{}<CR>", {noremap = true, silent = true})


-- BarBar
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
vim.keymap.set('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)

-- Magic buffer-picking mode
vim.keymap.set('n', '<leader>bpp',   '<Cmd>BufferPick<CR>', OptBarBar("Buffer Pick"))
vim.keymap.set('n', '<leader>bpd', '<Cmd>BufferPickDelete<CR>', OptBarBar("Delete Buffer"))

-- Sort automatically by...
vim.keymap.set('n', '<leader>bb', '<Cmd>BufferOrderByBufferNumber<CR>', OptBarBar("Order Buffer by Buffer Number"))
vim.keymap.set('n', '<leader>bn', '<Cmd>BufferOrderByName<CR>', OptBarBar("Order Buffer by Name"))
vim.keymap.set('n', '<leader>bd', '<Cmd>BufferOrderByDirectory<CR>', OptBarBar("Order Buffer by Directory"))
vim.keymap.set('n', '<leader>bl', '<Cmd>BufferOrderByLanguage<CR>', OptBarBar("Order Buffer by Language"))
vim.keymap.set('n', '<leader>bw', '<Cmd>BufferOrderByWindowNumber<CR>', OptBarBar("Order Buffer by Window Number"))


-- GoDebug
vim.keymap.set('n', '<F5>', ":GoDebug -t<CR>")
vim.keymap.set('n', '<leader>d', ":GoDebug -b<CR>", { desc="Go Debug" })


-- nvimtree
vim.keymap.set('n','<TAB>', ':NvimTreeToggle<CR>')


-- TODO Comment
vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })

vim.keymap.set("n", "<leader>ft", ":TodoTelescope<CR>", { desc = "Telescope Todo Comments" })

-- Oil
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
