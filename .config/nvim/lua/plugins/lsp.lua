return {
	-- Mason is configured in mason-tools.lua

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		config = function()
			local cmp = require("cmp")

			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
				},
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.snippet.active({ direction = 1 }) then
							vim.snippet.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.snippet.active({ direction = -1 }) then
							vim.snippet.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},
			})
		end,
	},

	-- LSP
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "mason-org/mason.nvim" },
			{ "mason-org/mason-lspconfig.nvim" },
		},
		init = function()
			vim.opt.signcolumn = "yes"
		end,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- LspAttach autocmd
			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				callback = function(event)
					local opts = { buffer = event.buf }

					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
					vim.keymap.set({ "n", "x" }, "<F3>", function() vim.lsp.buf.format({ async = true }) end, opts)
					vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)

					if vim.lsp.inlay_hint then
						vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
					end

					-- NOTE: no format-on-save here — conform.nvim owns formatting.
				end,
			})

			-- mason-lspconfig 2.x: no handlers table anymore.
			-- automatic_enable (default true) calls vim.lsp.enable() for each
			-- installed server; configs from nvim-lspconfig's lsp/ dir are merged
			-- by vim.lsp.config. rust_analyzer is NOT ensured here:
			-- rustaceanvim manages its own.
			require("mason-lspconfig").setup({
				ensure_installed = {
					"terraformls", "dockerls", "yamlls", "bashls", "helm_ls",
					"gopls", "buf_ls", "lua_ls", "html", "cssls", "sqlls", "templ", "jsonls",
				},
			})

			-- Global LSP defaults (merged into every server config by vim.lsp.config)
			vim.lsp.config("*", {
				capabilities = capabilities,
			})
			vim.lsp.config("lua_ls", {
				settings = { Lua = { diagnostics = { globals = { "vim" } } } },
			})

			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = " ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
			})
		end,
	},
}
