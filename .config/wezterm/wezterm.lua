local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Configuración Básica y Robusta
config.enable_wayland = true
config.front_end = "WebGpu" -- Probamos el default primero, si falla volvemos a OpenGL
config.term = "wezterm"

-- Apariencia Limpia
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 11.0
config.window_background_opacity = 0.90

-- Sin barra de pestañas compleja (para evitar crashes)
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

return config
