local wezterm = require 'wezterm'
local act = wezterm.action

-- DEBUG
wezterm.log_info 'Cargando config WezTerm: Rounded Bubbles Style'

local config = wezterm.config_builder()

-- =========================================================================
-- FUENTES & APARIENCIA
-- =========================================================================
config.font = wezterm.font_with_fallback {
  'FiraCode Nerd Font',
  'JetBrains Mono',
  'Noto Color Emoji',
}
config.font_size = 11.0
config.color_scheme = 'Catppuccin Mocha'

config.window_background_opacity = 0.90
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- =========================================================================
-- CONFIGURACIÓN DE BARRA (Bubbles Style)
-- =========================================================================
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

-- Colores Catppuccin Mocha
local colors = {
    base = '#1e1e2e',
    mantle = '#181825',
    crust = '#11111b',
    text = '#cdd6f4',
    subtext1 = '#bac2de',
    surface1 = '#45475a',
    surface0 = '#313244',
    overlay0 = '#6c7086',
    blue = '#89b4fa',
    mauve = '#cba6f7',
    red = '#f38ba8',
    green = '#a6e3a1',
    yellow = '#f9e2af',
    peach = '#fab387',
    lavender = '#b4befe',
}

config.colors = {
  tab_bar = {
    background = colors.crust,
    active_tab = {
      bg_color = colors.crust,
      fg_color = colors.text,
    },
    inactive_tab = {
      bg_color = colors.crust,
      fg_color = colors.subtext1,
    },
    inactive_tab_hover = {
      bg_color = colors.crust,
      fg_color = colors.text,
    },
    new_tab = {
      bg_color = colors.crust,
      fg_color = colors.text,
    },
    new_tab_hover = {
      bg_color = colors.crust,
      fg_color = colors.text,
    }
  }
}

-- FORMATO DE PESTAÑAS (IZQUIERDA - Rounded Bubbles)
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1
  local title = tab.active_pane.title
  
  -- Definir estado (Activa vs Inactiva)
  local bg = colors.surface0
  local fg = colors.text
  local icon = ''

  if tab.is_active then
    bg = colors.mauve
    fg = colors.crust
    icon = '' -- Icono diferente para activa
  elseif hover then
    bg = colors.surface1
    fg = colors.text
  end

  -- Iconos de proceso básicos
  if tab.active_pane.foreground_process_name:find('vim') then icon = '' end
  if tab.active_pane.foreground_process_name:find('git') then icon = '' end
  
  return {
    { Background = { Color = colors.crust } }, -- Fondo de la barra (transparente/oscuro)
    { Foreground = { Color = bg } },
    { Text = ' ' }, -- Inicio redondeado
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = index .. ' ' .. icon .. ' ' .. title },
    { Background = { Color = colors.crust } },
    { Foreground = { Color = bg } },
    { Text = '  ' }, -- Fin redondeado + espacio
  }
end)

-- BARRA DE ESTADO (DERECHA - Rounded Bubbles)
wezterm.on('update-right-status', function(window, pane)
  local cells = {}
  
  -- Función helper para añadir una burbuja
  local function push(text, bg_color, fg_color)
    table.insert(cells, { Foreground = { Color = bg_color } })
    table.insert(cells, { Background = { Color = colors.crust } })
    table.insert(cells, { Text = '' }) -- Inicio redondeado
    
    table.insert(cells, { Background = { Color = bg_color } })
    table.insert(cells, { Foreground = { Color = fg_color } })
    table.insert(cells, { Text = text })
    
    table.insert(cells, { Foreground = { Color = bg_color } })
    table.insert(cells, { Background = { Color = colors.crust } })
    table.insert(cells, { Text = ' ' }) -- Fin redondeado + espacio
  end

  -- 1. Leader Indicator
  if window:leader_is_active() then
    push(' LEADER', colors.red, colors.crust)
  end

  -- 2. Workspace
  push(' ' .. window:get_workspace(), colors.blue, colors.crust)

  -- 3. Host
  push(' ' .. wezterm.hostname(), colors.lavender, colors.crust)

  -- 4. Fecha
  local date = wezterm.strftime '%H:%M'
  push(' ' .. date, colors.peach, colors.crust)

  window:set_right_status(wezterm.format(cells))
end)


