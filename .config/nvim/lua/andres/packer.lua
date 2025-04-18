-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.4',
        -- or                            , branch = '0.1.x',
        requires = { {'nvim-lua/plenary.nvim'} }
    }
    use {'ahmedkhalf/project.nvim'}
    use {'nvim-telescope/telescope-project.nvim'}
    -- use {'nordtheme/vim'}
    use {'andytechcastro/nordthemevim'}
    use('nvim-treesitter/nvim-treesitter', {run =  ':TSUpdate'})
    use('nvim-treesitter/playground')
    use('mbbill/undotree')
    use {'airblade/vim-gitgutter'}
    use('tpope/vim-fugitive')
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {'williamboman/mason.nvim'},           -- Optional
            {'williamboman/mason-lspconfig.nvim'}, -- Optional

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},         -- Required
            {'hrsh7th/cmp-nvim-lsp'},     -- Required
            {'hrsh7th/cmp-buffer'},       -- Optional
            {'hrsh7th/cmp-path'},         -- Optional
            {'saadparwaiz1/cmp_luasnip'}, -- Optional
            {'hrsh7th/cmp-nvim-lua'},     -- Optional

            -- Snippets
            {'L3MON4D3/LuaSnip'},             -- Required
            {'rafamadriz/friendly-snippets'}, -- Optional
        }
    }
    use {'francoiscabrol/ranger.vim'}
    use {'jiangmiao/auto-pairs'}
    use {'majutsushi/tagbar'}
    use {'powerline/powerline'}
    use {'vim-airline/vim-airline'}
    use {'ryanoasis/vim-devicons'}
    use {'chrisbra/csv.vim'}
    use 'ray-x/go.nvim'
    use 'ray-x/guihua.lua'
    use {'towolf/vim-helm'}
    use {'frazrepo/vim-rainbow'}
    use {'dgryski/vim-godef'}
    use {'mfussenegger/nvim-dap'}
    use {'leoluz/nvim-dap-go'}
    use { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"} }
    use {'theHamsta/nvim-dap-virtual-text'}
    -- NerdTree
    use {'christoomey/vim-tmux-navigator'}
    use { "nvim-neotest/nvim-nio" }
    use {'folke/flash.nvim'}
    use({
        "stevearc/oil.nvim",
        config = function()
           require("oil").setup()
        end,
        requires = { {'nvim-tree/nvim-web-devicons'} }
    })
     -- Required plugins
    use 'stevearc/dressing.nvim'
    use 'nvim-lua/plenary.nvim'
    use 'MunifTanjim/nui.nvim'
    use 'MeanderingProgrammer/render-markdown.nvim'

    -- Optional dependencies
    use 'HakonHarnes/img-clip.nvim'
    use 'zbirenbaum/copilot.lua'

    -- Avante.nvim with build process
    use 'yetone/avante.nvim'

    use 'folke/which-key.nvim'
    use {
        'goolord/alpha-nvim',
        requires = {
            'echasnovski/mini.icons',
            'nvim-lua/plenary.nvim'
        },
    }
    use 'Shatur/neovim-session-manager'
    use 'akinsho/toggleterm.nvim'

    use 'lewis6991/gitsigns.nvim' -- OPTIONAL: for git status
    use 'romgrk/barbar.nvim'
    use 'nvim-tree/nvim-tree.lua'
end)
