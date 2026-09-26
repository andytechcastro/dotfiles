-- Terminal
vim.keymap.set("n", "<leader>tf", function() Snacks.terminal() end, { desc = "Terminal (Float)" })
vim.keymap.set("n", "<leader>th", function() TerminalDown() end, { desc = "Terminal (Horizontal)" })

vim.keymap.set('t', '<esc>', [[<C-\><C-n>]])


-- LazyGit
vim.keymap.set("n", "<leader>tg", "<cmd>lua LazyGitToggle()<CR>", {desc = "Git", noremap = true, silent = true})

-- Movements (smart-splits; falls back to native wincmd when plugin is disabled)
local function ss_move(dir, key)
    return function()
        local ss = package.loaded["smart-splits"]
        if ss then
            ss["move_cursor_" .. dir]()
        else
            vim.cmd("wincmd " .. key)
        end
    end
end
vim.keymap.set('n', '<C-Right>', ss_move('right', 'l'), {noremap = true, silent = true})
vim.keymap.set('n', '<C-Left>', ss_move('left', 'h'), {noremap = true, silent = true})
vim.keymap.set('n', '<C-Up>', ss_move('up', 'k'), {noremap = true, silent = true})
vim.keymap.set('n', '<C-Down>', ss_move('down', 'j'), {noremap = true, silent = true})

-- Undo: snacks.nvim undo module provides <leader>u (see plugins/snacks.lua)

-- Go debugging = nvim-dap (lua/plugins/dap.lua, grupo <leader>d). GoDebug de go.nvim eliminado.

-- Explorer (Oil) — '-' abre Oil en el dir padre (default de oil); <leader>e en cwd
vim.keymap.set('n', '<leader>e', '<CMD>Oil<CR>', { desc = "File Explorer" })

-- TODO Comment
vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })

-- Oil
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>-", "<CMD>Oil --float<CR>", { desc = "Open parent directory (float)" })

-- Go
vim.keymap.set("n", "<leader>ttr", "<cmd>lua GoRun()<CR>", {desc = "go run .", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ttt", "<cmd>lua GoTest()<CR>", {desc = "go test", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ttg", "<cmd>lua GeminiTerm()<CR>", {desc = "Gemini", noremap = true, silent = true})

-- OpenCode
vim.keymap.set("n", "<leader>og", ":GraphifyUpdate<CR>", {desc = "Graphify Update", noremap = true, silent = true})
vim.keymap.set("n", "<leader>oh", ":HexCheck<CR>", {desc = "Hexagonal Check", noremap = true, silent = true})
vim.keymap.set("n", "<leader>ob", ":OpenCodeBuild<CR>", {desc = "OpenCode Build", noremap = true, silent = true})
