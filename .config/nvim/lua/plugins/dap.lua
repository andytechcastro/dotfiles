return {
    {
        'rcarriga/nvim-dap-ui',
        dependencies = {
            'mfussenegger/nvim-dap',
            'leoluz/nvim-dap-go',
            'theHamsta/nvim-dap-virtual-text',
            'nvim-neotest/nvim-nio'
        },
        keys = {
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
            { "<leader>ds", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
            { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
            { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
            { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
            { "<leader>dq", function() require("dap").step_out() end, desc = "Step out" },
            { "<leader>dr", function() require("dap").repl.open() end, desc = "Open REPL" },
            { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover expression" },
            { "<leader>dd", function() require("dap").close() end, desc = "Disconnect session" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
            { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
        },
        config = function()
            local dap, dapui = require("dap"), require("dapui")

            -- Inline variable values next to code
            require("nvim-dap-virtual-text").setup()

            -- Registers the delve adapter + "Delve"/"Delve Test" Go configs.
            -- Coexists with go.nvim dap_debug (both target delve).
            require("dap-go").setup({
                dapui = { winbar = true },
            })

            -- rustaceanvim ^9 auto-registers codelldb (installed via Mason)
            -- for rust debugging; no manual adapter needed here.

            dapui.setup({
                layouts = {
                    {
                        elements = {
                            { id = "scopes", size = 0.25 },
                            { id = "breakpoints", size = 0.25 },
                            { id = "stacks", size = 0.25 },
                            { id = "watches", size = 0.25 },
                        },
                        size = 40,
                        position = "left",
                    },
                    {
                        elements = {
                            { id = "repl", size = 0.5 },
                            { id = "console", size = 0.5 },
                        },
                        size = 10,
                        position = "bottom",
                    },
                },
            })

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
    }
}
