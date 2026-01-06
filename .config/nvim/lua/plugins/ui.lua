return {
    -- Better UI for vim.ui.select and vim.ui.input
    {
        "stevearc/dressing.nvim",
        lazy = true,
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.select(...)
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.input = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.input(...)
            end
        end,
    },

    -- Markdown rendering
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ft = { "markdown" },
        opts = {
            file_types = { "markdown" },
        },
    },
    
    -- Nui (UI components, useful library to have around)
    { "MunifTanjim/nui.nvim", lazy = true },

    -- Cursor trail effect for terminals without native support (Wezterm)
    {
        "sphamba/smear-cursor.nvim",
        cond = not vim.g.neovide,
        opts = {
            smear_between_buffers = true,
            stiffness = 0.8,
            trailing_stiffness = 0.5,
            distance_stop_animating = 0.1,
        },
    }
}
