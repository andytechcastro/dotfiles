-- Asignación de workspaces a monitores
-- Migrado desde workspaces.conf

-- Monitor HDMI-A-1 (secundario)
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })

-- Monitor eDP-1 (laptop)
hl.workspace_rule({ workspace = "6", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "7", monitor = "eDP-1" })

-- Monitor DP-3 (terciario)
hl.workspace_rule({ workspace = "8", monitor = "DP-3" })
hl.workspace_rule({ workspace = "9", monitor = "DP-3" })
