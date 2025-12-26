return {
  "christoomey/vim-tmux-navigator",
  lazy = false, -- Cargar al inicio para que los mapeos funcionen siempre
  enabled = vim.env.TERM_PROGRAM ~= "WezTerm",
}
