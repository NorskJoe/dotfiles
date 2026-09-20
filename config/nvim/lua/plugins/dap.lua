-- Debugging via the Debug Adapter Protocol (DAP).
--   * nvim-dap            - the DAP client (breakpoints, stepping, sessions).
--   * nvim-dap-ui         - panels for scopes, stack, watches and a REPL.
--   * nvim-dap-virtual-text - inline variable values next to the code.
--
-- The debugger binary itself is netcoredbg (Nix-provided, see home/neovim.nix).
-- Build your project first (`dotnet build`) so a Debug .dll with symbols exists,
-- then <F5> and pick the .dll to launch.

-- Forward declaration: assigned inside `config` (which runs at plugin load,
-- before any keymap can fire), so the `keys` closures below can reach it.
local copy_locals

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "Debug: Continue/Start" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
			{ "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Conditional Breakpoint",
			},
			{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
			-- <S-F5> is reported as <F17> by most terminals; mirrors VS Code's stop.
			{ "<F17>", function() require("dap").terminate() end, desc = "Debug: Terminate" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
			{
				"<leader>de",
				function() require("dapui").eval() end,
				mode = { "n", "v" },
				desc = "Eval Expression",
			},
			{
				"<leader>dy",
				function() copy_locals() end,
				desc = "Copy locals to clipboard",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Copy all local variables at the current breakpoint to the system
			-- clipboard (+ register) as an indented tree. Walks every non-global
			-- scope of the current stack frame via the DAP protocol, recursing up
			-- to 2 levels deep into structured values. Guards against circular
			-- graphs (visited refs) and runaway dumps (node cap).
			copy_locals = function()
				local session = dap.session()
				if not session then
					vim.notify("No active debug session", vim.log.levels.WARN, { title = "DAP" })
					return
				end
				local frame = session.current_frame
				if not frame then
					vim.notify("Not stopped at a frame", vim.log.levels.WARN, { title = "DAP" })
					return
				end

				local MAX_DEPTH = 2 -- scope's direct vars = depth 1, one nesting = depth 2
				local NODE_CAP = 500

				local lines = {}
				local node_count = 0
				local truncated = false
				local visited = {}

				local function indent(level)
					return string.rep("  ", level)
				end

				local function fmt(var)
					local s = var.name .. " = " .. (var.value or "")
					if var.type and var.type ~= "" then
						s = s .. " (" .. var.type .. ")"
					end
					return s
				end

				-- Recursively request and render `ref`'s children at `level`.
				-- Uses a pending counter so we only finish once every async
				-- `variables` request has resolved.
				local pending = 1 -- the scopes request itself
				local function done_one()
					pending = pending - 1
					if pending == 0 then
						local text = table.concat(lines, "\n")
						if truncated then
							text = text .. "\n... (truncated at " .. NODE_CAP .. " nodes)"
						end
						vim.fn.setreg("+", text)
						vim.notify(
							"Copied " .. node_count .. " locals to clipboard",
							vim.log.levels.INFO,
							{ title = "DAP" }
						)
					end
				end

				local function walk(ref, level)
					if truncated or ref == 0 or level > MAX_DEPTH or visited[ref] then
						return
					end
					visited[ref] = true
					pending = pending + 1
					session:request("variables", { variablesReference = ref }, function(err, body)
						if not err and body and body.variables then
							for _, var in ipairs(body.variables) do
								if node_count >= NODE_CAP then
									truncated = true
									break
								end
								node_count = node_count + 1
								table.insert(lines, indent(level) .. fmt(var))
								if var.variablesReference and var.variablesReference ~= 0 then
									walk(var.variablesReference, level + 1)
								end
							end
						end
						done_one()
					end)
				end

				session:request("scopes", { frameId = frame.id }, function(err, body)
					if err or not body or not body.scopes then
						vim.notify("Failed to fetch scopes", vim.log.levels.ERROR, { title = "DAP" })
						done_one()
						return
					end
					for _, scope in ipairs(body.scopes) do
						local name = scope.name or ""
						local is_global = name:lower():find("global") ~= nil
						if not scope.expensive and not is_global then
							table.insert(lines, name)
							walk(scope.variablesReference, 1)
						end
					end
					done_one()
				end)
			end

			dapui.setup()
			require("nvim-dap-virtual-text").setup({})

			-- Open/close the UI panels automatically with the session lifecycle.
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- CoreCLR debug adapter (netcoredbg, Nix-provided).
			dap.adapters.coreclr = {
				type = "executable",
				command = "netcoredbg",
				args = { "--interpreter=vscode" },
			}

			-- Generic launch config for C#. Auto-detects the runnable project(s) in
			-- the workspace and launches the built .dll. Per-project settings (env
			-- vars, args, a specific project) belong in a `.vscode/launch.json` at
			-- the repo root, which nvim-dap loads automatically and lists alongside
			-- this entry in the <F5> picker.
			--
			-- "Runnable" = an executable project: SDK `Microsoft.NET.Sdk.Web` or an
			-- explicit `<OutputType>Exe</OutputType>`. Class libraries have no entry
			-- point, so they are never launch targets - but breakpoints in their code
			-- still hit, because their .dll loads into the executable's process.
			local function pick_dll()
				local root = vim.fn.getcwd()
				local csprojs = vim.fs.find(function(name)
					return name:match("%.csproj$")
				end, { path = root, type = "file", limit = math.huge })

				local targets = {}
				for _, csproj in ipairs(csprojs) do
					if csproj:match("/bin/") or csproj:match("/obj/") then
						goto continue
					end
					local text = table.concat(vim.fn.readfile(csproj), "\n")
					local is_exe = text:match('Sdk%s*=%s*"[^"]*%.Web"')
						or text:match("<OutputType>%s*Exe%s*</OutputType>")
					if is_exe then
						local dir = vim.fs.dirname(csproj)
						local name = vim.fn.fnamemodify(csproj, ":t:r")
						local tfm = text:match("<TargetFramework>%s*(.-)%s*</TargetFramework>") or "net9.0"
						table.insert(targets, {
							name = name,
							dll = string.format("%s/bin/Debug/%s/%s.dll", dir, tfm, name),
						})
					end
					::continue::
				end

				local function ensure_built(dll)
					if vim.fn.filereadable(dll) == 0 then
						vim.notify(
							"DLL not found (build first with `dotnet build`):\n" .. dll,
							vim.log.levels.WARN,
							{ title = "DAP" }
						)
					end
					return dll
				end

				if #targets == 1 then
					return ensure_built(targets[1].dll)
				elseif #targets > 1 then
					local co = coroutine.running()
					vim.ui.select(targets, {
						prompt = "Select project to debug",
						format_item = function(t)
							return t.name
						end,
					}, function(choice)
						coroutine.resume(co, choice and ensure_built(choice.dll) or nil)
					end)
					return coroutine.yield()
				end

				-- No executable project detected: fall back to manual entry.
				return vim.fn.input({
					prompt = "Path to dll: ",
					default = root .. "/bin/Debug/net9.0/",
					completion = "file",
				})
			end

			dap.configurations.cs = {
				{
					type = "coreclr",
					name = "Launch - netcoredbg (auto-detect)",
					request = "launch",
					program = pick_dll,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
				},
			}
		end,
	},
}
