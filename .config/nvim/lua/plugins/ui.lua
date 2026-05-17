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

    -- Image rendering in Neovim (required for diagram.nvim)
    {
        "3rd/image.nvim",
        build = false,
        opts = {
            backend = "kitty",
            processor = "magick_cli",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" },
                },
            },
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" },
        },
    },

    -- Mermaid & diagram rendering
    {
        "3rd/diagram.nvim",
        dependencies = { "3rd/image.nvim" },
        ft = { "markdown" },
        opts = {
            events = {
                render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
                clear_buffer = { "BufLeave" },
            },
            renderer_options = {
                mermaid = {
                    background = "transparent",
                    theme = "dark",
                    scale = 2,
                },
            },
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