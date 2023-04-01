require('plugins')
require('keymaps')
require('go').setup()

local set = vim.opt

vim.filetype = off
vim.filetype.plugin = on
set.wrap = true
set.encoding = 'utf-8'
set.relativenumber = true
set.number = true
set.hlsearch = true
set.incsearch = true
set.tabstop = 4
set.shiftwidth = 4
set.expandtab = true
set.belloff = 'all'

vim.cmd("highlight LineNr ctermfg=grey")
vim.cmd("syntax enable")
vim.cmd("colorscheme nord")
vim.cmd("set splitbelow")
vim.cmd("set splitright")

-- vim-airline
vim.cmd("let g:airline#extensions#tabline#enabled = 1")
vim.g.airline_powerline_fonts = 1
vim.g.Powerline_symbols = 'unicode'
vim.g.powerline_pycmd = 'py3'
set.laststatus = 2

-- project root
vim.cmd("let g:rootmarkers = ['.projectroot', '.git']")
