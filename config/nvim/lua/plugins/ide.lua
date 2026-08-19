-- Parsers to keep installed. These are parser names, not filetypes.
local ensure_installed = {
	"bash",
	"c",
	"lua",
	"markdown",
	"nix",
	"vim",
	"angular",
	"css",
	"c_sharp",
	"go",
	"html",
	"javascript",
	"typescript",
	"json",
	"prisma",
	"python",
	"razor",
	"scss",
	"sql",
	"vue",
	"xml",
	"gitcommit",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main", -- the master branch is deprecated
		lazy = false, -- main does not support lazy-loading
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install(ensure_installed)

			-- The main branch has no highlight/indent modules; you start them yourself.
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local ft = vim.bo[args.buf].filetype
					-- skip oil.nvim and neogit buffers
					if ft == "oil" or ft:match("^Neogit") then
						return
					end
					local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
					if
						lang
						and vim.tbl_contains(ensure_installed, lang)
						and pcall(vim.treesitter.language.add, lang)
					then
						vim.treesitter.start()
						-- Indentation is intentionally left to Neovim's built-in
						-- indenters (runtime/indent/*). The main-branch treesitter
						-- indenter is experimental and produces worse results for
						-- most languages we use, so we don't set indentexpr here.
						vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.wo[0][0].foldmethod = "expr"
					end
				end,
			})
		end,
	},

	-- LSP client config. Servers are Nix-provided (see home/neovim.nix) and enabled
	-- with the native vim.lsp API. Neovim 0.11+ ships default LSP keymaps
	-- (K = hover, grn = rename, gra = code action, grr = references, gri = impl).
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			-- Advertise blink.cmp's completion capabilities to every server.
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
			})

			vim.lsp.config("lua_ls", {
				settings = { Lua = { diagnostics = { globals = { "vim" } } } },
			})

			vim.lsp.enable({
				"lua_ls",
				"nil_ls",
				"ts_ls",
				"vue_ls",
				"angularls",
				"html",
				"cssls",
				"jsonls",
				"yamlls",
				"gopls",
				"pyright",
				"clangd",
				"sqls",
				"bashls",
			})
		end,
	},

	-- C#. roslyn-ls speaks a non-standard LSP dialect, so it needs this dedicated
	-- plugin instead of a plain lspconfig entry. Binary is Nix-provided.
	{
		"seblj/roslyn.nvim",
		ft = "cs",
		opts = {},
		config = function(_, opts)
			vim.lsp.config("roslyn", {
				cmd = {
					"Microsoft.CodeAnalysis.LanguageServer",
					"--logLevel=Warning",
					"--extensionLogDirectory=" .. vim.fs.joinpath(vim.fn.stdpath("log"), "roslyn"),
					"--stdio",
				},
				-- Server GC: faster initial solution load / analysis on multi-core machines.
				cmd_env = { DOTNET_gcServer = "1" },
			})
			require("roslyn").setup(vim.tbl_deep_extend("force", {
				-- Let the server handle file watching. The client-side fallback
				-- uses an in-process watcher that walks the tree itself (slow).
				filewatching = "roslyn",
				-- Don't re-detect the solution on every new buffer.
				lock_target = true,
				-- Analyse the whole solution, not just open buffers
				background_analysis_scope = "fullSolution",
			}, opts))

			-- New-file visibility fix for roslyn-ls.
			--
			-- We use `filewatching = "roslyn"` (above) for performance: Neovim's
			-- client-side watcher is slow on Linux because inotify isn't recursive.
			-- The downside is that files *created inside Neovim* aren't added to the
			-- project's compilation until a restart -- a freshly saved .cs file lands
			-- in Roslyn's "miscellaneous files" workspace, so other files can't see
			-- the new type in completion or code actions.
			--
			-- Fix: when a brand-new .cs buffer is first written to disk, send Roslyn a
			-- one-shot `didChangeWatchedFiles` "Created" event ourselves. That is the
			-- exact notification the disabled watcher would have sent, so the project
			-- system picks the file up immediately -- no restart, no background cost.
			local group = vim.api.nvim_create_augroup("RoslynNewFile", { clear = true })
			vim.api.nvim_create_autocmd("BufNewFile", {
				group = group,
				pattern = "*.cs",
				callback = function(args)
					vim.b[args.buf].roslyn_new_file = true
				end,
			})
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = group,
				pattern = "*.cs",
				callback = function(args)
					if not vim.b[args.buf].roslyn_new_file then
						return
					end
					vim.b[args.buf].roslyn_new_file = nil
					local uri = vim.uri_from_fname(args.file)
					for _, client in ipairs(vim.lsp.get_clients({ name = "roslyn" })) do
						client:notify("workspace/didChangeWatchedFiles", {
							changes = { { uri = uri, type = 1 } }, -- 1 = Created
						})
					end
				end,
			})

			-- Solution-load timer. roslyn only reports true progress ($/progress)
			-- for the near-instant Restore phase; it emits nothing during the
			-- background analysis pass. The only load-lifecycle signal is the
			-- custom workspace/projectInitializationComplete notification, so we
			-- show a live elapsed-time counter from attach until that fires.
			--
			-- Each entry: { handle = <fidget handle>, start = <hrtime>, timer = <uv timer> }
			local roslyn_timers = {}

			local function finish(client_id)
				local entry = roslyn_timers[client_id]
				if not entry then
					return
				end
				roslyn_timers[client_id] = nil
				if entry.timer then
					entry.timer:stop()
					if not entry.timer:is_closing() then
						entry.timer:close()
					end
				end
				local total = (vim.uv.hrtime() - entry.start) / 1e9
				entry.handle:report({ message = string.format("Done in %.1fs", total) })
				entry.handle:finish()
			end

			-- roslyn registers projectInitializationComplete as a *per-client*
			-- handler (see roslyn.nvim lsp/roslyn.lua), so overriding the global
			-- vim.lsp.handlers table would never fire. Wrap the per-client handler
			-- instead, delegating to the original so its diagnostic refresh runs.
			local roslyn_handlers = require("roslyn.lsp.handlers")
			local prev_handler = roslyn_handlers["workspace/projectInitializationComplete"]
			vim.lsp.config("roslyn", {
				handlers = {
					["workspace/projectInitializationComplete"] = function(err, res, ctx)
						finish(ctx.client_id)
						if prev_handler then
							return prev_handler(err, res, ctx)
						end
					end,
				},
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = group,
				callback = function(args)
					local client_id = args.data.client_id
					local client = vim.lsp.get_client_by_id(client_id)
					if not client or client.name ~= "roslyn" then
						return
					end
					if roslyn_timers[client_id] then
						return
					end

					local handle = require("fidget.progress.handle").create({
						message = "0.0s",
						lsp_client = { name = "roslyn" },
					})
					local start = vim.uv.hrtime()
					local timer = vim.uv.new_timer()
					roslyn_timers[client_id] = { handle = handle, start = start, timer = timer }

					-- uv timer callbacks run off the main loop; fidget must run on
					-- it, so hop back via vim.schedule.
					timer:start(0, 100, function()
						vim.schedule(function()
							if not roslyn_timers[client_id] then
								return
							end
							local elapsed = (vim.uv.hrtime() - start) / 1e9
							handle:report({ message = string.format("%.1fs", elapsed) })
						end)
					end)
				end,
			})
			vim.api.nvim_create_autocmd("LspDetach", {
				group = group,
				callback = function(args)
					if args.data.client_id then
						finish(args.data.client_id)
					end
				end,
			})
		end,
	},

	-- LSP progress spinners for every server (roslyn solution loads, gopls,
	-- pyright, ts_ls, etc.). Only the progress module is used; the notification
	-- backend is left disabled so it never fights snacks.notifier.
	{
		"j-hui/fidget.nvim",
		event = { "LspAttach" },
		opts = {
			progress = {
				display = { progress_icon = { pattern = "dots" } },
			},
			notification = {
				override_vim_notify = false,
			},
		},
	},

	-- Formatting. Formatters are Nix-installed; conform just runs them.
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true })
				end,
				desc = "Format Buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				nix = { "nixfmt" },
				javascript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				vue = { "prettierd" },
				html = { "prettierd" },
				css = { "prettierd" },
				scss = { "prettierd" },
				json = { "prettierd" },
				yaml = { "prettierd" },
				go = { "gofumpt" },
				python = { "ruff_format" },
				cs = { "csharpier" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				sql = { "sql_formatter" },
				sh = { "shfmt" },
				bash = { "shfmt" },
			},
			format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
		},
	},

	-- Autocompletion. blink.cmp provides LSP-driven completion, snippets and a
	-- signature-help popup. The default fuzzy matcher ships as a prebuilt Rust
	-- binary that won't run on NixOS, so we use the pure-Lua implementation.
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		version = "*",
		opts = {
			fuzzy = { implementation = "lua" },
			keymap = {
				preset = "default",
				["<Tab>"] = { "select_and_accept", "fallback" },
				["<CR>"] = { "select_and_accept", "fallback" },
			},
			appearance = { nerd_font_variant = "mono" },
			completion = {
				documentation = { auto_show = true, auto_show_delay_ms = 200 },
			},
			signature = { enabled = true },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
		opts_extend = { "sources.default" },
	},

	-- Auto-close brackets, braces, quotes, etc. as you type.
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
}
