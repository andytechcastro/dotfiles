return {
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

    -- Cursor trail effect for WezTerm (since it doesn't have native support)
    {
        "sphamba/smear-cursor.nvim",
        cond = not vim.g.neovide,
        opts = {
            smear_between_buffers = true,
            stiffness = 0.8,              -- Suavidad del trail (0.1-1.0)
            trailing_stiffness = 0.5,     -- Cola del trail
            distance_stop_animating = 0.1, -- Distancia mínima para animar
            hide_target_hack = true,      -- Mejora visual
        },
    }
}