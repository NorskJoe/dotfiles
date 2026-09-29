-- =============================================================================
--  WezTerm configuration  (shared across Windows and native Linux)
--
--  Detected at runtime via wezterm.target_triple:
--    * Windows -> on launch, asks which host to open: WSL or PowerShell (pwsh).
--                 No prompt when the WSL distro isn't installed (pure Windows).
--                 Per-machine settings come from the untracked
--                 ~/.wezterm.local.lua (written by scripts/install-windows.sh):
--                   return {
--                     wsl_domain = "WSL:NixOS",     -- optional, must match `wsl -l`
--                     default_cwd = "D:/Projects",  -- optional, used for pwsh
--                   }
--    * Linux   -> WezTerm runs natively (e.g. Ubuntu) and opens a normal local
--                 shell. Installed + linked by home-manager (home/wezterm.nix).
--
--  Windows: scripts/install-windows.sh symlinks this file to ~/.wezterm.lua.
--  Leader+w / Leader+p open a tab in WSL / pwsh; Ctrl+Shift+T (WezTerm default)
--  opens a tab on the current pane's host.
-- =============================================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Per-machine overrides (untracked). Missing or broken file -> defaults.
local local_cfg = {}
if is_windows then
	local ok, result = pcall(dofile, wezterm.home_dir .. "/.wezterm.local.lua")
	if ok and type(result) == "table" then
		local_cfg = result
	end
end

local wsl_domain = local_cfg.wsl_domain or "WSL:NixOS"
local pwsh_args = { "pwsh.exe", "-NoLogo" }

local function wsl_available()
	for _, d in ipairs(wezterm.default_wsl_domains()) do
		if d.name == wsl_domain then
			return true
		end
	end
	return false
end

-- The local domain is pwsh; WSL is opened on demand (startup prompt / Leader+w).
if is_windows then
	config.default_prog = pwsh_args
	if local_cfg.default_cwd then
		config.default_cwd = local_cfg.default_cwd
	end
end

-- --- Appearance (tweak to taste) ---
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Symbols Nerd Font Mono",
})
config.font_size = 11.0
config.hide_tab_bar_if_only_one_tab = true
config.underline_thickness = 1
config.window_close_confirmation = "NeverPrompt"


-- Make Alt+<key> send proper escape sequences (so <A-j>/<A-k> work in nvim)
-- instead of Windows treating Left Alt as a compose/dead key.
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- --- Keybindings (add your own) ---
config.leader = { key = "b", mods = "CTRL" }

config.keys = {
	-- Leader + l: horizontal split
	{
		key = "l",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	-- Leader + k: vertical split
	{
		key = "k",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	-- Leader + x: close pane
	{
		key = "x",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},
	-- Ctrl + v: paste from clipboard
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
	-- Leader + r: start to resize panes
	{
		key = "r",
		mods = "LEADER",
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			one_shot = false, --  stay active for multiple resize
			timeout_milliseconds = 1000,
		}),
	},
}

if is_windows then
	-- Leader + w: new tab in WSL
	table.insert(config.keys, {
		key = "w",
		mods = "LEADER",
		action = wezterm.action.SpawnCommandInNewTab({ domain = { DomainName = wsl_domain } }),
	})
	-- Leader + p: new tab in PowerShell
	table.insert(config.keys, {
		key = "p",
		mods = "LEADER",
		action = wezterm.action.SpawnCommandInNewTab({ domain = "DefaultDomain", args = pwsh_args }),
	})
end

-- keytable for resizing panes
config.key_tables = {
	-- Leader + r, h/j/k/l
	resize_panes = {
		{ key = "h", action = wezterm.action.AdjustPaneSize({ "Left", 3 }) },
		{ key = "j", action = wezterm.action.AdjustPaneSize({ "Down", 3 }) },
		{ key = "k", action = wezterm.action.AdjustPaneSize({ "Up", 3 }) },
		{ key = "l", action = wezterm.action.AdjustPaneSize({ "Right", 3 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

-- Asks which host the first tab should use. The window starts on pwsh (the
-- local domain); picking WSL opens a WSL tab and closes the pwsh one. With the
-- tab bar hidden for a single tab, the swap is invisible. Esc keeps pwsh.
local host_prompt = wezterm.action.InputSelector({
	title = "Open host",
	description = "Choose a host (1/2, or Enter). Esc keeps PowerShell.",
	alphabet = "12",
	choices = {
		{ id = "wsl", label = "WSL (" .. wsl_domain:gsub("^WSL:", "") .. ")" },
		{ id = "pwsh", label = "PowerShell" },
	},
	action = wezterm.action_callback(function(window, pane, id)
		if id == "wsl" then
			window:mux_window():spawn_tab({ domain = { DomainName = wsl_domain } })
			-- CloseCurrentPane acts on the active pane, so re-activate the pwsh
			-- placeholder first; closing it leaves the WSL tab active.
			pane:activate()
			window:perform_action(wezterm.action.CloseCurrentPane({ confirm = false }), pane)
		end
	end),
})

-- Open the window at 80% of the screen, then (Windows with WSL) ask for the host.
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()

	-- gui_window:maximize()
	local active_screen = wezterm.gui.screens()["active"]
	gui_window:set_inner_size(active_screen.width * 0.8, active_screen.height * 0.8)

	if is_windows and not cmd and wsl_available() then
		gui_window:perform_action(host_prompt, pane)
	end
end)

return config
