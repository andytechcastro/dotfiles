return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		default_file_explorer = true,
		-- Never hard-delete: send to Linux Trash via gio/trash.
		-- NOTE: installed oil accepts only boolean here ('auto' does not
		-- exist in this version's config schema — verified in lua/oil/config.lua).
		delete_to_trash = true,
		columns = { "icon" },
		view_options = {
			show_hidden = false,
			natural_order = true,
			sort = { { "type", "asc" }, { "name", "asc" } },
		},
		-- All default keymaps kept (incl. <C-c> = actions.close); see :help oil-actions
	},
	dependencies = { { "nvim-tree/nvim-web-devicons", opts = {} } },
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
}
