-- LazyGitToggle run a lazygit app into a terminal
function LazyGitToggle()
    Snacks.lazygit()
end

-- Terminal
function TerminalDown()
    Snacks.terminal(nil, { win = { position = "bottom", height = 15 } })
end

-- Go Run execute a terminal with go run .
function GoRun()
    Snacks.terminal("go run .", { interactive = true })
end

-- Go Test execute a terminal with gotest
function GoTest()
    Snacks.terminal("gotest ./... -v", { interactive = true })
end

-- Gemini Term
function GeminiTerm()
    Snacks.terminal("gemini", { 
        win = { 
            position = "right", 
            width = math.floor(vim.o.columns * 0.25)
        }
    })
end