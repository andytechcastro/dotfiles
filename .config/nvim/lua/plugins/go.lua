return {
    {
        "ray-x/go.nvim",
        dependencies = {
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("go").setup({
                -- Formatting is owned solely by conform.nvim
                -- (gofumpt + goimports already configured in conform.lua).
                fmt = false,
                lsp_gofumpt = false,
                lsp_document_formatting = false,

                -- gopls is enabled via lsp.lua (mason-lspconfig + vim.lsp.config);
                -- do not let go.nvim inject its own gopls setup.
                lsp_cfg = false,

                -- Old treesitter-textobjects integration is broken on
                -- nvim-treesitter main branch.
                textobjects = false,

                -- DAP fully owned by dap-go (plugins/dap.lua): it registers the
                -- delve adapter + configs. go.nvim dap_debug off to avoid
                -- double-registering adapter 'go' / duplicate launch configs.
                dap_debug = false,
                dap_debug_keymap = false,
                dap_debug_gui = false,

                -- Linting owned by lint.lua (golangci-lint via nvim-lint).
                -- golangci_lint block removed: go.nvim's runner would duplicate.
            })
        end,
        event = {"CmdlineEnter"},
        ft = {"go", 'gomod'},
        build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
    },
    {
        "dgryski/vim-godef",
    }
}
