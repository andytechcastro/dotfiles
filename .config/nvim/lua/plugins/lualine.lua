return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    config = function()
        local lualine = require("lualine")
        local lazy_status = require("lazy.status") -- to configure lazy pending updates count

        -- Asegurarnos de que el tema de catppuccin esté disponible para lualine
        local ok, _ = pcall(require, "catppuccin")
        if not ok then
            vim.notify("Catppuccin no encontrado, lualine podría fallar", vim.log.levels.WARN)
        end

        local lualine_theme = "catppuccin"
        local theme_ok, _ = pcall(require, "lualine.themes." .. lualine_theme)
        if not theme_ok then
            lualine_theme = "auto"
        end

        lualine.setup({
            options = {
                theme = lualine_theme,
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = { "alpha", "dashboard", "nvim-tree", "Outline" },
                },
            },
            sections = {
                lualine_x = {
                    {
                        lazy_status.updates,
                        cond = lazy_status.has_updates,
                        color = { fg = "#ff9e64" },
                    },
                    { "encoding" },
                    { "fileformat" },
                    { "filetype" },
                },
            },
        })
    end,
}
