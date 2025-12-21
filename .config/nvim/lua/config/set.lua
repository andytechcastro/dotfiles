local set = vim.opt

vim.filetype = off
vim.filetype.plugin = on
set.smartindent = true
set.wrap = true
set.breakindent = true
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



-- on
local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
   require('go.format').goimports()
  end,
  group = format_sync_grp,
})

-- Helm
vim.api.nvim_create_autocmd({'BufNewFile', 'BufRead'} , {
    pattern = 'deployment.yaml',
    callback = function()
          vim.opt_local.filetype = 'helm'
    end
})

vim.api.nvim_create_autocmd({"FocusGained","BufEnter", "CursorHold", "CursorHoldI"}, {
    pattern = "*",
    command = "checktime",
})

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")
