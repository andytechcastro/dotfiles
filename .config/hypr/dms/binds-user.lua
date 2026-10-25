-- Binds personalizados del usuario (migrados desde binds.conf)
-- Hyprland 0.55+ Lua syntax

-- === APLICACIONES ===
hl.bind("SUPER + Return", hl.dsp.exec_cmd("wezterm"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

-- === DMS SPOTLIGHT (tu atajo preferido) ===
hl.bind("SUPER + D", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + K", hl.dsp.exec_cmd("nwg-displays"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))

-- === MOVIMIENTO CON FLECHAS ===
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

-- === MOVER VENTANAS CON FLECHAS ===
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- === WORKSPACES (1-9) ===
for i = 1, 9 do
	hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- === FD LEAK WORKAROUND (bug Hyprland virtual-keyboard, upstream #16613) ===
-- SUPER+V colisionaba con el musculo Mac (CMD+V = pegar): abria el overlay de
-- clipboard sin querer, y Enter = auto-paste = teclado virtual = ~1000 fds
-- fugados por uso en Hyprland 0.56.2. El Ctrl+V fisico no usa virtual-keyboard.
hl.unbind("SUPER + V")
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"), { description = "Clipboard history (movido de SUPER+V: leak de fds)" })

-- === MOUSE SCROLL PARA WORKSPACES ===
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- === MOVER/REDIMENSIONAR CON MOUSE ===
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
