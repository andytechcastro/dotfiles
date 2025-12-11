return {
  "mrjones2014/smart-splits.nvim",
  lazy = false, -- Cargar al inicio para que la navegación funcione siempre
  build = './kitty/install-kittens.bash', -- Opcional, útil si alguna vez usas Kitty
  config = function()
    local smart_splits = require('smart-splits')
    
    smart_splits.setup({
      -- Configuración para WezTerm
      at_edge = 'wrap', -- O 'stop'
      log_level = 'info',
    })

    -- Mapeos de teclas (coinciden con tu config anterior)
    vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left)
    vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down)
    vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up)
    vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right)
    -- vim.keymap.set('n', '<C-\>', smart_splits.move_cursor_previous) -- Opcional

    -- Mapeos para redimensionar (opcional, pero muy útil)
    vim.keymap.set('n', '<A-h>', smart_splits.resize_left)
    vim.keymap.set('n', '<A-j>', smart_splits.resize_down)
    vim.keymap.set('n', '<A-k>', smart_splits.resize_up)
    vim.keymap.set('n', '<A-l>', smart_splits.resize_right)
  end,
}