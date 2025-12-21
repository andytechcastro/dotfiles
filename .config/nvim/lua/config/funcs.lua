-- LazyGitToggle run a lazygit app into a terminal
function LazyGitToggle()
    local envs = {}
    envs["NVIM"] = "TRUE"
    local Terminal  = require('toggleterm.terminal').Terminal
    local lazygit = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        env = envs
    })
    lazygit:toggle()
end

-- Terminal
function TerminalDown()
    local envs = {}
    envs["NVIM"] = "TRUE"
    local Terminal = require('toggleterm.terminal').Terminal
    local horizontal = Terminal:new({
        hidden = true,
        direction = "horizontal",
        env = envs
    })
    horizontal:toggle()
end
--
-- Go Run execute a terminal with go run .
function GoRun()
    local envs = {}
    envs["NVIM"] = "TRUE"
    local Terminal  = require('toggleterm.terminal').Terminal
    local lazygit = Terminal:new({
        cmd = "go run .",
        hidden = true,
        direction = "float",
        env = envs
    })
    lazygit:toggle()
end
-- Go Test execute a terminal with gotest
function GoTest()
    local envs = {}
    envs["NVIM"] = "TRUE"
    local Terminal  = require('toggleterm.terminal').Terminal
    local lazygit = Terminal:new({
        cmd = "gotest ./... -v",
        hidden = true,
        direction = "float",
        env = envs,
        close_on_exit = false
    })
    lazygit:toggle()
end

-- Gemini Term
function GeminiTerm()
    local envs = {}
    envs["NVIM"] = "TRUE"
    local Terminal = require('toggleterm.terminal').Terminal
    local gemini = Terminal:new({
        cmd = "gemini",
        hidden = true,
        direction = "vertical",
        on_open = function(term)
            vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.25))
            -- Dobles ESC for normal mode in terminal
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc><Esc>",[[<C-\><C-n>]], { noremap = true, silent = true })
        end,
        env = envs
    })
    gemini:toggle()
end
