-- OpenCode v2 integration via nickjvandyke/opencode.nvim.
-- After setup: run `:checkhealth opencode`.
-- Server events arrive as `OpencodeEvent:*` User autocmds (pattern-filterable,
-- e.g. "OpencodeEvent:session.execution.started") — reserved for future hooks.
return {
	"nickjvandyke/opencode.nvim",
	-- Load at startup (after UI ready). Without this, lazy keeps the plugin off
	-- the runtimepath until a <leader>o* key is pressed, so `:checkhealth
	-- opencode` and the lualine status module are unavailable in fresh sessions.
	-- HTTP/SSE client only (daemon auto-discovery is lazy, not eager) -> no
	-- meaningful startup cost. keys below still work as first-class triggers.
	event = "VeryLazy",
	-- NO version pin on purpose: V2 support lives on the default branch `main`.
	-- `version = "*"` would pin the stable V1-only channel -> broken against the
	-- opencode v2 shared background service. The plugin talks HTTP/SSE to the
	-- daemon (NOT ACP) and auto-discovers it: `opencode serve` (or the shared
	-- service) already running -> it connects; none found -> server.start
	-- spawns one in a terminal.
	init = function()
		---@type opencode.Opts
		-- server.connect stays true ON PURPOSE: it enables the
		-- permission/:diffpatch review flow, i.e. agent edits are approved
		-- hunk-by-hunk in Neovim (da/dp/do/dq). Do not disable.
		-- server.start override: if no daemon is discoverable, spawn the
		-- opencode TUI in an embedded right-side terminal (snacks) instead of
		-- a bare vim terminal. Discovery order: connected -> server.url ->
		-- registered service.json -> this start fn.
		vim.g.opencode_opts = {
			server = {
				start = function()
					require("snacks.terminal").open("opencode", { win = { position = "right", enter = false } })
				end,
			},
		}
	end,
	config = function()
		-- Auto-show the TUI when the agent starts executing (README pattern).
		-- Without this, answers stream into a hidden terminal split and the
		-- flow degenerates into "I asked and saw nothing" again.
		vim.api.nvim_create_autocmd("User", {
			pattern = { "OpencodeEvent:session.execution.started" },
			callback = function()
				local win = require("snacks.terminal").get("opencode", { create = false })
				if win then
					win:show()
				end
			end,
		})
		-- lualine integration: append the OpenCode server status to lualine_z.
		-- lualine.setup() is merge-per-section (see lualine/config.lua
		-- apply_configuration), so only lualine_z changes; "location" kept.
		-- Kept here (not in plugins/lualine.lua) to keep this spec self-contained.
		local ok, lualine = pcall(require, "lualine")
		if ok then
			lualine.setup({
				sections = {
					lualine_z = { "location", { require("opencode").statusline } },
				},
			})
		end
	end,
	-- <leader>o* prefix. Avoided collisions: flash owns s/S, remap.lua owns
	-- <leader>og (Graphify), <leader>oh (HexCheck), <leader>ob (OpenCodeBuild)
	-- -> line variant uses <leader>ol instead of README's "goo"-style slot.
	-- stylua: ignore
	keys = {
		{ mode = { "n", "x" }, "<leader>oa", function() require("opencode").ask("@this: ") end, desc = "Ask OpenCode" },
		{ mode = { "n", "x" }, "<leader>os", function() require("opencode").select() end, desc = "OpenCode: Select" },
		-- The plugin has NO chat pane: ask()/prompt() target the most-recently
		-- updated session for nvim's cwd and the answer renders ONLY in the
		-- opencode TUI. <leader>ot toggles that TUI in a right split (README
		-- snacks.terminal pattern). Mode "n" only on purpose: binding "t" with
		-- a <leader> prefix would add leader-wait latency to every "t" typed
		-- inside the terminal (README warning).
		{ mode = "n", "<leader>ot", function() require("snacks.terminal").toggle("opencode", { win = { position = "right", enter = false } }) end, desc = "Toggle OpenCode TUI" },
		-- Operator maps MUST be expr = true and RETURN a motion string (README).
		{ mode = { "n", "x" }, "<leader>oo", function() return require("opencode").operator("@this") end, expr = true, desc = "Send range to OpenCode" },
		{ mode = "n", "<leader>ol", function() return require("opencode").operator("@this") .. "_" end, expr = true, desc = "Send line to OpenCode" },
	},
}
