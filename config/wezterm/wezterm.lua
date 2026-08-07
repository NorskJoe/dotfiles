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
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Symbols Nerd Font Mono",
})
config.font_size = 11.0
config.window_background_opacity = 1.0
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
config.scrollback_lines = 10000

-- --- Keybindings (add your own) ---
-- config.keys = {
--   { key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SpawnWindow },
-- }

return config
