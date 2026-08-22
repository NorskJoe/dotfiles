-- =============================================================================
--  WezTerm configuration template  (shared across Windows and native Linux)
--
--  This single file supports two setups, detected at runtime via
--  wezterm.target_triple:
--    * Windows  -> WezTerm runs on Windows and launches into the "NixOS" WSL
--                  distro. Install by symlinking to %USERPROFILE% (see below).
--    * Linux    -> WezTerm runs natively (e.g. on Ubuntu). No WSL is involved;
--                  it opens a normal local shell. Installed + symlinked to
--                  ~/.config/wezterm by home-manager (see home/wezterm.nix).
--
--  Windows install location (pick one):
--    %USERPROFILE%\.wezterm.lua
--    %USERPROFILE%\.config\wezterm\wezterm.lua
--
--  Easiest on Windows: symlink it from this repo (run in an *elevated* PowerShell):
--    New-Item -ItemType SymbolicLink `
--      -Path "$env:USERPROFILE\.wezterm.lua" `
--      -Target "C:\dev\dotfiles\config\wezterm\wezterm.lua"
-- =============================================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- True when WezTerm is running on Windows (and thus reaches into WSL). On native
-- Linux this is false and WezTerm just uses the local default domain.
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- The WSL distro name must match what you imported (see README). Default: "NixOS".
local wsl_domain = "WSL:NixOS"

-- --- Launch straight into the NixOS WSL distro (Windows only) ---
if is_windows then
	config.default_domain = wsl_domain
end

-- --- Appearance (tweak to taste) ---
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Symbols Nerd Font Mono",
})
config.font_size = 11.0
config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.underline_thickness = 1

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

-- Spawn the window maximized to fill the screen. On Windows, open it directly in
-- the WSL distro; on native Linux, open a normal local window.
wezterm.on("gui-startup", function(cmd)
	local spawn_args = {}
	if is_windows then
		spawn_args.domain = { DomainName = wsl_domain }
	end
	local tab, pane, window = wezterm.mux.spawn_window(spawn_args)

	window:gui_window():maximize()
end)

return config
