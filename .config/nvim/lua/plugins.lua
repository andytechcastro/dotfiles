-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Simple plugins can be specified as strings
  use 'rstacruz/vim-closer'


  -- Post-install/update hook with neovim command
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- coc
  use {'neoclide/coc.nvim', branch = 'release'}

  use {'nordtheme/vim'}

  -- Old plugins
  use {'vim-airline/vim-airline'}
  use {'jiangmiao/auto-pairs'}
  use {'francoiscabrol/ranger.vim'}
  use {'christoomey/vim-tmux-navigator'}
  use {'majutsushi/tagbar'}
  use {'powerline/powerline'}
  use {'hashivim/vim-terraform'}
  use {'ryanoasis/vim-devicons'}
  use {'nvim-lua/plenary.nvim'}
  use {'nvim-telescope/telescope.nvim'}
  use {'ahmedkhalf/project.nvim'}
  use {'nvim-telescope/telescope-project.nvim'}
  use {'airblade/vim-gitgutter'}
  use {'tpope/vim-fugitive'}
  use {'towolf/vim-helm'}
  use {'frazrepo/vim-rainbow'}

  use 'ray-x/go.nvim'
  use 'ray-x/guihua.lua' -- recommended if need floating window support
  use 'neovim/nvim-lspconfig'
  use 'dense-analysis/ale'
end)
