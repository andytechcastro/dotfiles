require('plugins')
require('keymaps')
require('goconfig')
require('godapconfig')

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

-- on
local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
   require('go.format').gofmt()
  end,
  group = format_sync_grp,
})

-- rainbow
vim.cmd("let g:rainbow_active = 1")

-- Ale
vim.cmd("let g:ale_completion_enabled = 0")
vim.cmd("let b:ale_fixers = ['prettier', 'eslint']")
vim.cmd("let g:ale_fix_on_save = 1")
vim.cmd("let g:ale_floating_preview = 1")
vim.cmd("let g:ale_floating_window_border = []")
vim.cmd("let g:ale_hover_to_floating_preview = 1")
vim.cmd("let g:ale_detail_to_floating_preview = 1")

-- Ale Go
vim.cmd("let g:ale_go_golangci_lint_package = 1")

require'lspconfig'.gopls.setup{}
require'lspconfig'.golangci_lint_ls.setup{}
