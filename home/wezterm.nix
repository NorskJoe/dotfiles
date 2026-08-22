{ config, pkgs, ... }:
{
  # WezTerm for native Linux (e.g. Ubuntu). On WSL, WezTerm runs on the Windows
  # side instead, so this module is imported only from home/ubuntu.nix.
  #
  # We install WezTerm as a plain package and symlink the config out-of-store,
  # rather than using `programs.wezterm.enable`, because that module manages
  # ~/.config/wezterm/wezterm.lua and would collide with the whole-directory
  # symlink below (same rationale as home/neovim.nix).
  home.packages = [ pkgs.wezterm ];

  # Mutable symlink: ~/.config/wezterm -> your repo's config/wezterm, so you can
  # edit the config live without a rebuild. The wezterm.lua is platform-aware and
  # shared with the Windows/WSL setup. Assumes the repo is cloned at ~/dotfiles.
  xdg.configFile."wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/wezterm";
}
