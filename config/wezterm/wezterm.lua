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

-- --- Keybindings (add your own) ---
config.leader = { key = 'b', mods = 'CTRL', }

config.keys = {
  -- Leader + l: horizontal split
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Leader + k: vertical split
  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Leader + x: close pane
  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  }
}

-- Center the window with a size of 0.7 of the actual screen
wezterm.on('gui-startup', function(cmd)
    local screen = wezterm.gui.screens().active
    local ratio = 0.7
    local width, height = screen.width * ratio, screen.height * ratio
    
    local tab, pane, window = wezterm.mux.spawn_window {
        domain = { DomainName = "WSL:NixOS" },
        position = {
            x = (screen.width - width) / 2,
            y = (screen.height - height) / 2,
            origin = 'ActiveScreen'
        }
    }
    
    -- Apply inner size after spawn to avoid visual jumping
    window:gui_window():set_inner_size(width, height)
end)

return config