-- =========================================================================
-- FUNCIONALIDAD (Tmux-like)
-- =========================================================================
config.enable_wayland = false
config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 1000 }

local function is_vim(pane)
  local process_info = pane:get_foreground_process_info()
  local process_name = process_info and process_info.name or ""
  return pane:get_user_vars().IS_NVIM == 'true' or process_name:find('n?vim')
end

local function bind_smart_move(key, direction)
  return {
    key = key,
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      if is_vim(pane) then
        window:perform_action(act.SendKey({ key = key, mods = 'CTRL' }), pane)
      else
        window:perform_action(act.ActivatePaneDirection(direction), pane)
      end
    end),
  }
end

local function bind_smart_resize(key, direction)
  return {
    key = key,
    mods = 'META',
    action = wezterm.action_callback(function(window, pane)
      if is_vim(pane) then
        window:perform_action(act.SendKey({ key = key, mods = 'META' }), pane)
      else
        window:perform_action(act.AdjustPaneSize { direction, 3 }, pane)
      end
    end),
  }
end

config.keys = {
  { mods = 'LEADER|CTRL', key = 'j', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { mods = 'LEADER|CTRL', key = 'l', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { mods = 'LEADER|CTRL', key = 'k', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { mods = 'LEADER|CTRL', key = 'h', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { mods = 'LEADER', key = 'x', action = act.CloseCurrentPane { confirm = true } },
  { mods = 'LEADER', key = 'z', action = act.TogglePaneZoomState },
  { mods = 'LEADER', key = 'c', action = act.SpawnTab 'CurrentPaneDomain' },
  { mods = 'LEADER', key = 'n', action = act.ActivateTabRelative(1) },
  { mods = 'LEADER', key = 'p', action = act.ActivateTabRelative(-1) },
  { mods = 'LEADER', key = '1', action = act.ActivateTab(0) },
  { mods = 'LEADER', key = '2', action = act.ActivateTab(1) },
  { mods = 'LEADER', key = '3', action = act.ActivateTab(2) },
  { mods = 'LEADER', key = '4', action = act.ActivateTab(3) },
  { mods = 'LEADER', key = '5', action = act.ActivateTab(4) },
  -- Navegación Inteligente (Vim-Tmux-Navigator sin prefix)
  bind_smart_move('h', 'Left'),
  bind_smart_move('j', 'Down'),
  bind_smart_move('k', 'Up'),
  bind_smart_move('l', 'Right'),

  -- Redimensionado Inteligente (Vim-Tmux-Navigator sin prefix)
  bind_smart_resize('h', 'Left'),
  bind_smart_resize('j', 'Down'),
  bind_smart_resize('k', 'Up'),
  bind_smart_resize('l', 'Right'),
  
  -- Copiar y Pegar
  { mods = 'CTRL|SHIFT', key = 'c', action = act.CopyTo 'Clipboard' },
  { mods = 'CTRL|SHIFT', key = 'v', action = act.PasteFrom 'Clipboard' },

  -- WORKSPACES (Sesiones estilo Tmux)
  -- C-b s -> Listar Workspaces (Cambiar de sesión)
  { mods = 'LEADER', key = 's', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  -- C-b w -> Listar Workspaces (para muscle memory de Tmux choose-tree)
  { mods = 'LEADER', key = 'w', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  -- C-b $ -> Renombrar Workspace actual
  { 
    mods = 'LEADER', 
    key = ':', 
    action = act.PromptInputLine {
      description = 'Renombrar Workspace',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(window:mux_window():get_workspace(), line)
        end
      end),
    } 
  },
}

return config
