return {
    'mrcjkb/rustaceanvim',
    version = '^9', -- v9 requires nvim >= 0.12; config keys (server.checkOnSave via default_settings) stable v5→v9
    lazy = false, -- This plugin is already lazy
    config = function()
        vim.g.rustaceanvim = {
            server = {
                on_attach = function(client, bufnr)
                    -- You can add specific rust mappings here if you want
                end,
                default_settings = {
                    ['rust-analyzer'] = {
                        checkOnSave = {
                            command = "clippy",
                        },
                    },
                },
            },
        }
    end
}
