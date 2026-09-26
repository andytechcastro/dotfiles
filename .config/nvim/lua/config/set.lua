local set = vim.opt

set.termguicolors = true
set.smartindent = true
set.wrap = true
set.breakindent = true
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
local undodir = vim.fn.stdpath('data') .. '/undo'
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, 'p')
end
set.undodir = undodir
set.undofile = true

vim.api.nvim_set_hl(0, "LineNr", { ctermfg = 8 })
vim.o.splitbelow = true
vim.o.splitright = true



-- Tabs: Go and templ use hard tabs (global stays expandtab ts=4)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "templ" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Helm: broaden filetype detection beyond plain *.yaml
-- (paths containing /templates/ OR Chart.yaml / values.yaml)
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { '*.yaml', '*.yml' },
  callback = function(event)
    local path = event.match
    local name = vim.fn.fnamemodify(path, ':t')
    if path:find('/templates/') or name == 'Chart.yaml' or name == 'values.yaml' then
      vim.bo[event.buf].filetype = 'helm'
    end
  end,
})

vim.api.nvim_create_autocmd({"FocusGained","BufEnter", "CursorHold", "CursorHoldI"}, {
    pattern = "*",
    command = "checktime",
})

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Neovide config
if vim.g.neovide then
    vim.o.guifont = "FiraCode Nerd Font:h11"
end

require("config.lazy")
