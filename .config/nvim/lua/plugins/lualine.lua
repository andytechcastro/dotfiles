return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status")
		local cp = require("catppuccin.palettes").get_palette("mocha")

		local my_lualine_theme = {
			normal = {
				a = { bg = cp.blue, fg = cp.mantle, gui = "bold" },
				b = { bg = cp.surface0, fg = cp.text },
				c = { bg = cp.base, fg = cp.text },
			},
			insert = {
				a = { bg = cp.green, fg = cp.mantle, gui = "bold" },
				b = { bg = cp.surface0, fg = cp.text },
				c = { bg = cp.base, fg = cp.text },
			},
			visual = {
				a = { bg = cp.mauve, fg = cp.mantle, gui = "bold" },
				b = { bg = cp.surface0, fg = cp.text },
				c = { bg = cp.base, fg = cp.text },
			},
			command = {
				a = { bg = cp.peach, fg = cp.mantle, gui = "bold" },
				b = { bg = cp.surface0, fg = cp.text },
				c = { bg = cp.base, fg = cp.text },
			},
			replace = {
				a = { bg = cp.red, fg = cp.mantle, gui = "bold" },
				b = { bg = cp.surface0, fg = cp.text },
				c = { bg = cp.base, fg = cp.text },
			},
			inactive = {
				a = { bg = cp.mantle, fg = cp.overlay0, gui = "bold" },
				b = { bg = cp.mantle, fg = cp.overlay0 },
				c = { bg = cp.mantle, fg = cp.overlay0 },
			},
		}

		lualine.setup({
			options = {
				theme = my_lualine_theme,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = "#ff9e64" },
					},
					{ "encoding" },
					{ "fileformat" },
					{ "filetype" },
				},
			},
		})
	end,
}
