-- Personal
--vim.keymap.set({'n', 'x'}, 'gy', '"+y')
--vim.keymap.set({'n', 'x'}, 'gp', '"+p')
--vim.keymap.set({'n', 'x'}, 'x', '"_x')
--vim.keymap.set({'n', 'x'}, 'X', '"_d')

-- Terminal
vim.keymap.set("n", "<leader>tf", function() Snacks.terminal() end, { desc = "Terminal (Float)" })
vim.keymap.set("n", "<leader>th", function() TerminalDown() end, { desc = "Terminal (Horizontal)" })

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

-- Explorer (Snacks)
vim.keymap.set('n','<TAB>', function() Snacks.explorer() end, { desc = "File Explorer" })

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
vim.keymap.set("n", "<leader>-", "<CMD>Oil --float<CR>", { desc = "Open parent directory (float)" })

-- Go
vim.keymap.set("n", "<leader>ttr", "<cmd>lua GoRun()<CR>", {desc = "go run .", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ttt", "<cmd>lua GoTest()<CR>", {desc = "go run .", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ttg", "<cmd>lua GeminiTerm()<CR>", {desc = "Gemini", noremap = true, silent = true})

-- OpenCode
vim.keymap.set("n", "<leader>og", ":GraphifyUpdate<CR>", {desc = "Graphify Update", noremap = true, silent = true})
vim.keymap.set("n", "<leader>oh", ":HexCheck<CR>", {desc = "Hexagonal Check", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ob", ":OpenCodeBuild<CR>", {desc = "OpenCode Build", noremap = true, silent = true})
