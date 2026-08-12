-- =============================================================================
--  WezTerm configuration template  (runs on WINDOWS, not inside WSL)
--
--  Install location on Windows (pick one):
--    %USERPROFILE%\.wezterm.lua
--    %USERPROFILE%\.config\wezterm\wezterm.lua
--
--  Easiest: symlink it from this repo (run in an *elevated* PowerShell):
--    New-Item -ItemType SymbolicLink `
--      -Path "$env:USERPROFILE\.wezterm.lua" `
--      -Target "C:\dev\dotfiles\config\wezterm\wezterm.lua"
-- =============================================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- --- Launch straight into the NixOS WSL distro ---
-- The distro name must match what you imported (see README). Default: "NixOS".
config.default_domain = "WSL:NixOS"

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
config.send_composed_key_when_left_alt_is_down = false
config.send_composed_key_when_right_alt_is_down = false

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
	-- paste from clipboard
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

-- Spawn the window maximized to fill the screen.
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm.mux.spawn_window({
		domain = { DomainName = "WSL:NixOS" },
	})

	window:gui_window():maximize()
end)

return config
