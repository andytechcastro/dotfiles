vim.keymap.set("o", "r", function()
    local operator = vim.v.operator
    local register = vim--[[  ]].v.register
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, true, true), "o", true)
    vim.schedule(function()
        require("flash").jump({
            action = function(match, state)
                local op_func = vim.go.operatorfunc
                local saved_view = vim.fn.winsaveview()
                vim.api.nvim_set_current_win(match.win)
                vim.api.nvim_win_set_cursor(match.win, match.pos)
                _G.flash_op = function()
                    local start = vim.api.nvim_buf_get_mark(0, "[")
                    local finish = vim.api.nvim_buf_get_mark(0, "]")
                    vim.api.nvim_cmd({ cmd = "normal", bang = true, args = { "v" } }, {})
                    vim.api.nvim_win_set_cursor(0, { start[1], start[2] })
                    vim.cmd("normal! o")
                    vim.api.nvim_win_set_cursor(0, { finish[1], finish[2] })
                    vim.go.operatorfunc = op_func
                    vim.api.nvim_input('"' .. register .. operator)

                    vim.schedule(function()
                        vim.api.nvim_set_current_win(state.win)
                        vim.fn.winrestview(saved_view)
                    end)

                    _G.flash_op = nil
                end
                vim.go.operatorfunc = "v:lua.flash_op"
                vim.api.nvim_feedkeys("g@", "n", false)
            end,
        })
    end)
end)
