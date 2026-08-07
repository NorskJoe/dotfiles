{ config, pkgs, username, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./neovim.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # User-level CLI tooling. Add your own here.
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    bat
    eza
    jq
    tree
    htop
  ];

  # Let Home Manager manage itself.
  programs.home-manager.enable = true;

  # Do not change after first install. Match your NixOS release.
  home.stateVersion = "26.05";
}
