return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local status_ok, configs = pcall(require, "nvim-treesitter.configs")
        if not status_ok then
            return
        end

        configs.setup({
            ensure_installed = { 
                "lua", 
                "vim", 
                "vimdoc", 
                "query",
                "go", 
                "gomod", 
                "gosum",
                "rust", 
                "terraform", 
                "hcl", 
                "yaml", 
                "json", 
                "helm",
                "dockerfile", 
                "bash", 
                "markdown", 
                "markdown_inline",
                "proto",
                "toml"
            },
            sync_install = false,
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
        })
    end
}
