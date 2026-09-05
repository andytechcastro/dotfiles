-- Configuración de monitores personalizada
-- Migrado desde monitors.conf

-- Monitor principal (laptop)
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60.01",
	position = "0x1043",
	scale = "1.0",
})

-- Monitor secundario (HDMI)
hl.monitor({
	output = "HDMI-A-1",
	mode = "2560x1080@60.0",
	position = "1920x614",
	scale = "1.0",
})

-- Monitor terciario (DisplayPort)
hl.monitor({
	output = "DP-3",
	mode = "2560x1080@60.0",
	position = "4480x0",
	scale = "1.0",
	transform = 1,
})
