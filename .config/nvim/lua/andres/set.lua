local set = vim.opt

vim.filetype = off
vim.filetype.plugin = on
set.smartindent = true
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
set.scrolloff = 8

set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.vim/undodir"
set.undofile = true

vim.cmd("highlight LineNr ctermfg=grey")
vim.cmd("syntax enable")
vim.cmd("set splitbelow")
vim.cmd("set splitright")

-- vim-airline
vim.cmd("let g:airline#extensions#tabline#enabled = 1")
vim.g.airline_powerline_fonts = 1
vim.g.Powerline_symbols = 'unicode'
vim.g.powerline_pycmd = 'py3'
vim.opt.laststatus = 2

-- on
local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
   require('go.format').gofmt()
  end,
  group = format_sync_grp,
})
