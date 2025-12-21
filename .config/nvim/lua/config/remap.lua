-- Personal
--vim.keymap.set({'n', 'x'}, 'gy', '"+y')
--vim.keymap.set({'n', 'x'}, 'gp', '"+p')
--vim.keymap.set({'n', 'x'}, 'x', '"_x')
--vim.keymap.set({'n', 'x'}, 'X', '"_d')

-- TogleTerm
vim.keymap.set("n", "<leader>tf", ':ToggleTerm<CR>', { desc = "Terminal (Float)" }) -- ToggleTerm
vim.keymap.set("n", "<leader>th", '<cmd>lua TerminalDown()<CR>', { desc = "Terminal (Horizontal)" }) -- ToggleTerm

vim.keymap.set('t', '<esc>', [[<C-\><C-n>]])


-- LazyGit
vim.keymap.set("n", "<leader>tg", "<cmd>lua LazyGitToggle()<CR>", {desc = "Git", noremap = true, silent = true})

-- Movements
vim.keymap.set('n', '<C-Right>', '<c-w>l', {noremap = true, silent = true})
vim.keymap.set('n', '<C-Left>', '<c-w>h', {noremap = true, silent = true})
vim.keymap.set('n', '<C-Up>', '<c-w>k', {noremap = true, silent = true})
vim.keymap.set('n', '<C-Down>', '<c-w>j', {noremap = true, silent = true})

-- Tagbar
vim.keymap.set('','<F8>', ':TagbarToggle<CR>',{})

-- UndoTree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Undo" })

-- Project with Telescope
vim.keymap.set('n', '<C-p>', ":lua require'telescope'.extensions.project.project{}<CR>", {noremap = true, silent = true})

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

-- Go
vim.keymap.set("n", "<leader>ttr", "<cmd>lua GoRun()<CR>", {desc = "go run .", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ttt", "<cmd>lua GoTest()<CR>", {desc = "go run .", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ttg", "<cmd>lua GeminiTerm()<CR>", {desc = "Gemini", noremap = true, silent = true})
