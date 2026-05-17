return {
    'mrcjkb/rustaceanvim',
    version = '^5', -- Recommended
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
